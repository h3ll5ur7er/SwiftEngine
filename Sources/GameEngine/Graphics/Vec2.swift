import Foundation

/// 2D vectors
public struct Vec2: Equatable, Hashable, Sendable {
    public var x: Int32
    public var y: Int32
    
    public init(x: Int32, y: Int32) {
        self.x = x
        self.y = y
    }
    
    public init(_ x: Int32, _ y: Int32) {
        self.x = x
        self.y = y
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Vec2(0, 0)
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    public static func - (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    public static func * (lhs: Vec2, rhs: Int32) -> Vec2 {
        Vec2(lhs.x * rhs, lhs.y * rhs)
    }
    
    public static func * (lhs: Int32, rhs: Vec2) -> Vec2 {
        Vec2(lhs * rhs.x, lhs * rhs.y)
    }
    
    public static func / (lhs: Vec2, rhs: Int32) -> Vec2 {
        Vec2(lhs.x / rhs, lhs.y / rhs)
    }
    
    public static prefix func - (v: Vec2) -> Vec2 {
        Vec2(-v.x, -v.y)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec2, rhs: Vec2) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec2, rhs: Vec2) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec2, rhs: Int32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec2) -> Int32 {
        x * other.x + y * other.y
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Int32 {
        x * x + y * y
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec2) -> Int32 {
        abs(x - other.x) + abs(y - other.y)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec2) -> Int32 {
        let dx = x - other.x
        let dy = y - other.y
        return dx * dx + dy * dy
    }
}

extension Vec2: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}


public struct Vec2d: Equatable, Hashable, Sendable {
    public var x: Float32
    public var y: Float32
    
    public init(x: Float32, y: Float32) {
        self.x = x
        self.y = y
    }
    
    public init(_ x: Float32, _ y: Float32) {
        self.x = x
        self.y = y
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Vec2d(0, 0)
    public static let one = Vec2d(1, 1)
    public static let unitX = Vec2d(1, 0)
    public static let unitY = Vec2d(0, 1)
    
    // MARK: - Arithmetic Operations
    
    public static func + (lhs: Vec2d, rhs: Vec2d) -> Vec2d {
        Vec2d(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    public static func - (lhs: Vec2d, rhs: Vec2d) -> Vec2d {
        Vec2d(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    public static func * (lhs: Vec2d, rhs: Float32) -> Vec2d {
        Vec2d(lhs.x * rhs, lhs.y * rhs)
    }
    
    public static func * (lhs: Float32, rhs: Vec2d) -> Vec2d {
        Vec2d(lhs * rhs.x, lhs * rhs.y)
    }
    
    public static func / (lhs: Vec2d, rhs: Float32) -> Vec2d {
        Vec2d(lhs.x / rhs, lhs.y / rhs)
    }
    
    public static prefix func - (v: Vec2d) -> Vec2d {
        Vec2d(-v.x, -v.y)
    }
    
    // MARK: - Compound Assignment
    
    public static func += (lhs: inout Vec2d, rhs: Vec2d) {
        lhs = lhs + rhs
    }
    
    public static func -= (lhs: inout Vec2d, rhs: Vec2d) {
        lhs = lhs - rhs
    }
    
    public static func *= (lhs: inout Vec2d, rhs: Float32) {
        lhs = lhs * rhs
    }
    
    // MARK: - Utility
    
    /// Dot product
    public func dot(_ other: Vec2d) -> Float32 {
        x * other.x + y * other.y
    }
    
    /// Cross product (returns scalar z-component)
    public func cross(_ other: Vec2d) -> Float32 {
        x * other.y - y * other.x
    }
    
    /// Squared length (avoids sqrt)
    public var squaredLength: Float32 {
        x * x + y * y
    }
    
    /// Length/magnitude
    public var length: Float32 {
        sqrt(squaredLength)
    }
    
    /// Returns normalized vector (unit length)
    public var normalized: Vec2d {
        let len = length
        guard len > 0 else { return .zero }
        return self / len
    }
    
    /// Manhattan distance
    public func manhattanDistance(to other: Vec2d) -> Float32 {
        abs(x - other.x) + abs(y - other.y)
    }
    
    /// Squared distance (avoids sqrt)
    public func squaredDistance(to other: Vec2d) -> Float32 {
        let dx = x - other.x
        let dy = y - other.y
        return dx * dx + dy * dy
    }
    
    /// Distance to another vector
    public func distance(to other: Vec2d) -> Float32 {
        sqrt(squaredDistance(to: other))
    }
    
    /// Linear interpolation
    public func lerp(to other: Vec2d, t: Float32) -> Vec2d {
        Vec2d(x + (other.x - x) * t, y + (other.y - y) * t)
    }
    
    /// Perpendicular vector (rotated 90 degrees counter-clockwise)
    public var perpendicular: Vec2d {
        Vec2d(-y, x)
    }
    
    /// Angle of the vector in radians
    public var angle: Float32 {
        atan2(y, x)
    }
    
    /// Create vector from angle and length
    public static func fromAngle(_ angle: Float32, length: Float32 = 1) -> Vec2d {
        Vec2d(cos(angle) * length, sin(angle) * length)
    }
}

extension Vec2d: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}