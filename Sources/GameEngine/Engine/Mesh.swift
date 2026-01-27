import Foundation

/// A vertex with position, normal, and texture coordinates
public struct Vertex {
    public var position: Vec3d
    public var normal: Vec3d
    public var uv: Vec2d
    
    public init(position: Vec3d, normal: Vec3d = .zero, uv: Vec2d = .zero) {
        self.position = position
        self.normal = normal
        self.uv = uv
    }
}

/// Protocol for meshes that can be rendered
/// Implement this protocol for different mesh formats (FBX, STL, OBJ, etc.)
public protocol Mesh: AnyObject, Sendable {
    /// The vertices of the mesh
    var vertices: [Vertex] { get }
    
    /// Triangle indices (every 3 indices form a triangle)
    var indices: [UInt32] { get }
    
    /// The bounds of the mesh in local space
    var bounds: Bounds { get }
    
    /// Number of triangles in the mesh
    var triangleCount: Int { get }
}

// MARK: - Default Implementations

extension Mesh {
    public var triangleCount: Int {
        indices.count / 3
    }
}

/// Axis-aligned bounding box
public struct Bounds: Sendable {
    public var center: Vec3d
    public var size: Vec3d
    
    public var min: Vec3d {
        Vec3d(
            center.x - size.x / 2,
            center.y - size.y / 2,
            center.z - size.z / 2
        )
    }
    
    public var max: Vec3d {
        Vec3d(
            center.x + size.x / 2,
            center.y + size.y / 2,
            center.z + size.z / 2
        )
    }
    
    public var extents: Vec3d {
        Vec3d(size.x / 2, size.y / 2, size.z / 2)
    }
    
    public init(center: Vec3d = .zero, size: Vec3d = .one) {
        self.center = center
        self.size = size
    }
    
    /// Create bounds from min and max points
    public static func fromMinMax(min: Vec3d, max: Vec3d) -> Bounds {
        let center = Vec3d(
            (min.x + max.x) / 2,
            (min.y + max.y) / 2,
            (min.z + max.z) / 2
        )
        let size = Vec3d(
            max.x - min.x,
            max.y - min.y,
            max.z - min.z
        )
        return Bounds(center: center, size: size)
    }
    
    /// Check if a point is inside the bounds
    public func contains(_ point: Vec3d) -> Bool {
        point.x >= min.x && point.x <= max.x &&
        point.y >= min.y && point.y <= max.y &&
        point.z >= min.z && point.z <= max.z
    }
    
    /// Check if this bounds intersects another bounds
    public func intersects(_ other: Bounds) -> Bool {
        min.x <= other.max.x && max.x >= other.min.x &&
        min.y <= other.max.y && max.y >= other.min.y &&
        min.z <= other.max.z && max.z >= other.min.z
    }
}
