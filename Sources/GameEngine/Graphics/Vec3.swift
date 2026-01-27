import Foundation

/// 3D vectors
public struct Vec3: Equatable, Hashable, Sendable {
    public var x: Int32
    public var y: Int32
    public var z: Int32
    public init(x: Int32, y: Int32, z: Int32) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(_ x: Int32, _ y: Int32, _ z: Int32) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Vec3(0, 0, 0)
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec3, rhs: Vec3) -> Vec3 {
        Vec3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    public static func - (lhs: Vec3, rhs: Vec3) -> Vec3 {
        Vec3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    public static func * (lhs: Vec3, rhs: Int32) -> Vec3 {
        Vec3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    public static func * (lhs: Int32, rhs: Vec3) -> Vec3 {
        Vec3(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }
    
    public static func / (lhs: Vec3, rhs: Int32) -> Vec3 {
        Vec3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    public static prefix func - (v: Vec3) -> Vec3 {
        Vec3(-v.x, -v.y, -v.z)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec3, rhs: Vec3) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec3, rhs: Vec3) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec3, rhs: Int32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec3) -> Int32 {
        x * other.x + y * other.y + z * other.z
    }
    
    /// Cross product
    public func cross(_ other: Vec3) -> Vec3 {
        Vec3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Int32 {
        x * x + y * y + z * z
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec3) -> Int32 {
        abs(x - other.x) + abs(y - other.y) + abs(z - other.z)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec3) -> Int32 {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return dx * dx + dy * dy + dz * dz
    }
}
extension Vec3: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y), \(z))"
    }
}
public struct Vec3d: Equatable, Hashable, Sendable {
    public var x: Float32
    public var y: Float32
    public var z: Float32
    
    public init(x: Float32, y: Float32, z: Float32) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(_ x: Float32, _ y: Float32, _ z: Float32) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Vec3d(0, 0, 0)
    public static let one = Vec3d(1, 1, 1)
    public static let unitX = Vec3d(1, 0, 0)
    public static let unitY = Vec3d(0, 1, 0)
    public static let unitZ = Vec3d(0, 0, 1)
    
    // Direction aliases
    public static let right = unitX
    public static let up = unitY
    public static let forward = Vec3d(0, 0, -1) // -Z is forward in right-handed coordinates
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec3d, rhs: Vec3d) -> Vec3d {
        Vec3d(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    public static func - (lhs: Vec3d, rhs: Vec3d) -> Vec3d {
        Vec3d(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    public static func * (lhs: Vec3d, rhs: Float32) -> Vec3d {
        Vec3d(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    public static func * (lhs: Float32, rhs: Vec3d) -> Vec3d {
        Vec3d(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }
    
    public static func / (lhs: Vec3d, rhs: Float32) -> Vec3d {
        Vec3d(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    public static prefix func - (v: Vec3d) -> Vec3d {
        Vec3d(-v.x, -v.y, -v.z)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec3d, rhs: Vec3d) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec3d, rhs: Vec3d) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec3d, rhs: Float32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec3d) -> Float32 {
        x * other.x + y * other.y + z * other.z
    }
    
    /// Cross product
    public func cross(_ other: Vec3d) -> Vec3d {
        Vec3d(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Float32 {
        x * x + y * y + z * z
    }
    
    /// Length/magnitude
    public var length: Float32 {
        sqrt(squaredLength)
    }
    
    /// Returns normalized vector (unit length)
    public var normalized: Vec3d {
        let len = length
        guard len > 0 else { return .zero }
        return self / len
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec3d) -> Float32 {
        abs(x - other.x) + abs(y - other.y) + abs(z - other.z)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec3d) -> Float32 {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return dx * dx + dy * dy + dz * dz
    }
    
    /// Distance to another vector
    public func distance(to other: Vec3d) -> Float32 {
        sqrt(squaredDistance(to: other))
    }
    
    /// Linear interpolation
    public func lerp(to other: Vec3d, t: Float32) -> Vec3d {
        Vec3d(
            x + (other.x - x) * t,
            y + (other.y - y) * t,
            z + (other.z - z) * t
        )
    }
    
    /// Reflect vector around a normal
    public func reflect(normal: Vec3d) -> Vec3d {
        self - 2 * self.dot(normal) * normal
    }
}

extension Vec3d: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y), \(z))"
    }
}
