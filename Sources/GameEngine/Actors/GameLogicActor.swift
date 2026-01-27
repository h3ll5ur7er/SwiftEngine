import Foundation
@preconcurrency import WinSDK

/// Snapshot of a component's update state
public struct ComponentUpdateData: Sendable {
    public let gameObjectId: GameUUID
    public let componentTypeName: String
    public let isEnabled: Bool
    
    public init(gameObjectId: GameUUID, componentTypeName: String, isEnabled: Bool) {
        self.gameObjectId = gameObjectId
        self.componentTypeName = componentTypeName
        self.isEnabled = isEnabled
    }
}

/// Snapshot of a game object's state for concurrent processing
public struct GameObjectSnapshot: Sendable {
    public let id: GameUUID
    public let name: String
    public let isActive: Bool
    public let position: Vec3d
    public let rotation: Quaternion
    public let scale: Vec3d
    public let components: [ComponentUpdateData]
    
    public init(
        id: GameUUID,
        name: String,
        isActive: Bool,
        position: Vec3d,
        rotation: Quaternion,
        scale: Vec3d,
        components: [ComponentUpdateData]
    ) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.components = components
    }
}

/// Result of game logic processing
public struct GameLogicResult: Sendable {
    public let processedCount: Int
    public let processingTime: Double
    public let transformUpdates: [GameUUID: TransformUpdate]
    
    public init(processedCount: Int, processingTime: Double, transformUpdates: [GameUUID: TransformUpdate]) {
        self.processedCount = processedCount
        self.processingTime = processingTime
        self.transformUpdates = transformUpdates
    }
}

/// Update to apply to a transform
public struct TransformUpdate: Sendable {
    public let position: Vec3d?
    public let rotation: Quaternion?
    public let scale: Vec3d?
    
