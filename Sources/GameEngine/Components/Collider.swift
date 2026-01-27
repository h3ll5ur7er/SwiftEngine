import Foundation

/// Base class for all colliders
/// Subclasses should also conform to ColliderProtocol for type-specific collision detection
@MainActor
open class Collider: Component, ColliderProtocol {
    
    /// The type of this collider (override in subclasses)
    open var colliderType: ColliderType { .custom }
    
    /// Whether this collider is a trigger (doesn't physically collide, just detects)
    public var isTrigger: Bool = false
    
    /// Offset from the transform center
    public var center: Vec3d = .zero
    
    /// Collision layer (objects on same layer collide)
    public var layer: Int = 0
    
    /// Physics material defining friction, bounciness, and density
    public var material: PhysicsMaterial = .default
    
    /// Get the world-space center of this collider
    public var worldCenter: Vec3d {
        let localCenter = center
        let worldPos = transform.position
        return Vec3d(worldPos.x + localCenter.x, worldPos.y + localCenter.y, worldPos.z + localCenter.z)
    }
    
    /// Get the volume of this collider (override in subclasses)
    open var volume: Float {
        return 1.0
    }
    
    /// Calculate mass based on material density and collider volume
    public var calculatedMass: Float {
        return material.density * volume
    }
    
    public required init() {
        super.init()
    }
    
    // MARK: - Lifecycle
    
    open override func onEnable() {
        CollisionManager.shared.register(self)
    }
    
    open override func onDisable() {
        CollisionManager.shared.unregister(self)
    }
    
    open override func onDestroy() {
        CollisionManager.shared.unregister(self)
    }
    
    /// Check if this collider intersects with another (generic dispatch)
    open func intersects(with other: Collider) -> CollisionInfo? {
        // Override in subclasses
        return nil
    }
    
    /// Check if this collider intersects with another (protocol version)
    open func intersects(with other: ColliderProtocol) -> CollisionInfo? {
        if let collider = other as? Collider {
            return intersects(with: collider)
        }
        return nil
    }
    
    /// Check if this collider intersects with a box collider (override in subclasses)
    open func intersectsBox(_ box: BoxCollider) -> CollisionInfo? {
        return nil
    }
    
    /// Check if this collider intersects with a sphere collider (override in subclasses)
    open func intersectsSphere(_ sphere: SphereCollider) -> CollisionInfo? {
        return nil
    }
    
    /// Check if this collider intersects with a plane collider (override in subclasses)
    open func intersectsPlane(_ plane: PlaneCollider) -> CollisionInfo? {
        return nil
    }
    
    /// Get the bounding sphere radius for broad-phase collision
    open var boundingSphereRadius: Float {
        return 1.0
    }
}

/// Information about a collision
public struct CollisionInfo {
    /// The other collider involved
    public let other: Collider
    
    /// Contact point in world space
    public let contactPoint: Vec3d
    
    /// Collision normal (pointing from self toward other)
    public let normal: Vec3d
    
    /// Penetration depth
    public let penetrationDepth: Float
    
    public init(other: Collider, contactPoint: Vec3d, normal: Vec3d, penetrationDepth: Float) {
        self.other = other
        self.contactPoint = contactPoint
        self.normal = normal
        self.penetrationDepth = penetrationDepth
    }
}
