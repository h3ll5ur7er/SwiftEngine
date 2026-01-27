import Foundation

/// 4D vectors
public struct Vec4: Equatable, Hashable, Sendable {
    public var x: Int32
    public var y: Int32
    public var z: Int32
    public var w: Int32
    public init(x: Int32, y: Int32, z: Int32, w: Int32) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    public init(_ x: Int32, _ y: Int32, _ z: Int32, _ w: Int32) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Vec4(0, 0, 0, 0)
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec4, rhs: Vec4) -> Vec4 {
        Vec4(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }
    
    public static func - (lhs: Vec4, rhs: Vec4) -> Vec4 {
        Vec4(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }
    
    public static func * (lhs: Vec4, rhs: Int32) -> Vec4 {
        Vec4(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }
    
    public static func * (lhs: Int32, rhs: Vec4) -> Vec4 {
        Vec4(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z, lhs * rhs.w)
    }
    
    public static func / (lhs: Vec4, rhs: Int32) -> Vec4 {
        Vec4(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs)
    }
    
    public static prefix func - (v: Vec4) -> Vec4 {
        Vec4(-v.x, -v.y, -v.z, -v.w)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec4, rhs: Vec4) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec4, rhs: Vec4) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec4, rhs: Int32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec4) -> Int32 {
        x * other.x + y * other.y + z * other.z + w * other.w
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Int32 {
        x * x + y * y + z * z + w * w
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec4) -> Int32 {
        abs(x - other.x) + abs(y - other.y) + abs(z - other.z) + abs(w - other.w)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec4) -> Int32 {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        let dw = w - other.w
        return dx * dx + dy * dy + dz * dz + dw * dw
    }
}
extension Vec4: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y), \(z), \(w))"
    }
}
public struct Vec4d: Equatable, Hashable, Sendable {
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
    
    public static let zero = Vec4d(0, 0, 0, 0)
    public static let one = Vec4d(1, 1, 1, 1)
    public static let unitX = Vec4d(1, 0, 0, 0)
    public static let unitY = Vec4d(0, 1, 0, 0)
    public static let unitZ = Vec4d(0, 0, 1, 0)
    public static let unitW = Vec4d(0, 0, 0, 1)
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec4d, rhs: Vec4d) -> Vec4d {
        Vec4d(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }
    
    public static func - (lhs: Vec4d, rhs: Vec4d) -> Vec4d {
        Vec4d(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }
    
    public static func * (lhs: Vec4d, rhs: Float32) -> Vec4d {
        Vec4d(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }
    
    public static func * (lhs: Float32, rhs: Vec4d) -> Vec4d {
        Vec4d(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z, lhs * rhs.w)
    }
    
    public static func / (lhs: Vec4d, rhs: Float32) -> Vec4d {
        Vec4d(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs)
    }
    
    public static prefix func - (v: Vec4d) -> Vec4d {
        Vec4d(-v.x, -v.y, -v.z, -v.w)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec4d, rhs: Vec4d) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec4d, rhs: Vec4d) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec4d, rhs: Float32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec4d) -> Float32 {
        x * other.x + y * other.y + z * other.z + w * other.w
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Float32 {
        x * x + y * y + z * z + w * w
    }
    
    /// Length/magnitude
    public var length: Float32 {
        sqrt(squaredLength)
    }
    
    /// Returns normalized vector (unit length)
    public var normalized: Vec4d {
        let len = length
        guard len > 0 else { return .zero }
        return self / len
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec4d) -> Float32 {
        abs(x - other.x) + abs(y - other.y) + abs(z - other.z) + abs(w - other.w)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec4d) -> Float32 {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        let dw = w - other.w
        return dx * dx + dy * dy + dz * dz + dw * dw
    }
    
    /// Distance to another vector
    public func distance(to other: Vec4d) -> Float32 {
        sqrt(squaredDistance(to: other))
    }
    
    /// Linear interpolation
    public func lerp(to other: Vec4d, t: Float32) -> Vec4d {
        Vec4d(
            x + (other.x - x) * t,
            y + (other.y - y) * t,
            z + (other.z - z) * t,
            w + (other.w - w) * t
        )
    }
    
    /// Convert to Vec3d by discarding w
    public var xyz: Vec3d {
        Vec3d(x, y, z)
    }
}

extension Vec4d: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y), \(z), \(w))"
    }
}
