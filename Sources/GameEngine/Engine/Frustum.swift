import Foundation

/// Represents a plane in 3D space using the equation: ax + by + cz + d = 0
public struct Plane: Sendable {
    public var normal: Vec3d
    public var distance: Float  // d in the plane equation
    
    public init(normal: Vec3d, distance: Float) {
        self.normal = normal
        self.distance = distance
    }
    
    /// Create a plane from three points (counter-clockwise winding)
    public static func fromPoints(_ p0: Vec3d, _ p1: Vec3d, _ p2: Vec3d) -> Plane {
        let v1 = p1 - p0
        let v2 = p2 - p0
        let normal = v1.cross(v2).normalized
        let distance = -normal.dot(p0)
        return Plane(normal: normal, distance: distance)
    }
    
    /// Create a plane from a point and normal
    public static func fromPointNormal(point: Vec3d, normal: Vec3d) -> Plane {
        let n = normal.normalized
        return Plane(normal: n, distance: -n.dot(point))
    }
    
    /// Signed distance from point to plane (positive = in front, negative = behind)
    public func distanceToPoint(_ point: Vec3d) -> Float {
        normal.dot(point) + distance
    }
    
    /// Check if a point is in front of the plane
    public func isInFront(_ point: Vec3d) -> Bool {
        distanceToPoint(point) > 0
    }
    
    /// Normalize the plane
    public var normalized: Plane {
        let len = normal.length
        guard len > 0 else { return self }
        return Plane(normal: normal / len, distance: distance / len)
    }
}

/// View frustum for culling and clipping
public struct Frustum: Sendable {
    /// The six planes of the frustum
    /// Order: Left, Right, Bottom, Top, Near, Far
    public var planes: [Plane]
    
    public init(planes: [Plane]) {
        self.planes = planes
    }
    
    /// Extract frustum planes from a view-projection matrix
    public static func fromViewProjection(_ vp: Mat4d) -> Frustum {
        // Extract planes from the view-projection matrix
        // Using Gribb/Hartmann method
        
        var planes: [Plane] = []
        
        // Left plane: row3 + row0
        let left = Plane(
            normal: Vec3d(vp.m30 + vp.m00, vp.m31 + vp.m01, vp.m32 + vp.m02),
            distance: vp.m33 + vp.m03
        ).normalized
        planes.append(left)
        
        // Right plane: row3 - row0
        let right = Plane(
            normal: Vec3d(vp.m30 - vp.m00, vp.m31 - vp.m01, vp.m32 - vp.m02),
            distance: vp.m33 - vp.m03
        ).normalized
        planes.append(right)
        
        // Bottom plane: row3 + row1
        let bottom = Plane(
            normal: Vec3d(vp.m30 + vp.m10, vp.m31 + vp.m11, vp.m32 + vp.m12),
            distance: vp.m33 + vp.m13
        ).normalized
        planes.append(bottom)
        
        // Top plane: row3 - row1
        let top = Plane(
            normal: Vec3d(vp.m30 - vp.m10, vp.m31 - vp.m11, vp.m32 - vp.m12),
            distance: vp.m33 - vp.m13
        ).normalized
        planes.append(top)
        
        // Near plane: row3 + row2
        let near = Plane(
            normal: Vec3d(vp.m30 + vp.m20, vp.m31 + vp.m21, vp.m32 + vp.m22),
            distance: vp.m33 + vp.m23
        ).normalized
        planes.append(near)
        
        // Far plane: row3 - row2
        let far = Plane(
            normal: Vec3d(vp.m30 - vp.m20, vp.m31 - vp.m21, vp.m32 - vp.m22),
            distance: vp.m33 - vp.m23
        ).normalized
        planes.append(far)
        
        return Frustum(planes: planes)
    }
    
    /// Test if a point is inside the frustum
    public func containsPoint(_ point: Vec3d) -> Bool {
        for plane in planes {
            if plane.distanceToPoint(point) < 0 {
                return false
            }
        }
        return true
    }
    
