import Foundation

/// Registry of active colliders and the collision callback.
/// Detection and response run in PhysicsSimulation, driven by PhysicsSystem.
@MainActor
public final class CollisionManager {
    
    /// Shared instance
    public static let shared = CollisionManager()
    
    /// All active colliders
    private var colliders: [Collider] = []
    
    /// Called once per frame for each overlapping collider pair (including triggers).
    /// The info's normal points from the first collider toward the second.
    public var onCollision: ((Collider, Collider, CollisionInfo) -> Void)?
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register a collider
    public func register(_ collider: Collider) {
        if !colliders.contains(where: { $0 === collider }) {
            colliders.append(collider)
        }
    }
    
    /// Unregister a collider
    public func unregister(_ collider: Collider) {
        colliders.removeAll { $0 === collider }
    }
    
    /// Clear all colliders
    public func clear() {
        colliders.removeAll()
    }
    
    /// Get the number of registered colliders
    public var colliderCount: Int {
        colliders.count
    }
    
    /// Get all registered colliders (for debug drawing)
    public var allColliders: [Collider] {
        colliders
    }
}
