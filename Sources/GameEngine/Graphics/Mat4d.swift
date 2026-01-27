import Foundation

public struct Mat4d: Equatable, Hashable, Sendable {
    public var m00: Float32, m01: Float32, m02: Float32, m03: Float32
    public var m10: Float32, m11: Float32, m12: Float32, m13: Float32
    public var m20: Float32, m21: Float32, m22: Float32, m23: Float32
    public var m30: Float32, m31: Float32, m32: Float32, m33: Float32
    
    public init(m00: Float32, m01: Float32, m02: Float32, m03: Float32,
                m10: Float32, m11: Float32, m12: Float32, m13: Float32,
                m20: Float32, m21: Float32, m22: Float32, m23: Float32,
                m30: Float32, m31: Float32, m32: Float32, m33: Float32) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m03 = m03
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m30 = m30
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }
    
    public static let identity = Mat4d(m00: 1, m01: 0, m02: 0, m03: 0,
                                       m10: 0, m11: 1, m12: 0, m13: 0,
                                       m20: 0, m21: 0, m22: 1, m23: 0,
                                       m30: 0, m31: 0, m32: 0, m33: 1)
    
    public static let zero = Mat4d(m00: 0, m01: 0, m02: 0, m03: 0,
                                   m10: 0, m11: 0, m12: 0, m13: 0,
                                   m20: 0, m21: 0, m22: 0, m23: 0,
                                   m30: 0, m31: 0, m32: 0, m33: 0)
    
    // MARK: - Factory Methods
    
    public static func rotX(angle: Float32) -> Mat4d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat4d(m00: 1,  m01: 0,  m02: 0,  m03: 0,
                     m10: 0,  m11: c,  m12: -s, m13: 0,
                     m20: 0,  m21: s,  m22: c,  m23: 0,
                     m30: 0,  m31: 0,  m32: 0,  m33: 1)
    }
    
    public static func rotY(angle: Float32) -> Mat4d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat4d(m00: c,  m01: 0,  m02: s,  m03: 0,
                     m10: 0,  m11: 1,  m12: 0,  m13: 0,
                     m20: -s, m21: 0,  m22: c,  m23: 0,
                     m30: 0,  m31: 0,  m32: 0,  m33: 1)
    }
    
    public static func rotZ(angle: Float32) -> Mat4d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat4d(m00: c,  m01: -s, m02: 0,  m03: 0,
                     m10: s,  m11: c,  m12: 0,  m13: 0,
                     m20: 0,  m21: 0,  m22: 1,  m23: 0,
                     m30: 0,  m31: 0,  m32: 0,  m33: 1)
    }

    public static func fromEulerAngles(rx: Float32, ry: Float32, rz: Float32) -> Mat4d {
        return rotZ(angle: rz) * rotY(angle: ry) * rotX(angle: rx)
    }

    public static func scale(sx: Float32, sy: Float32, sz: Float32, sw: Float32 = 1) -> Mat4d {
        return Mat4d(m00: sx, m01: 0,  m02: 0,  m03: 0,
                     m10: 0,  m11: sy, m12: 0,  m13: 0,
                     m20: 0,  m21: 0,  m22: sz, m23: 0,
                     m30: 0,  m31: 0,  m32: 0,  m33: sw)
    }
    
    public static func scale(_ s: Float32) -> Mat4d {
        return scale(sx: s, sy: s, sz: s)
    }
    
    public static func translate(vec: Vec2d) -> Mat4d {
        return Mat4d(
            m00: 1,  m01: 0,  m02: 0,  m03: vec.x,
            m10: 0,  m11: 1,  m12: 0,  m13: vec.y,
            m20: 0,  m21: 0,  m22: 1,  m23: 0,
            m30: 0,  m31: 0,  m32: 0,  m33: 1)
    }
    
    public static func translate(vec: Vec3d) -> Mat4d {
        return Mat4d(
            m00: 1,  m01: 0,  m02: 0,  m03: vec.x,
            m10: 0,  m11: 1,  m12: 0,  m13: vec.y,
            m20: 0,  m21: 0,  m22: 1,  m23: vec.z,
            m30: 0,  m31: 0,  m32: 0,  m33: 1)
    }
    
    public static func translate(x: Float32, y: Float32, z: Float32) -> Mat4d {
        return translate(vec: Vec3d(x, y, z))
    }
    
    /// Create a perspective projection matrix
    public static func perspective(fovY: Float32, aspect: Float32, near: Float32, far: Float32) -> Mat4d {
        let tanHalfFovy = tan(fovY / 2)
        let f = 1 / tanHalfFovy
        let nf = 1 / (near - far)
        
        return Mat4d(
            m00: f / aspect, m01: 0,  m02: 0,                      m03: 0,
            m10: 0,          m11: f,  m12: 0,                      m13: 0,
            m20: 0,          m21: 0,  m22: (far + near) * nf,      m23: 2 * far * near * nf,
            m30: 0,          m31: 0,  m32: -1,                     m33: 0
        )
    }
    
    /// Create an orthographic projection matrix
    public static func orthographic(left: Float32, right: Float32, bottom: Float32, top: Float32, near: Float32, far: Float32) -> Mat4d {
        let rl = 1 / (right - left)
        let tb = 1 / (top - bottom)
        let fn = 1 / (far - near)
        
        return Mat4d(
            m00: 2 * rl,            m01: 0,                  m02: 0,                 m03: -(right + left) * rl,
            m10: 0,                 m11: 2 * tb,             m12: 0,                 m13: -(top + bottom) * tb,
            m20: 0,                 m21: 0,                  m22: -2 * fn,           m23: -(far + near) * fn,
            m30: 0,                 m31: 0,                  m32: 0,                 m33: 1
        )
    }
    
    /// Create a look-at view matrix
    public static func lookAt(eye: Vec3d, target: Vec3d, up: Vec3d) -> Mat4d {
        let f = (target - eye).normalized
        let s = f.cross(up).normalized
        let u = s.cross(f)
        
        return Mat4d(
            m00: s.x,  m01: s.y,  m02: s.z,  m03: -s.dot(eye),
            m10: u.x,  m11: u.y,  m12: u.z,  m13: -u.dot(eye),
            m20: -f.x, m21: -f.y, m22: -f.z, m23: f.dot(eye),
            m30: 0,    m31: 0,    m32: 0,    m33: 1
        )
    }
    
    // MARK: - Matrix Operations
    
    /// Matrix multiplication
    public static func * (lhs: Mat4d, rhs: Mat4d) -> Mat4d {
        Mat4d(
            m00: lhs.m00 * rhs.m00 + lhs.m01 * rhs.m10 + lhs.m02 * rhs.m20 + lhs.m03 * rhs.m30,
            m01: lhs.m00 * rhs.m01 + lhs.m01 * rhs.m11 + lhs.m02 * rhs.m21 + lhs.m03 * rhs.m31,
            m02: lhs.m00 * rhs.m02 + lhs.m01 * rhs.m12 + lhs.m02 * rhs.m22 + lhs.m03 * rhs.m32,
            m03: lhs.m00 * rhs.m03 + lhs.m01 * rhs.m13 + lhs.m02 * rhs.m23 + lhs.m03 * rhs.m33,
            m10: lhs.m10 * rhs.m00 + lhs.m11 * rhs.m10 + lhs.m12 * rhs.m20 + lhs.m13 * rhs.m30,
            m11: lhs.m10 * rhs.m01 + lhs.m11 * rhs.m11 + lhs.m12 * rhs.m21 + lhs.m13 * rhs.m31,
            m12: lhs.m10 * rhs.m02 + lhs.m11 * rhs.m12 + lhs.m12 * rhs.m22 + lhs.m13 * rhs.m32,
            m13: lhs.m10 * rhs.m03 + lhs.m11 * rhs.m13 + lhs.m12 * rhs.m23 + lhs.m13 * rhs.m33,
            m20: lhs.m20 * rhs.m00 + lhs.m21 * rhs.m10 + lhs.m22 * rhs.m20 + lhs.m23 * rhs.m30,
            m21: lhs.m20 * rhs.m01 + lhs.m21 * rhs.m11 + lhs.m22 * rhs.m21 + lhs.m23 * rhs.m31,
            m22: lhs.m20 * rhs.m02 + lhs.m21 * rhs.m12 + lhs.m22 * rhs.m22 + lhs.m23 * rhs.m32,
            m23: lhs.m20 * rhs.m03 + lhs.m21 * rhs.m13 + lhs.m22 * rhs.m23 + lhs.m23 * rhs.m33,
            m30: lhs.m30 * rhs.m00 + lhs.m31 * rhs.m10 + lhs.m32 * rhs.m20 + lhs.m33 * rhs.m30,
            m31: lhs.m30 * rhs.m01 + lhs.m31 * rhs.m11 + lhs.m32 * rhs.m21 + lhs.m33 * rhs.m31,
            m32: lhs.m30 * rhs.m02 + lhs.m31 * rhs.m12 + lhs.m32 * rhs.m22 + lhs.m33 * rhs.m32,
            m33: lhs.m30 * rhs.m03 + lhs.m31 * rhs.m13 + lhs.m32 * rhs.m23 + lhs.m33 * rhs.m33
        )
    }
    
    /// Matrix-vector multiplication
    public static func * (lhs: Mat4d, rhs: Vec4d) -> Vec4d {
        Vec4d(
            lhs.m00 * rhs.x + lhs.m01 * rhs.y + lhs.m02 * rhs.z + lhs.m03 * rhs.w,
            lhs.m10 * rhs.x + lhs.m11 * rhs.y + lhs.m12 * rhs.z + lhs.m13 * rhs.w,
            lhs.m20 * rhs.x + lhs.m21 * rhs.y + lhs.m22 * rhs.z + lhs.m23 * rhs.w,
            lhs.m30 * rhs.x + lhs.m31 * rhs.y + lhs.m32 * rhs.z + lhs.m33 * rhs.w
        )
    }
    
    /// Transform a 3D point (assumes w=1)
    public func transformPoint(_ v: Vec3d) -> Vec3d {
        let w = m30 * v.x + m31 * v.y + m32 * v.z + m33
        return Vec3d(
            (m00 * v.x + m01 * v.y + m02 * v.z + m03) / w,
            (m10 * v.x + m11 * v.y + m12 * v.z + m13) / w,
            (m20 * v.x + m21 * v.y + m22 * v.z + m23) / w
        )
    }
    
    /// Transform a 3D direction (ignores translation, assumes w=0)
    public func transformDirection(_ v: Vec3d) -> Vec3d {
        Vec3d(
            m00 * v.x + m01 * v.y + m02 * v.z,
            m10 * v.x + m11 * v.y + m12 * v.z,
            m20 * v.x + m21 * v.y + m22 * v.z
        )
    }
    
    /// Scalar multiplication
    public static func * (lhs: Mat4d, rhs: Float32) -> Mat4d {
        Mat4d(
            m00: lhs.m00 * rhs, m01: lhs.m01 * rhs, m02: lhs.m02 * rhs, m03: lhs.m03 * rhs,
            m10: lhs.m10 * rhs, m11: lhs.m11 * rhs, m12: lhs.m12 * rhs, m13: lhs.m13 * rhs,
            m20: lhs.m20 * rhs, m21: lhs.m21 * rhs, m22: lhs.m22 * rhs, m23: lhs.m23 * rhs,
            m30: lhs.m30 * rhs, m31: lhs.m31 * rhs, m32: lhs.m32 * rhs, m33: lhs.m33 * rhs
        )
    }
    
    public static func * (lhs: Float32, rhs: Mat4d) -> Mat4d {
        rhs * lhs
    }
    
    /// Matrix addition
    public static func + (lhs: Mat4d, rhs: Mat4d) -> Mat4d {
        Mat4d(
            m00: lhs.m00 + rhs.m00, m01: lhs.m01 + rhs.m01, m02: lhs.m02 + rhs.m02, m03: lhs.m03 + rhs.m03,
            m10: lhs.m10 + rhs.m10, m11: lhs.m11 + rhs.m11, m12: lhs.m12 + rhs.m12, m13: lhs.m13 + rhs.m13,
            m20: lhs.m20 + rhs.m20, m21: lhs.m21 + rhs.m21, m22: lhs.m22 + rhs.m22, m23: lhs.m23 + rhs.m23,
            m30: lhs.m30 + rhs.m30, m31: lhs.m31 + rhs.m31, m32: lhs.m32 + rhs.m32, m33: lhs.m33 + rhs.m33
        )
    }
    
    /// Matrix subtraction
    public static func - (lhs: Mat4d, rhs: Mat4d) -> Mat4d {
        Mat4d(
            m00: lhs.m00 - rhs.m00, m01: lhs.m01 - rhs.m01, m02: lhs.m02 - rhs.m02, m03: lhs.m03 - rhs.m03,
            m10: lhs.m10 - rhs.m10, m11: lhs.m11 - rhs.m11, m12: lhs.m12 - rhs.m12, m13: lhs.m13 - rhs.m13,
            m20: lhs.m20 - rhs.m20, m21: lhs.m21 - rhs.m21, m22: lhs.m22 - rhs.m22, m23: lhs.m23 - rhs.m23,
            m30: lhs.m30 - rhs.m30, m31: lhs.m31 - rhs.m31, m32: lhs.m32 - rhs.m32, m33: lhs.m33 - rhs.m33
        )
    }
    
    // MARK: - Properties
    
    /// Transpose of the matrix
    public var transposed: Mat4d {
        Mat4d(
            m00: m00, m01: m10, m02: m20, m03: m30,
            m10: m01, m11: m11, m12: m21, m13: m31,
            m20: m02, m21: m12, m22: m22, m23: m32,
            m30: m03, m31: m13, m32: m23, m33: m33
        )
    }
    
    /// Determinant
    public var determinant: Float32 {
        let a = m00, b = m01, c = m02, d = m03
        let e = m10, f = m11, g = m12, h = m13
        let i = m20, j = m21, k = m22, l = m23
        let m = m30, n = m31, o = m32, p = m33
        
        let kp_lo = k * p - l * o
        let jp_ln = j * p - l * n
        let jo_kn = j * o - k * n
        let ip_lm = i * p - l * m
        let io_km = i * o - k * m
        let in_jm = i * n - j * m
        
        return a * (f * kp_lo - g * jp_ln + h * jo_kn) -
               b * (e * kp_lo - g * ip_lm + h * io_km) +
               c * (e * jp_ln - f * ip_lm + h * in_jm) -
               d * (e * jo_kn - f * io_km + g * in_jm)
    }
    
    /// Inverse (returns nil if matrix is singular)
    public var inverse: Mat4d? {
        let det = determinant
        guard abs(det) > Float32.ulpOfOne else { return nil }
        
        let a = m00, b = m01, c = m02, d = m03
        let e = m10, f = m11, g = m12, h = m13
        let i = m20, j = m21, k = m22, l = m23
        let m = m30, n = m31, o = m32, p = m33
        
        let invDet = 1 / det
        
        return Mat4d(
            m00: (f * (k * p - l * o) - g * (j * p - l * n) + h * (j * o - k * n)) * invDet,
            m01: -(b * (k * p - l * o) - c * (j * p - l * n) + d * (j * o - k * n)) * invDet,
            m02: (b * (g * p - h * o) - c * (f * p - h * n) + d * (f * o - g * n)) * invDet,
            m03: -(b * (g * l - h * k) - c * (f * l - h * j) + d * (f * k - g * j)) * invDet,
            m10: -(e * (k * p - l * o) - g * (i * p - l * m) + h * (i * o - k * m)) * invDet,
            m11: (a * (k * p - l * o) - c * (i * p - l * m) + d * (i * o - k * m)) * invDet,
            m12: -(a * (g * p - h * o) - c * (e * p - h * m) + d * (e * o - g * m)) * invDet,
            m13: (a * (g * l - h * k) - c * (e * l - h * i) + d * (e * k - g * i)) * invDet,
            m20: (e * (j * p - l * n) - f * (i * p - l * m) + h * (i * n - j * m)) * invDet,
            m21: -(a * (j * p - l * n) - b * (i * p - l * m) + d * (i * n - j * m)) * invDet,
            m22: (a * (f * p - h * n) - b * (e * p - h * m) + d * (e * n - f * m)) * invDet,
            m23: -(a * (f * l - h * j) - b * (e * l - h * i) + d * (e * j - f * i)) * invDet,
            m30: -(e * (j * o - k * n) - f * (i * o - k * m) + g * (i * n - j * m)) * invDet,
            m31: (a * (j * o - k * n) - b * (i * o - k * m) + c * (i * n - j * m)) * invDet,
            m32: -(a * (f * o - g * n) - b * (e * o - g * m) + c * (e * n - f * m)) * invDet,
            m33: (a * (f * k - g * j) - b * (e * k - g * i) + c * (e * j - f * i)) * invDet
        )
    }
    
    /// Extract the upper-left 3x3 rotation/scale matrix
    public var mat3: Mat3d {
        Mat3d(
            m00: m00, m01: m01, m02: m02,
            m10: m10, m11: m11, m12: m12,
            m20: m20, m21: m21, m22: m22
        )
    }
}

extension Mat4d: CustomStringConvertible {
    public var description: String {
        """
        [\(m00), \(m01), \(m02), \(m03)]
        [\(m10), \(m11), \(m12), \(m13)]
        [\(m20), \(m21), \(m22), \(m23)]
        [\(m30), \(m31), \(m32), \(m33)]
        """
    }
}