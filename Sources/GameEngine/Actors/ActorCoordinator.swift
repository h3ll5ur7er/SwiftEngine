import Foundation
@preconcurrency import WinSDK

/// Coordinates between different actors and the main thread
/// Manages the flow of data between physics, game logic, and rendering
@MainActor
public final class ActorCoordinator {
    
    /// Shared instance
    public static let shared = ActorCoordinator()
    
    /// Whether async physics is enabled
    public var asyncPhysicsEnabled: Bool = true
    
    /// Whether async game logic is enabled  
    public var asyncGameLogicEnabled: Bool = true
    
    /// Latest physics result (for interpolation)
    private var latestPhysicsResult: PhysicsStepResult?
    
    /// Latest game logic result
    private var latestGameLogicResult: GameLogicResult?
    
    /// Performance metrics
    public private(set) var physicsTime: Double = 0
    public private(set) var gameLogicTime: Double = 0
    public private(set) var lastFrameActorTime: Double = 0
    
    private init() {}
    
    // MARK: - Frame Update
    
    /// Called each frame to coordinate actor updates
    /// This runs physics and game logic concurrently, then applies results
    public func update(
        deltaTime: Float,
        gameObjects: [GameObject]
    ) async {
        let frameStart = GetTickCount64()
        
        // Create snapshots for concurrent processing (on MainActor)
        let snapshots = gameObjects.map { go in
            GameObjectSnapshot(
                id: go.id,
                name: go.name,
                isActive: go.isActive,
                position: go.transform.position,
                rotation: go.transform.rotation,
                scale: go.transform.lossyScale,
                components: go.components.map { comp in
                    ComponentUpdateData(
                        gameObjectId: go.id,
                        componentTypeName: comp.typeName,
                        isEnabled: comp.isEnabled
                    )
                }
            )
        }
        
        // Create physics input if async physics is enabled
        let physicsInput: PhysicsFrameInput?
        if asyncPhysicsEnabled {
            // Gather body states from RigidBody components
            var bodies: [GameUUID: PhysicsBodyState] = [:]
            var colliders: [ColliderSnapshot] = []
            
            for go in gameObjects {
                if let rb = go.getComponent(RigidBody.self) {
                    let state = PhysicsBodyState(
                        id: go.id,
                        position: go.transform.position,
                        velocity: rb.velocity,
                        rotation: go.transform.rotation,
                        angularVelocity: rb.angularVelocity,
                        mass: rb.mass,
                        isKinematic: rb.isKinematic,
                        angularDrag: rb.angularDrag,
                        maxVelocity: rb.maxVelocity,
                        maxAngularVelocity: rb.maxAngularVelocity,
                        accumulatedForce: rb.accumulatedForce,
                        accumulatedTorque: rb.accumulatedTorque
                    )
                    bodies[go.id] = state
                }
                
                // Gather colliders
                for collider in [go.getComponent(BoxCollider.self) as Collider?, 
                                go.getComponent(SphereCollider.self) as Collider?,
                                go.getComponent(PlaneCollider.self) as Collider?].compactMap({ $0 }) {
                    if collider.isEnabled {
                        let colliderType: ColliderSnapshot.ColliderType
                        if let box = collider as? BoxCollider {
                            colliderType = .box(halfExtents: box.halfExtents)
                        } else if let sphere = collider as? SphereCollider {
                            colliderType = .sphere(radius: sphere.radius)
                        } else if let plane = collider as? PlaneCollider {
                            let worldNormal = plane.worldNormal
                            let worldPoint = plane.worldCenter
                            let offset = worldNormal.x * worldPoint.x + worldNormal.y * worldPoint.y + worldNormal.z * worldPoint.z
                            colliderType = .plane(normal: worldNormal, offset: offset)
                        } else {
                            continue
                        }
                        
                        colliders.append(ColliderSnapshot(
                            bodyId: go.id,
                            type: colliderType,
                            worldCenter: collider.worldCenter,
                            worldRotation: go.transform.rotation,
                            isTrigger: collider.isTrigger,
                            layer: collider.layer,
                            material: collider.material,
                            boundingSphereRadius: collider.boundingSphereRadius
                        ))
                    }
                }
            }
            
            physicsInput = PhysicsFrameInput(bodies: bodies, colliders: colliders, deltaTime: deltaTime)
        } else {
            physicsInput = nil
        }
        
        // Run physics and game logic concurrently
        async let physicsTask: PhysicsStepResult? = physicsInput != nil 
            ? await PhysicsActor.shared.simulate(input: physicsInput!) 
            : nil
            
        async let gameLogicTask: GameLogicResult = asyncGameLogicEnabled
            ? GameLogicActor.shared.processGameObjects(snapshots, deltaTime: deltaTime)
            : GameLogicResult(processedCount: 0, processingTime: 0, transformUpdates: [:])
        
        // Await both results
        let (physicsResult, gameLogicResult) = await (physicsTask, gameLogicTask)
        
        // Store results
        latestPhysicsResult = physicsResult
        latestGameLogicResult = gameLogicResult
        
        // Apply physics results to transforms (on MainActor)
        if let physics = physicsResult {
            physicsTime = Double(physics.simulatedTime)
            applyPhysicsResults(physics, to: gameObjects)
        }
        
        // Apply game logic results to transforms (on MainActor)
        gameLogicTime = gameLogicResult.processingTime
        applyGameLogicResults(gameLogicResult, to: gameObjects)
        
        lastFrameActorTime = Double(GetTickCount64() - frameStart) / 1000.0
    }
    
