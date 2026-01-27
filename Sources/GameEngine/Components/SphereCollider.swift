import Foundation

/// Sphere-shaped collider
@MainActor
public final class SphereCollider: Collider {
    
    public override var colliderType: ColliderType { .sphere }
    
    /// Radius of the sphere
    public var radius: Float = 0.5
    
    public required init() {
        super.init()
    }
    
    public convenience init(radius: Float) {
        self.init()
        self.radius = radius
    }
    
    public override var boundingSphereRadius: Float {
        return radius
    }
    
    /// Volume of the sphere in cubic meters (4/3 * π * r³)
    public override var volume: Float {
        return (4.0 / 3.0) * Float.pi * radius * radius * radius
    }
    
    public override func intersects(with other: Collider) -> CollisionInfo? {
        if let sphereB = other as? SphereCollider {
            return intersectsSphere(sphereB)
        } else if let boxB = other as? BoxCollider {
            return intersectsBox(boxB)
        } else if let planeB = other as? PlaneCollider {
            return intersectsPlane(planeB)
        }
        return nil
    }
    
    /// Sphere vs Box collision (delegate to box's implementation)
    public override func intersectsBox(_ box: BoxCollider) -> CollisionInfo? {
        if let info = box.intersectsSphere(self) {
            return CollisionInfo(
                other: box,
                contactPoint: info.contactPoint,
                normal: Vec3d(-info.normal.x, -info.normal.y, -info.normal.z),
                penetrationDepth: info.penetrationDepth
            )
        }
        return nil
    }
    
    /// Sphere vs Sphere collision
    public override func intersectsSphere(_ other: SphereCollider) -> CollisionInfo? {
        let centerA = worldCenter
        let centerB = other.worldCenter
        
        let dx = centerB.x - centerA.x
        let dy = centerB.y - centerA.y
        let dz = centerB.z - centerA.z
        let distSquared = dx * dx + dy * dy + dz * dz
        
        let radiusSum = radius + other.radius
        let radiusSumSquared = radiusSum * radiusSum
        
        if distSquared > radiusSumSquared {
            return nil
        }
        
        let dist = sqrt(distSquared)
        let penetration = radiusSum - dist
        
        var normal: Vec3d
        if dist > 0.0001 {
            normal = Vec3d(dx / dist, dy / dist, dz / dist)
        } else {
            // Spheres are at same position, arbitrary normal
            normal = Vec3d(0, 1, 0)
        }
        
        // Contact point is on the surface of this sphere toward the other
        let contactPoint = Vec3d(
            centerA.x + normal.x * radius,
            centerA.y + normal.y * radius,
            centerA.z + normal.z * radius
        )
        
        return CollisionInfo(
            other: other,
            contactPoint: contactPoint,
            normal: normal,
            penetrationDepth: penetration
        )
    }
    
    /// Sphere vs Plane collision (delegate to plane's implementation)
    public override func intersectsPlane(_ plane: PlaneCollider) -> CollisionInfo? {
        if let info = plane.intersectsSphere(self) {
            return CollisionInfo(
                other: plane,
                contactPoint: info.contactPoint,
                normal: Vec3d(-info.normal.x, -info.normal.y, -info.normal.z),
                penetrationDepth: info.penetrationDepth
            )
        }
        return nil
    }
}