    /// Test if a sphere intersects the frustum
    public func intersectsSphere(center: Vec3d, radius: Float) -> Bool {
        for plane in planes {
            if plane.distanceToPoint(center) < -radius {
                return false
            }
        }
        return true
    }
    
    /// Test if an AABB intersects the frustum
    public func intersectsBounds(_ bounds: Bounds) -> Bool {
        for plane in planes {
            // Find the positive vertex (furthest along plane normal)
            let px = plane.normal.x >= 0 ? bounds.max.x : bounds.min.x
            let py = plane.normal.y >= 0 ? bounds.max.y : bounds.min.y
            let pz = plane.normal.z >= 0 ? bounds.max.z : bounds.min.z
            let pVertex = Vec3d(px, py, pz)
            
            if plane.distanceToPoint(pVertex) < 0 {
                return false
            }
        }
        return true
    }
}

/// Clipping result for a line segment
public enum ClipResult {
    case fullyInside
    case fullyOutside
    case clipped(start: Vec3d, end: Vec3d)
}

/// Utility for clipping lines against the view frustum
public struct LineClipper {
    
    /// Clip a line segment against a single plane using parametric clipping
    public static func clipLineToPlane(
        start: Vec3d,
        end: Vec3d,
        plane: Plane
    ) -> ClipResult {
        let startDist = plane.distanceToPoint(start)
        let endDist = plane.distanceToPoint(end)
        
        // Both points in front of plane
        if startDist >= 0 && endDist >= 0 {
            return .fullyInside
        }
        
        // Both points behind plane
        if startDist < 0 && endDist < 0 {
            return .fullyOutside
        }
        
        // Line crosses plane - compute intersection
        let t = startDist / (startDist - endDist)
        let intersection = start + (end - start) * t
        
        if startDist >= 0 {
            // Start is inside, end is outside
            return .clipped(start: start, end: intersection)
        } else {
            // Start is outside, end is inside
            return .clipped(start: intersection, end: end)
        }
    }
    
    /// Clip a line segment against all frustum planes
    public static func clipLineToFrustum(
        start: Vec3d,
        end: Vec3d,
        frustum: Frustum
    ) -> ClipResult {
        var clippedStart = start
        var clippedEnd = end
        
        for plane in frustum.planes {
            switch clipLineToPlane(start: clippedStart, end: clippedEnd, plane: plane) {
            case .fullyInside:
                continue
            case .fullyOutside:
                return .fullyOutside
            case .clipped(let newStart, let newEnd):
                clippedStart = newStart
                clippedEnd = newEnd
            }
        }
        
        // Check if any clipping actually occurred
        if clippedStart == start && clippedEnd == end {
            return .fullyInside
        }
        
        return .clipped(start: clippedStart, end: clippedEnd)
    }
    
    /// Clip a line in clip space (after MVP transform) against the near plane
    /// This is a simpler approach that works with homogeneous coordinates
    public static func clipLineToNearPlane(
        v0: Vec4d,
        v1: Vec4d,
        nearW: Float = 0.001
    ) -> (v0: Vec4d, v1: Vec4d, visible: Bool) {
        let w0 = v0.w
        let w1 = v1.w
        
        // Both vertices behind near plane
        if w0 < nearW && w1 < nearW {
            return (v0, v1, false)
        }
        
        // Both vertices in front of near plane
        if w0 >= nearW && w1 >= nearW {
            return (v0, v1, true)
        }
        
        // One vertex needs clipping
        let t = (nearW - w0) / (w1 - w0)
        let clipped = Vec4d(
            v0.x + t * (v1.x - v0.x),
            v0.y + t * (v1.y - v0.y),
            v0.z + t * (v1.z - v0.z),
            nearW
        )
        
        if w0 < nearW {
            return (clipped, v1, true)
        } else {
            return (v0, clipped, true)
        }
    }
}
