import Foundation

/// Box-shaped collider
@MainActor
public final class BoxCollider: Collider {
    
    public override var colliderType: ColliderType { .box }
    
    /// Half-extents of the box (size / 2) in local space
    public var halfExtents: Vec3d = Vec3d(0.5, 0.5, 0.5)
    
    /// Full size of the box
    public var size: Vec3d {
        get { Vec3d(halfExtents.x * 2, halfExtents.y * 2, halfExtents.z * 2) }
        set { halfExtents = Vec3d(newValue.x / 2, newValue.y / 2, newValue.z / 2) }
    }
    
    public required init() {
        super.init()
    }
    
    public convenience init(size: Vec3d) {
        self.init()
        self.size = size
    }
    
    public convenience init(halfExtents: Vec3d) {
        self.init()
        self.halfExtents = halfExtents
    }
    
    public override var boundingSphereRadius: Float {
        // Diagonal of the box
        let hx = halfExtents.x
        let hy = halfExtents.y
        let hz = halfExtents.z
        return sqrt(hx * hx + hy * hy + hz * hz)
    }
    
    /// Volume of the box in cubic meters
    public override var volume: Float {
        return halfExtents.x * 2 * halfExtents.y * 2 * halfExtents.z * 2
    }
    
    /// Get the 8 corners of the box in world space (accounting for rotation)
    public var worldCorners: [Vec3d] {
        let c = worldCenter
        let rot = transform.rotation
        let hx = halfExtents.x
        let hy = halfExtents.y
        let hz = halfExtents.z
        
        // Local space corners
        let localCorners: [Vec3d] = [
            Vec3d(-hx, -hy, -hz),
            Vec3d( hx, -hy, -hz),
            Vec3d( hx,  hy, -hz),
            Vec3d(-hx,  hy, -hz),
            Vec3d(-hx, -hy,  hz),
            Vec3d( hx, -hy,  hz),
            Vec3d( hx,  hy,  hz),
            Vec3d(-hx,  hy,  hz),
        ]
        
        // Transform corners to world space
        return localCorners.map { corner in
            let rotated = rot * corner
            return Vec3d(c.x + rotated.x, c.y + rotated.y, c.z + rotated.z)
        }
    }
    
    /// Get the AABB min corner in world space (accounts for rotation)
    public var worldMin: Vec3d {
        let corners = worldCorners
        var minX = corners[0].x
        var minY = corners[0].y
        var minZ = corners[0].z
        
        for corner in corners.dropFirst() {
            minX = min(minX, corner.x)
            minY = min(minY, corner.y)
            minZ = min(minZ, corner.z)
        }
        
        return Vec3d(minX, minY, minZ)
    }
    
    /// Get the AABB max corner in world space (accounts for rotation)
    public var worldMax: Vec3d {
        let corners = worldCorners
        var maxX = corners[0].x
        var maxY = corners[0].y
        var maxZ = corners[0].z
        
        for corner in corners.dropFirst() {
            maxX = max(maxX, corner.x)
            maxY = max(maxY, corner.y)
            maxZ = max(maxZ, corner.z)
        }
        
        return Vec3d(maxX, maxY, maxZ)
    }
    
    public override func intersects(with other: Collider) -> CollisionInfo? {
        if let boxB = other as? BoxCollider {
            return intersectsBox(boxB)
        } else if let sphereB = other as? SphereCollider {
            return intersectsSphere(sphereB)
        } else if let planeB = other as? PlaneCollider {
            return intersectsPlane(planeB)
        }
        return nil
    }
    
    /// AABB vs AABB collision (simplified, ignores rotation)
    public override func intersectsBox(_ other: BoxCollider) -> CollisionInfo? {
        let minA = worldMin
        let maxA = worldMax
        let minB = other.worldMin
        let maxB = other.worldMax
        
        // Check for separation on each axis
        if maxA.x < minB.x || minA.x > maxB.x { return nil }
        if maxA.y < minB.y || minA.y > maxB.y { return nil }
        if maxA.z < minB.z || minA.z > maxB.z { return nil }
        
        // Calculate overlap on each axis
        let overlapX = min(maxA.x - minB.x, maxB.x - minA.x)
        let overlapY = min(maxA.y - minB.y, maxB.y - minA.y)
        let overlapZ = min(maxA.z - minB.z, maxB.z - minA.z)
        
        // Find minimum overlap axis (collision normal)
        var normal: Vec3d
        var penetration: Float
        
        if overlapX <= overlapY && overlapX <= overlapZ {
            penetration = overlapX
            // Normal points from A to B (direction to push A away)
            normal = worldCenter.x < other.worldCenter.x ? Vec3d(1, 0, 0) : Vec3d(-1, 0, 0)
        } else if overlapY <= overlapX && overlapY <= overlapZ {
            penetration = overlapY
            normal = worldCenter.y < other.worldCenter.y ? Vec3d(0, 1, 0) : Vec3d(0, -1, 0)
        } else {
            penetration = overlapZ
            normal = worldCenter.z < other.worldCenter.z ? Vec3d(0, 0, 1) : Vec3d(0, 0, -1)
        }
        
        // Contact point is midpoint between the two centers projected onto collision surface
        let centerA = worldCenter
        let centerB = other.worldCenter
        let contactPoint = Vec3d(
            (centerA.x + centerB.x) / 2,
            (centerA.y + centerB.y) / 2,
            (centerA.z + centerB.z) / 2
        )
        
        return CollisionInfo(
            other: other,
            contactPoint: contactPoint,
            normal: normal,
            penetrationDepth: penetration
        )
    }
    
    /// AABB vs Sphere collision
    public override func intersectsSphere(_ sphere: SphereCollider) -> CollisionInfo? {
        let sphereCenter = sphere.worldCenter
        let boxMin = worldMin
        let boxMax = worldMax
        
        // Find closest point on box to sphere center
        let closestX = max(boxMin.x, min(sphereCenter.x, boxMax.x))
        let closestY = max(boxMin.y, min(sphereCenter.y, boxMax.y))
        let closestZ = max(boxMin.z, min(sphereCenter.z, boxMax.z))
        let closestPoint = Vec3d(closestX, closestY, closestZ)
        
        // Calculate distance from closest point to sphere center
        let dx = sphereCenter.x - closestPoint.x
        let dy = sphereCenter.y - closestPoint.y
        let dz = sphereCenter.z - closestPoint.z
        let distSquared = dx * dx + dy * dy + dz * dz
        
        let radiusSquared = sphere.radius * sphere.radius
        
        if distSquared > radiusSquared {
            return nil
        }
        
        let dist = sqrt(distSquared)
        let penetration = sphere.radius - dist
        
        var normal: Vec3d
        if dist > 0.0001 {
            normal = Vec3d(dx / dist, dy / dist, dz / dist)
        } else {
            // Sphere center is inside box, push out on shortest axis
            normal = Vec3d(0, 1, 0)
        }
        
        return CollisionInfo(
            other: sphere,
            contactPoint: closestPoint,
            normal: Vec3d(-normal.x, -normal.y, -normal.z), // Point toward sphere
            penetrationDepth: penetration
        )
    }
    
    /// Box vs Plane collision
    public override func intersectsPlane(_ plane: PlaneCollider) -> CollisionInfo? {
        // Delegate to plane's implementation and flip the result
        if let info = plane.intersectsBox(self) {
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
