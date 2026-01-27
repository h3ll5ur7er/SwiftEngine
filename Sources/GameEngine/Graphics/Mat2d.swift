import Foundation

public struct Mat2d: Equatable, Hashable, Sendable {
    public var m00: Float32, m01: Float32
    public var m10: Float32, m11: Float32
    
    public init(m00: Float32, m01: Float32,
                m10: Float32, m11: Float32) {
        self.m00 = m00
        self.m01 = m01
        self.m10 = m10
        self.m11 = m11
    }
    
    public static let identity = Mat2d(m00: 1, m01: 0,
                                       m10: 0, m11: 1)
    
    public static let zero = Mat2d(m00: 0, m01: 0,
                                   m10: 0, m11: 0)
    
    // MARK: - Factory Methods
    
    public static func rotation(angle: Float32) -> Mat2d {
        let c = cos(angle)
        let s = sin(angle)
        return Mat2d(m00: c,  m01: -s,
                     m10: s,  m11: c)
    }
    
    public static func scale(sx: Float32, sy: Float32) -> Mat2d {
        return Mat2d(m00: sx, m01: 0,
                     m10: 0,  m11: sy)
    }
    
    public static func scale(_ s: Float32) -> Mat2d {
        return scale(sx: s, sy: s)
    }
    
    // MARK: - Matrix Operations
    
    /// Matrix multiplication
    public static func * (lhs: Mat2d, rhs: Mat2d) -> Mat2d {
        Mat2d(
            m00: lhs.m00 * rhs.m00 + lhs.m01 * rhs.m10,
            m01: lhs.m00 * rhs.m01 + lhs.m01 * rhs.m11,
            m10: lhs.m10 * rhs.m00 + lhs.m11 * rhs.m10,
            m11: lhs.m10 * rhs.m01 + lhs.m11 * rhs.m11
        )
    }
    
    /// Matrix-vector multiplication
    public static func * (lhs: Mat2d, rhs: Vec2d) -> Vec2d {
        Vec2d(
            lhs.m00 * rhs.x + lhs.m01 * rhs.y,
            lhs.m10 * rhs.x + lhs.m11 * rhs.y
        )
    }
    
    /// Scalar multiplication
    public static func * (lhs: Mat2d, rhs: Float32) -> Mat2d {
        Mat2d(
            m00: lhs.m00 * rhs, m01: lhs.m01 * rhs,
            m10: lhs.m10 * rhs, m11: lhs.m11 * rhs
        )
    }
    
    public static func * (lhs: Float32, rhs: Mat2d) -> Mat2d {
        rhs * lhs
    }
    
    /// Matrix addition
    public static func + (lhs: Mat2d, rhs: Mat2d) -> Mat2d {
        Mat2d(
            m00: lhs.m00 + rhs.m00, m01: lhs.m01 + rhs.m01,
            m10: lhs.m10 + rhs.m10, m11: lhs.m11 + rhs.m11
        )
    }
    
    /// Matrix subtraction
    public static func - (lhs: Mat2d, rhs: Mat2d) -> Mat2d {
        Mat2d(
            m00: lhs.m00 - rhs.m00, m01: lhs.m01 - rhs.m01,
            m10: lhs.m10 - rhs.m10, m11: lhs.m11 - rhs.m11
        )
    }
    
    // MARK: - Properties
    
    /// Transpose of the matrix
    public var transposed: Mat2d {
        Mat2d(m00: m00, m01: m10,
              m10: m01, m11: m11)
    }
    
    /// Determinant
    public var determinant: Float32 {
        m00 * m11 - m01 * m10
    }
    
    /// Inverse (returns nil if matrix is singular)
    public var inverse: Mat2d? {
        let det = determinant
        guard abs(det) > Float32.ulpOfOne else { return nil }
        let invDet = 1.0 / det
        return Mat2d(
            m00: m11 * invDet, m01: -m01 * invDet,
            m10: -m10 * invDet, m11: m00 * invDet
        )
    }
}

extension Mat2d: CustomStringConvertible {
    public var description: String {
        """
        [\(m00), \(m01)]
        [\(m10), \(m11)]
        """
    }
}