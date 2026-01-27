import Foundation

public struct Mat3d: Equatable, Hashable, Sendable {
    public var m00: Float32, m01: Float32, m02: Float32
    public var m10: Float32, m11: Float32, m12: Float32
    public var m20: Float32, m21: Float32, m22: Float32
    
    public init(m00: Float32, m01: Float32, m02: Float32,
                m10: Float32, m11: Float32, m12: Float32,
                m20: Float32, m21: Float32, m22: Float32) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
    }
    
    public static let identity = Mat3d(m00: 1, m01: 0, m02: 0,
                                       m10: 0, m11: 1, m12: 0,
                                       m20: 0, m21: 0, m22: 1)
    
    public static let zero = Mat3d(m00: 0, m01: 0, m02: 0,
                                   m10: 0, m11: 0, m12: 0,
                                   m20: 0, m21: 0, m22: 0)
    
    // MARK: - Factory Methods
    
    public static func rotX(angle: Float32) -> Mat3d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat3d(m00: 1,  m01: 0,  m02: 0,
                     m10: 0,  m11: c,  m12: -s,
                     m20: 0,  m21: s,  m22: c)
    }
    
    public static func rotY(angle: Float32) -> Mat3d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat3d(m00: c,  m01: 0,  m02: s,
                     m10: 0,  m11: 1,  m12: 0,
                     m20: -s, m21: 0,  m22: c)
    }
    
    public static func rotZ(angle: Float32) -> Mat3d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat3d(m00: c,  m01: -s, m02: 0,
                     m10: s,  m11: c,  m12: 0,
                     m20: 0,  m21: 0,  m22: 1)
    }
    
    public static func translate(tx: Float32, ty: Float32) -> Mat3d {
        return Mat3d(m00: 1,  m01: 0,  m02: tx,
                     m10: 0,  m11: 1,  m12: ty,
                     m20: 0,  m21: 0,  m22: 1)
    }

    public static func fromEulerAngles(rx: Float32, ry: Float32, rz: Float32) -> Mat3d {
        return rotZ(angle: rz) * rotY(angle: ry) * rotX(angle: rx)
    }

    public static func scale(sx: Float32, sy: Float32, sz: Float32) -> Mat3d {
        return Mat3d(m00: sx, m01: 0,  m02: 0,
                     m10: 0,  m11: sy, m12: 0,
                     m20: 0,  m21: 0,  m22: sz)
    }
    
    public static func scale(_ s: Float32) -> Mat3d {
        return scale(sx: s, sy: s, sz: s)
    }
    
    // MARK: - Matrix Operations
    
    /// Matrix multiplication
    public static func * (lhs: Mat3d, rhs: Mat3d) -> Mat3d {
        Mat3d(
            m00: lhs.m00 * rhs.m00 + lhs.m01 * rhs.m10 + lhs.m02 * rhs.m20,
            m01: lhs.m00 * rhs.m01 + lhs.m01 * rhs.m11 + lhs.m02 * rhs.m21,
            m02: lhs.m00 * rhs.m02 + lhs.m01 * rhs.m12 + lhs.m02 * rhs.m22,
            m10: lhs.m10 * rhs.m00 + lhs.m11 * rhs.m10 + lhs.m12 * rhs.m20,
            m11: lhs.m10 * rhs.m01 + lhs.m11 * rhs.m11 + lhs.m12 * rhs.m21,
            m12: lhs.m10 * rhs.m02 + lhs.m11 * rhs.m12 + lhs.m12 * rhs.m22,
            m20: lhs.m20 * rhs.m00 + lhs.m21 * rhs.m10 + lhs.m22 * rhs.m20,
            m21: lhs.m20 * rhs.m01 + lhs.m21 * rhs.m11 + lhs.m22 * rhs.m21,
            m22: lhs.m20 * rhs.m02 + lhs.m21 * rhs.m12 + lhs.m22 * rhs.m22
        )
    }
    
    /// Matrix-vector multiplication
    public static func * (lhs: Mat3d, rhs: Vec3d) -> Vec3d {
        Vec3d(
            lhs.m00 * rhs.x + lhs.m01 * rhs.y + lhs.m02 * rhs.z,
            lhs.m10 * rhs.x + lhs.m11 * rhs.y + lhs.m12 * rhs.z,
            lhs.m20 * rhs.x + lhs.m21 * rhs.y + lhs.m22 * rhs.z
        )
    }
    
    /// Scalar multiplication
    public static func * (lhs: Mat3d, rhs: Float32) -> Mat3d {
        Mat3d(
            m00: lhs.m00 * rhs, m01: lhs.m01 * rhs, m02: lhs.m02 * rhs,
            m10: lhs.m10 * rhs, m11: lhs.m11 * rhs, m12: lhs.m12 * rhs,
            m20: lhs.m20 * rhs, m21: lhs.m21 * rhs, m22: lhs.m22 * rhs
        )
    }
    
    public static func * (lhs: Float32, rhs: Mat3d) -> Mat3d {
        rhs * lhs
    }
    
    /// Matrix addition
    public static func + (lhs: Mat3d, rhs: Mat3d) -> Mat3d {
        Mat3d(
            m00: lhs.m00 + rhs.m00, m01: lhs.m01 + rhs.m01, m02: lhs.m02 + rhs.m02,
            m10: lhs.m10 + rhs.m10, m11: lhs.m11 + rhs.m11, m12: lhs.m12 + rhs.m12,
            m20: lhs.m20 + rhs.m20, m21: lhs.m21 + rhs.m21, m22: lhs.m22 + rhs.m22
        )
    }
    
    /// Matrix subtraction
    public static func - (lhs: Mat3d, rhs: Mat3d) -> Mat3d {
        Mat3d(
            m00: lhs.m00 - rhs.m00, m01: lhs.m01 - rhs.m01, m02: lhs.m02 - rhs.m02,
            m10: lhs.m10 - rhs.m10, m11: lhs.m11 - rhs.m11, m12: lhs.m12 - rhs.m12,
            m20: lhs.m20 - rhs.m20, m21: lhs.m21 - rhs.m21, m22: lhs.m22 - rhs.m22
        )
    }
    
    // MARK: - Properties
    
    /// Transpose of the matrix
    public var transposed: Mat3d {
        Mat3d(m00: m00, m01: m10, m02: m20,
              m10: m01, m11: m11, m12: m21,
              m20: m02, m21: m12, m22: m22)
    }
    
    /// Determinant
    public var determinant: Float32 {
        m00 * (m11 * m22 - m12 * m21) -
        m01 * (m10 * m22 - m12 * m20) +
        m02 * (m10 * m21 - m11 * m20)
    }
    
    /// Inverse (returns nil if matrix is singular)
    public var inverse: Mat3d? {
        let det = determinant
        guard abs(det) > Float32.ulpOfOne else { return nil }
        let invDet = 1.0 / det
        
        return Mat3d(
            m00: (m11 * m22 - m21 * m12) * invDet,
            m01: (m02 * m21 - m01 * m22) * invDet,
            m02: (m01 * m12 - m02 * m11) * invDet,
            m10: (m12 * m20 - m10 * m22) * invDet,
            m11: (m00 * m22 - m02 * m20) * invDet,
            m12: (m10 * m02 - m00 * m12) * invDet,
            m20: (m10 * m21 - m20 * m11) * invDet,
            m21: (m20 * m01 - m00 * m21) * invDet,
            m22: (m00 * m11 - m10 * m01) * invDet
        )
    }
}

extension Mat3d: CustomStringConvertible {
    public var description: String {
        """
        [\(m00), \(m01), \(m02)]
        [\(m10), \(m11), \(m12)]
        [\(m20), \(m21), \(m22)]
        """
    }
}