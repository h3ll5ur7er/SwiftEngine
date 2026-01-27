import Foundation

/// Infinite plane collider - highly efficient for floors, walls, and boundaries
/// The plane is defined by a normal direction and extends infinitely in perpendicular directions
@MainActor
public final class PlaneCollider: Collider {
    
    /// The normal direction of the plane in local space (default: up)
    public var normal: Vec3d = Vec3d(0, 1, 0)
    
    /// Distance from the transform origin along the normal
    public var distance: Float = 0.0
    
    public override var colliderType: ColliderType { .plane }
    
    public required init() {
        super.init()
    }
    
    /// Create a plane collider with a specific normal
    public convenience init(normal: Vec3d, distance: Float = 0.0) {
        self.init()
        self.normal = normal.normalized
        self.distance = distance
    }
    
    // MARK: - Geometry
    
    /// Get the world-space normal (accounting for rotation)
    public var worldNormal: Vec3d {
        let rot = transform.rotation
        return rot * normal
    }
    
    /// Get the world-space distance from origin
    public var worldDistance: Float {
        let worldPos = transform.position
        let wNormal = worldNormal
        // Distance is transform position projected onto normal, plus local distance
        return worldPos.x * wNormal.x + worldPos.y * wNormal.y + worldPos.z * wNormal.z + distance
    }
    
    /// Get a point on the plane in world space
    public var worldPlanePoint: Vec3d {
        let worldPos = transform.position
        let wNormal = worldNormal
        // Point on plane = transform position + normal * distance + center offset
        return Vec3d(
            worldPos.x + wNormal.x * distance + center.x,
            worldPos.y + wNormal.y * distance + center.y,
            worldPos.z + wNormal.z * distance + center.z
        )
    }
    
    /// Planes have infinite volume, return infinity
    public override var volume: Float {
        return Float.infinity
    }
    
    /// Planes have infinite extent - return infinity to skip broad phase check
    public override var boundingSphereRadius: Float {
        return Float.infinity
    }
    
    // MARK: - Collision Detection
    
    public override func intersects(with other: Collider) -> CollisionInfo? {
        if let box = other as? BoxCollider {
            return intersectsBox(box)
        } else if let sphere = other as? SphereCollider {
            return intersectsSphere(sphere)
        } else if other is PlaneCollider {
            // Plane-plane collision not supported (they're infinite)
            return nil
        }
        return nil
    }
    
    /// Plane vs Box collision
    public override func intersectsBox(_ box: BoxCollider) -> CollisionInfo? {
        let planeNormal = worldNormal
        let planePoint = worldPlanePoint
        
        // Get the box's corners
        let corners = box.worldCorners
        
        // Find the closest (most negative) corner to the plane
        var minDist = Float.greatestFiniteMagnitude
        var closestCorner = corners[0]
        var anyBelow = false
        
        for corner in corners {
            // Signed distance from corner to plane
            let toCorner = Vec3d(
                corner.x - planePoint.x,
                corner.y - planePoint.y,
                corner.z - planePoint.z
            )
            let dist = toCorner.x * planeNormal.x + toCorner.y * planeNormal.y + toCorner.z * planeNormal.z
            
            if dist < minDist {
                minDist = dist
                closestCorner = corner
            }
            if dist < 0 {
                anyBelow = true
            }
        }
        
        // No collision if all corners are above the plane (all distances positive)
        if !anyBelow {
            return nil
        }
        
        // Penetration depth is the negative of the minimum distance (how deep below the plane)
        let penetration = -minDist
        
        // Contact point is the deepest corner
        let contactPoint = closestCorner
        
        // Normal points from plane toward the box (the direction to push the box)
        // This is already planeNormal since planeNormal points "up" from the plane surface
        return CollisionInfo(
            other: box,
            contactPoint: contactPoint,
            normal: planeNormal,
            penetrationDepth: penetration
        )
    }
    
    /// Plane vs Sphere collision
    public override func intersectsSphere(_ sphere: SphereCollider) -> CollisionInfo? {
        let planeNormal = worldNormal
        let planePoint = worldPlanePoint
        let sphereCenter = sphere.worldCenter
        let radius = sphere.radius
        
        // Signed distance from sphere center to plane
        let toSphere = Vec3d(
            sphereCenter.x - planePoint.x,
            sphereCenter.y - planePoint.y,
            sphereCenter.z - planePoint.z
        )
        let dist = toSphere.x * planeNormal.x + toSphere.y * planeNormal.y + toSphere.z * planeNormal.z
        
        // No collision if sphere is above the plane by more than its radius
        if dist > radius {
            return nil
        }
        
        // Penetration depth
        let penetration = radius - dist
        
        // Contact point is on the sphere surface toward the plane
        let contactPoint = Vec3d(
            sphereCenter.x - planeNormal.x * radius,
            sphereCenter.y - planeNormal.y * radius,
            sphereCenter.z - planeNormal.z * radius
        )
        
        return CollisionInfo(
            other: sphere,
            contactPoint: contactPoint,
            normal: planeNormal,
            penetrationDepth: penetration
        )
    }
    
    /// Plane vs Plane - not supported (infinite planes)
    public override func intersectsPlane(_ plane: PlaneCollider) -> CollisionInfo? {
        return nil
    }
}
