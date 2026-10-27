import Foundation

/// Coordinates between different actors and the main thread
/// Manages the flow of data between physics, game logic, and rendering
@MainActor
public final class ActorCoordinator {
    
    /// Shared instance
    public static let shared = ActorCoordinator()
    
    /// Shared timer for performance measurement
    private let timer = sharedTimer
    
    /// Run physics on PhysicsActor instead of inline on the main actor
    public var asyncPhysicsEnabled: Bool = false
    
    /// Run GameLogicActor handlers and tasks each frame
    public var asyncGameLogicEnabled: Bool = true
    
    /// Performance metrics
    public private(set) var physicsTime: Double = 0
    public private(set) var gameLogicTime: Double = 0
    public private(set) var lastFrameActorTime: Double = 0
    
    private init() {}
    
    // MARK: - Frame Update
    
    /// Called by the engine each frame after the scene update.
    /// Steps physics (inline or on PhysicsActor), then runs GameLogicActor handlers
    /// and applies their transform updates.
    public func update(
        deltaTime: Float,
        gameObjects: [GameObject]
    ) async {
        let frameStart = timer.currentTimeMillis()
        
        if asyncPhysicsEnabled {
            await PhysicsSystem.shared.updateAsync(deltaTime: deltaTime)
        } else {
            PhysicsSystem.shared.update(deltaTime: deltaTime)
        }
        physicsTime = PhysicsSystem.shared.waitTimeMs / 1000.0
        
        if asyncGameLogicEnabled, await GameLogicActor.shared.hasWork {
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
            
            let result = await GameLogicActor.shared.processGameObjects(snapshots, deltaTime: deltaTime)
            gameLogicTime = result.processingTime
            applyGameLogicResults(result, to: gameObjects)
        } else {
            gameLogicTime = 0
        }
        
        lastFrameActorTime = Double(timer.currentTimeMillis() - frameStart) / 1000.0
    }
    
    // MARK: - Result Application
    
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
        let (physicsUpdates, physicsTime, _) = await PhysicsActor.shared.getStatistics()
        let (_, logicTime, avgLogicTime) = await GameLogicActor.shared.getStatistics()
        let cacheStats = await AssetLoadingActor.shared.getCacheStats()
        
        return ActorPerformanceStats(
            physicsBodyCount: PhysicsSystem.shared.bodyCount,
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