    // MARK: - Result Application
    
    private func applyPhysicsResults(_ result: PhysicsStepResult, to gameObjects: [GameObject]) {
        let lookup = Dictionary(uniqueKeysWithValues: gameObjects.map { ($0.id, $0) })
        
        for (id, bodyState) in result.updatedBodies {
            if let gameObject = lookup[id] {
                gameObject.transform.position = bodyState.position
                gameObject.transform.rotation = bodyState.rotation
            }
        }
    }
    
    private func applyGameLogicResults(_ result: GameLogicResult, to gameObjects: [GameObject]) {
        let lookup = Dictionary(uniqueKeysWithValues: gameObjects.map { ($0.id, $0) })
        
        for (id, update) in result.transformUpdates {
            if let gameObject = lookup[id] {
                if let position = update.position {
                    gameObject.transform.position = position
                }
                if let rotation = update.rotation {
                    gameObject.transform.rotation = rotation
                }
                if let scale = update.scale {
                    gameObject.transform.localScale = scale
                }
            }
        }
    }
    
    // MARK: - Physics Body Registration
    
    /// Register a game object with the physics system
    /// Note: When using ActorCoordinator.update(), bodies are automatically included
    /// This method is for manual registration when not using the coordinator
    public func registerPhysicsBody(
        for gameObject: GameObject,
        mass: Float = 1.0,
        isKinematic: Bool = false
    ) async {
        // With the new architecture, physics bodies are gathered each frame
        // from RigidBody components. This method is now a no-op but kept for API compatibility.
    }
    
    /// Unregister a game object from the physics system
    /// Note: With the new architecture, this is handled automatically
    public func unregisterPhysicsBody(for gameObject: GameObject) async {
        // With the new architecture, physics bodies are gathered each frame
        // This method is now a no-op but kept for API compatibility.
    }
    
    // MARK: - Interpolation
    
    /// Get interpolation alpha for smooth rendering between physics steps
    public func getPhysicsInterpolationAlpha() async -> Float {
        await PhysicsActor.shared.getInterpolationAlpha()
    }
    
    // MARK: - Statistics
    
    /// Get comprehensive performance statistics
    public func getPerformanceStats() async -> ActorPerformanceStats {
        let (physicsUpdates, physicsTime, lastFrameSteps) = await PhysicsActor.shared.getStatistics()
        let (logicUpdates, logicTime, avgLogicTime) = await GameLogicActor.shared.getStatistics()
        let cacheStats = await AssetLoadingActor.shared.getCacheStats()
        
        return ActorPerformanceStats(
            physicsBodyCount: latestPhysicsResult?.updatedBodies.count ?? 0,
            totalPhysicsTime: physicsTime,
            totalGameLogicTime: logicTime,
            avgPhysicsTimePerStep: physicsUpdates > 0 ? physicsTime / Double(physicsUpdates) : 0,
            avgGameLogicTimePerFrame: avgLogicTime,
            cachedAssetCount: cacheStats.count,
            lastFrameActorTime: lastFrameActorTime
        )
    }
}

/// Performance statistics for actors
public struct ActorPerformanceStats: Sendable {
    public let physicsBodyCount: Int
    public let totalPhysicsTime: Double
    public let totalGameLogicTime: Double
    public let avgPhysicsTimePerStep: Double
    public let avgGameLogicTimePerFrame: Double
    public let cachedAssetCount: Int
    public let lastFrameActorTime: Double
}
