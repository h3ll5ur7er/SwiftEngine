import Foundation

/// Defines the types of collider shapes
public enum ColliderType {
    case box
    case sphere
    case plane
    case capsule
    case mesh
    case custom
}

/// Protocol defining the interface for all collider types
/// This allows for efficient polymorphic collision detection
@MainActor
public protocol ColliderProtocol: AnyObject {
    
    // MARK: - Identity
    
    /// The type of this collider
    var colliderType: ColliderType { get }
    
    // MARK: - Configuration
    
    /// Whether this collider is a trigger (doesn't physically collide, just detects)
    var isTrigger: Bool { get set }
    
    /// Offset from the transform center
    var center: Vec3d { get set }
    
    /// Collision layer (objects on same layer collide)
    var layer: Int { get set }
    
    /// Physics material defining friction, bounciness, and density
    var material: PhysicsMaterial { get set }
    
    // MARK: - Transform Access
    
    /// The transform of the game object this collider is attached to
    var transform: Transform { get }
    
    /// The game object this collider is attached to
    var gameObject: GameObject? { get }
    
    /// Whether this collider is enabled
    var isEnabled: Bool { get }
    
    // MARK: - Geometry
    
    /// Get the world-space center of this collider
    var worldCenter: Vec3d { get }
    
    /// Get the volume of this collider (used for mass calculation)
    var volume: Float { get }
    
    /// Calculate mass based on material density and collider volume
    var calculatedMass: Float { get }
    
    /// Bounding sphere radius for broad-phase collision detection
    var boundingSphereRadius: Float { get }
    
    // MARK: - Collision Detection
    
    /// Check if this collider intersects with another collider
    /// Returns collision info if intersecting, nil otherwise
    func intersects(with other: ColliderProtocol) -> CollisionInfo?
    
    /// Check if this collider intersects with a box collider
    func intersectsBox(_ box: BoxCollider) -> CollisionInfo?
    
    /// Check if this collider intersects with a sphere collider
    func intersectsSphere(_ sphere: SphereCollider) -> CollisionInfo?
    
    /// Check if this collider intersects with a plane collider
    func intersectsPlane(_ plane: PlaneCollider) -> CollisionInfo?
}

// MARK: - Default Implementations

extension ColliderProtocol {
    
    /// Default calculated mass based on density and volume
    public var calculatedMass: Float {
        return material.density * volume
    }
    
    /// Default world center calculation
    public var worldCenter: Vec3d {
        let localCenter = center
        let worldPos = transform.position
        return Vec3d(worldPos.x + localCenter.x, worldPos.y + localCenter.y, worldPos.z + localCenter.z)
    }
}
