import Foundation

/// Quaternion for 3D rotations
/// Represented as q = w + xi + yj + zk
public struct Quaternion: Equatable, Hashable, Sendable {
    public var x: Float32
    public var y: Float32
    public var z: Float32
    public var w: Float32
    
    public init(x: Float32, y: Float32, z: Float32, w: Float32) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(_ x: Float32, _ y: Float32, _ z: Float32, _ w: Float32) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    // MARK: - Static Constructors
    
    /// Identity quaternion (no rotation)
    public static let identity = Quaternion(0, 0, 0, 1)
    
    /// Create quaternion from axis-angle representation
    public static func fromAxisAngle(axis: Vec3d, angle: Float32) -> Quaternion {
        let halfAngle = angle * 0.5
        let s = sin(halfAngle)
        let normalizedAxis = axis.normalized
        return Quaternion(
            normalizedAxis.x * s,
            normalizedAxis.y * s,
            normalizedAxis.z * s,
            cos(halfAngle)
        )
    }
    
    /// Create quaternion from Euler angles (in radians)
    /// Order: ZYX (yaw, pitch, roll)
    public static func fromEulerAngles(pitch: Float32, yaw: Float32, roll: Float32) -> Quaternion {
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)
        
        return Quaternion(
            sr * cp * cy - cr * sp * sy,
            cr * sp * cy + sr * cp * sy,
            cr * cp * sy - sr * sp * cy,
            cr * cp * cy + sr * sp * sy
        )
    }
    
    /// Create quaternion that rotates from one direction to another
    public static func fromTo(from: Vec3d, to: Vec3d) -> Quaternion {
        let f = from.normalized
        let t = to.normalized
        let dot = f.dot(t)
        
        if dot >= 1.0 - Float32.ulpOfOne {
            return .identity
        }
        
        if dot <= -1.0 + Float32.ulpOfOne {
            // Vectors are opposite, find perpendicular axis
            var axis = Vec3d.unitX.cross(f)
            if axis.squaredLength < Float32.ulpOfOne {
                axis = Vec3d.unitY.cross(f)
            }
            return fromAxisAngle(axis: axis.normalized, angle: .pi)
        }
        
        let axis = f.cross(t)
        return Quaternion(
            axis.x,
            axis.y,
            axis.z,
            1 + dot
        ).normalized
    }
    
    /// Create rotation quaternion looking in a direction
    public static func lookRotation(forward: Vec3d, up: Vec3d = .unitY) -> Quaternion {
        let f = forward.normalized
        let r = up.cross(f).normalized
        let u = f.cross(r)
        
        let m00 = r.x, m01 = r.y, m02 = r.z
        let m10 = u.x, m11 = u.y, m12 = u.z
        let m20 = f.x, m21 = f.y, m22 = f.z
        
        let trace = m00 + m11 + m22
        
        if trace > 0 {
            let s = 0.5 / sqrt(trace + 1)
            return Quaternion(
                (m12 - m21) * s,
                (m20 - m02) * s,
                (m01 - m10) * s,
                0.25 / s
            )
        } else if m00 > m11 && m00 > m22 {
            let s = 2 * sqrt(1 + m00 - m11 - m22)
            return Quaternion(
                0.25 * s,
                (m01 + m10) / s,
                (m02 + m20) / s,
                (m12 - m21) / s
            )
        } else if m11 > m22 {
            let s = 2 * sqrt(1 + m11 - m00 - m22)
            return Quaternion(
                (m01 + m10) / s,
                0.25 * s,
                (m12 + m21) / s,
                (m20 - m02) / s
            )
        } else {
            let s = 2 * sqrt(1 + m22 - m00 - m11)
            return Quaternion(
                (m02 + m20) / s,
                (m12 + m21) / s,
                0.25 * s,
                (m01 - m10) / s
            )
        }
    }
    
    // MARK: - Arithmetic Operations
    
    /// Quaternion multiplication (combines rotations)
    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }
    
    /// Rotate a vector by this quaternion
    public static func * (lhs: Quaternion, rhs: Vec3d) -> Vec3d {
        let qv = Vec3d(lhs.x, lhs.y, lhs.z)
        let uv = qv.cross(rhs)
        let uuv = qv.cross(uv)
        return rhs + 2.0 * (lhs.w * uv + uuv)
    }
    
    /// Scalar multiplication
    public static func * (lhs: Quaternion, rhs: Float32) -> Quaternion {
        Quaternion(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }
    
    public static func * (lhs: Float32, rhs: Quaternion) -> Quaternion {
        rhs * lhs
    }
    
    /// Quaternion addition
    public static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }
    
    /// Quaternion subtraction
    public static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }
    
    /// Negation
    public static prefix func - (q: Quaternion) -> Quaternion {
        Quaternion(-q.x, -q.y, -q.z, -q.w)
    }
    
    // MARK: - Properties
    
    /// Squared length
    public var squaredLength: Float32 {
        x * x + y * y + z * z + w * w
    }
    
    /// Length/magnitude
    public var length: Float32 {
        sqrt(squaredLength)
    }
    
    /// Normalized quaternion (unit quaternion)
    public var normalized: Quaternion {
        let len = length
        guard len > 0 else { return .identity }
        return self * (1 / len)
    }
    
    /// Conjugate (inverse rotation for unit quaternions)
    public var conjugate: Quaternion {
        Quaternion(-x, -y, -z, w)
    }
    
    /// Inverse quaternion
    public var inverse: Quaternion {
        let sqLen = squaredLength
        guard sqLen > 0 else { return .identity }
        return conjugate * (1 / sqLen)
    }
    
    /// Dot product
    public func dot(_ other: Quaternion) -> Float32 {
        x * other.x + y * other.y + z * other.z + w * other.w
    }
    
    /// Get rotation axis (assumes unit quaternion)
    public var axis: Vec3d {
        let sinHalfAngle = sqrt(1 - w * w)
        guard sinHalfAngle > Float32.ulpOfOne else {
            return Vec3d.unitZ  // Any axis when angle is 0
        }
        return Vec3d(x / sinHalfAngle, y / sinHalfAngle, z / sinHalfAngle)
    }
    
    /// Get rotation angle in radians (assumes unit quaternion)
    public var angle: Float32 {
        2 * acos(min(max(w, -1), 1))
    }
    
    /// Convert to Euler angles (pitch, yaw, roll) in radians
    public var eulerAngles: (pitch: Float32, yaw: Float32, roll: Float32) {
        // Roll (x-axis rotation)
        let sinr_cosp = 2 * (w * x + y * z)
        let cosr_cosp = 1 - 2 * (x * x + y * y)
        let roll = atan2(sinr_cosp, cosr_cosp)
        
        // Pitch (y-axis rotation)
        let sinp = 2 * (w * y - z * x)
        let pitch: Float32
        if abs(sinp) >= 1 {
            pitch = copysign(.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }
        
        // Yaw (z-axis rotation)
        let siny_cosp = 2 * (w * z + x * y)
        let cosy_cosp = 1 - 2 * (y * y + z * z)
        let yaw = atan2(siny_cosp, cosy_cosp)
        
        return (pitch, yaw, roll)
    }
    
    // MARK: - Conversion to Matrix
    
    /// Convert to 3x3 rotation matrix
    public var toMat3d: Mat3d {
        let xx = x * x, yy = y * y, zz = z * z
        let xy = x * y, xz = x * z, yz = y * z
        let wx = w * x, wy = w * y, wz = w * z
        
        return Mat3d(
            m00: 1 - 2 * (yy + zz), m01: 2 * (xy - wz),     m02: 2 * (xz + wy),
            m10: 2 * (xy + wz),     m11: 1 - 2 * (xx + zz), m12: 2 * (yz - wx),
            m20: 2 * (xz - wy),     m21: 2 * (yz + wx),     m22: 1 - 2 * (xx + yy)
        )
    }
    
    /// Convert to 4x4 rotation matrix
    public var toMat4d: Mat4d {
        let xx = x * x, yy = y * y, zz = z * z
        let xy = x * y, xz = x * z, yz = y * z
        let wx = w * x, wy = w * y, wz = w * z
        
        return Mat4d(
            m00: 1 - 2 * (yy + zz), m01: 2 * (xy - wz),     m02: 2 * (xz + wy),     m03: 0,
            m10: 2 * (xy + wz),     m11: 1 - 2 * (xx + zz), m12: 2 * (yz - wx),     m13: 0,
            m20: 2 * (xz - wy),     m21: 2 * (yz + wx),     m22: 1 - 2 * (xx + yy), m23: 0,
            m30: 0,                 m31: 0,                 m32: 0,                 m33: 1
        )
    }
    
    // MARK: - Interpolation
    
    /// Linear interpolation (not recommended for rotations, use slerp)
    public func lerp(to other: Quaternion, t: Float32) -> Quaternion {
        (self * (1 - t) + other * t).normalized
    }
    
    /// Spherical linear interpolation (smooth rotation)
    public func slerp(to other: Quaternion, t: Float32) -> Quaternion {
        var other = other
        var dot = self.dot(other)
        
        // If dot is negative, negate one quaternion to take shorter path
        if dot < 0 {
            other = -other
            dot = -dot
        }
        
        // If quaternions are very close, use linear interpolation
        if dot > 0.9995 {
            return lerp(to: other, t: t)
        }
        
        let theta0 = acos(dot)
        let theta = theta0 * t
        let sinTheta = sin(theta)
        let sinTheta0 = sin(theta0)
        
        let s0 = cos(theta) - dot * sinTheta / sinTheta0
        let s1 = sinTheta / sinTheta0
        
        return self * s0 + other * s1
    }
}

extension Quaternion: CustomStringConvertible {
    public var description: String {
        "(x: \(x), y: \(y), z: \(z), w: \(w))"
    }
}