    public init(position: Vec3d? = nil, rotation: Quaternion? = nil, scale: Vec3d? = nil) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

/// Actor responsible for running game logic updates concurrently
/// Processes component updates that don't require MainActor isolation
public actor GameLogicActor {
    
    /// Shared instance
    public static let shared = GameLogicActor()
    
    /// Registered update handlers (keyed by component type name)
    private var updateHandlers: [String: @Sendable (GameObjectSnapshot, Float) async -> TransformUpdate?] = [:]
    
    /// Custom game logic tasks to run each frame
    private var customTasks: [String: @Sendable (Float) async -> Void] = [:]
    
    /// Statistics
    private var totalUpdatesProcessed: UInt64 = 0
    private var totalProcessingTime: Double = 0
    
    public init() {}
    
    // MARK: - Handler Registration
    
    /// Register a custom update handler for a component type
    public func registerHandler(
        for componentType: String,
        handler: @escaping @Sendable (GameObjectSnapshot, Float) async -> TransformUpdate?
    ) {
        updateHandlers[componentType] = handler
    }
    
    /// Unregister a handler
    public func unregisterHandler(for componentType: String) {
        updateHandlers.removeValue(forKey: componentType)
    }
    
    /// Register a custom task to run each frame
    public func registerTask(name: String, task: @escaping @Sendable (Float) async -> Void) {
        customTasks[name] = task
    }
    
    /// Unregister a custom task
    public func unregisterTask(name: String) {
        customTasks.removeValue(forKey: name)
    }
    
    // MARK: - Processing
    
    /// Process game logic for a batch of game objects
    /// Returns transform updates to apply back on MainActor
    public func processGameObjects(
        _ snapshots: [GameObjectSnapshot],
        deltaTime: Float
    ) async -> GameLogicResult {
        let startTime = GetTickCount64()
        var transformUpdates: [GameUUID: TransformUpdate] = [:]
        var processedCount = 0
        
        // Process in parallel using task groups
        await withTaskGroup(of: (GameUUID, TransformUpdate?).self) { group in
            for snapshot in snapshots where snapshot.isActive {
                group.addTask {
                    var combinedUpdate: TransformUpdate? = nil
                    
                    // Process each component with registered handlers
                    for component in snapshot.components where component.isEnabled {
                        if let handler = await self.updateHandlers[component.componentTypeName] {
                            if let update = await handler(snapshot, deltaTime) {
                                // Combine updates
                                combinedUpdate = TransformUpdate(
                                    position: update.position ?? combinedUpdate?.position,
                                    rotation: update.rotation ?? combinedUpdate?.rotation,
                                    scale: update.scale ?? combinedUpdate?.scale
                                )
                            }
                        }
                    }
                    
                    return (snapshot.id, combinedUpdate)
                }
            }
            
            // Collect results
            for await (id, update) in group {
                processedCount += 1
                if let update = update {
                    transformUpdates[id] = update
                }
            }
        }
        
        // Run custom tasks
        await withTaskGroup(of: Void.self) { group in
            for (_, task) in customTasks {
                group.addTask {
                    await task(deltaTime)
                }
            }
        }
        
        let processingTime = Double(GetTickCount64() - startTime) / 1000.0
        totalUpdatesProcessed += UInt64(processedCount)
        totalProcessingTime += processingTime
        
        return GameLogicResult(
            processedCount: processedCount,
            processingTime: processingTime,
            transformUpdates: transformUpdates
        )
    }
    
    // MARK: - AI/Pathfinding Support
    
    /// Batch process AI decisions (can be parallelized)
    public func processAIDecisions(
        entities: [AIEntityState],
        worldState: WorldStateSnapshot
    ) async -> [GameUUID: AIDecision] {
        await withTaskGroup(of: (GameUUID, AIDecision).self) { group in
            for entity in entities {
                group.addTask {
                    let decision = await self.computeAIDecision(for: entity, world: worldState)
                    return (entity.id, decision)
                }
            }
            
            var results: [GameUUID: AIDecision] = [:]
            for await (id, decision) in group {
                results[id] = decision
            }
            return results
        }
    }
    
    private func computeAIDecision(for entity: AIEntityState, world: WorldStateSnapshot) async -> AIDecision {
        // Placeholder AI logic - override via registered handlers
        return AIDecision(targetPosition: nil, action: .idle)
    }
    
    // MARK: - Statistics
    
    /// Get processing statistics
    public func getStatistics() -> (totalUpdates: UInt64, totalTime: Double, avgTimePerUpdate: Double) {
        let avg = totalUpdatesProcessed > 0 ? totalProcessingTime / Double(totalUpdatesProcessed) : 0
        return (totalUpdatesProcessed, totalProcessingTime, avg)
    }
    
    /// Reset statistics
    public func resetStatistics() {
        totalUpdatesProcessed = 0
        totalProcessingTime = 0
    }
}

// MARK: - AI Support Types

/// State of an AI entity for decision making
public struct AIEntityState: Sendable {
    public let id: GameUUID
    public let position: Vec3d
    public let health: Float
    public let targetId: GameUUID?
    public let state: String
    
    public init(id: GameUUID, position: Vec3d, health: Float, targetId: GameUUID?, state: String) {
        self.id = id
        self.position = position
        self.health = health
        self.targetId = targetId
        self.state = state
    }
}

/// Snapshot of world state for AI reasoning
public struct WorldStateSnapshot: Sendable {
    public let entities: [GameUUID: Vec3d]
    public let playerPosition: Vec3d?
    public let time: Double
    
    public init(entities: [GameUUID: Vec3d], playerPosition: Vec3d?, time: Double) {
        self.entities = entities
        self.playerPosition = playerPosition
        self.time = time
    }
}

/// AI decision result
public struct AIDecision: Sendable {
    public let targetPosition: Vec3d?
    public let action: AIAction
    
    public init(targetPosition: Vec3d?, action: AIAction) {
        self.targetPosition = targetPosition
        self.action = action
    }
}

/// AI action types
public enum AIAction: Sendable {
    case idle
    case move(Vec3d)
    case attack(GameUUID)
    case flee
    case patrol
}
