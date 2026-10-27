import Foundation

/// A simple cube mesh centered at origin with size 1x1x1
public final class CubeMesh: Mesh, @unchecked Sendable {
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: Bounds
    
    /// Shared instance of a unit cube
    public static let shared = CubeMesh()
    
    /// Create a cube mesh with the given size
    public init(size: Float = 1.0) {
        let halfSize = size / 2
        
        // Define vertices for each face with proper normals
        // Front face (z+)
        let frontNormal = Vec3d(0, 0, 1)
        let frontVertices = [
            Vertex(position: Vec3d(-halfSize, -halfSize, halfSize), normal: frontNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfSize, -halfSize, halfSize), normal: frontNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfSize, halfSize, halfSize), normal: frontNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfSize, halfSize, halfSize), normal: frontNormal, uv: Vec2d(0, 1)),
        ]
        
        // Back face (z-)
        let backNormal = Vec3d(0, 0, -1)
        let backVertices = [
            Vertex(position: Vec3d(halfSize, -halfSize, -halfSize), normal: backNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(-halfSize, -halfSize, -halfSize), normal: backNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(-halfSize, halfSize, -halfSize), normal: backNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(halfSize, halfSize, -halfSize), normal: backNormal, uv: Vec2d(0, 1)),
        ]
        
        // Top face (y+)
        let topNormal = Vec3d(0, 1, 0)
        let topVertices = [
            Vertex(position: Vec3d(-halfSize, halfSize, halfSize), normal: topNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfSize, halfSize, halfSize), normal: topNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfSize, halfSize, -halfSize), normal: topNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfSize, halfSize, -halfSize), normal: topNormal, uv: Vec2d(0, 1)),
        ]
        
        // Bottom face (y-)
        let bottomNormal = Vec3d(0, -1, 0)
        let bottomVertices = [
            Vertex(position: Vec3d(-halfSize, -halfSize, -halfSize), normal: bottomNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfSize, -halfSize, -halfSize), normal: bottomNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfSize, -halfSize, halfSize), normal: bottomNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfSize, -halfSize, halfSize), normal: bottomNormal, uv: Vec2d(0, 1)),
        ]
        
        // Right face (x+)
        let rightNormal = Vec3d(1, 0, 0)
        let rightVertices = [
            Vertex(position: Vec3d(halfSize, -halfSize, halfSize), normal: rightNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfSize, -halfSize, -halfSize), normal: rightNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfSize, halfSize, -halfSize), normal: rightNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(halfSize, halfSize, halfSize), normal: rightNormal, uv: Vec2d(0, 1)),
        ]
        
        // Left face (x-)
        let leftNormal = Vec3d(-1, 0, 0)
        let leftVertices = [
            Vertex(position: Vec3d(-halfSize, -halfSize, -halfSize), normal: leftNormal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(-halfSize, -halfSize, halfSize), normal: leftNormal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(-halfSize, halfSize, halfSize), normal: leftNormal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfSize, halfSize, -halfSize), normal: leftNormal, uv: Vec2d(0, 1)),
        ]
        
        // Combine all vertices
        self.vertices = frontVertices + backVertices + topVertices + bottomVertices + rightVertices + leftVertices
        
        // Generate indices for each face (two triangles per face)
        var indices: [UInt32] = []
        for face in 0..<6 {
            let base = UInt32(face * 4)
            // First triangle
            indices.append(contentsOf: [base, base + 1, base + 2])
            // Second triangle
            indices.append(contentsOf: [base, base + 2, base + 3])
        }
        self.indices = indices
        
        // Set bounds
        self.bounds = Bounds(center: .zero, size: Vec3d(size, size, size))
    }
}

/// A simple plane mesh on the XZ plane
public final class PlaneMesh: Mesh, @unchecked Sendable {
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: Bounds
    
    /// Shared instance of a unit plane
    public static let shared = PlaneMesh()
    
    /// Create a plane mesh with the given size
    public init(width: Float = 1.0, depth: Float = 1.0) {
        let halfWidth = width / 2
        let halfDepth = depth / 2
        let normal = Vec3d(0, 1, 0)
        
        self.vertices = [
            Vertex(position: Vec3d(-halfWidth, 0, -halfDepth), normal: normal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfWidth, 0, -halfDepth), normal: normal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfWidth, 0, halfDepth), normal: normal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfWidth, 0, halfDepth), normal: normal, uv: Vec2d(0, 1)),
        ]
        
        // Counter-clockwise when seen from above, matching the +Y normal
        self.indices = [
            0, 2, 1,  // First triangle
            0, 3, 2   // Second triangle
        ]
        
        self.bounds = Bounds(center: .zero, size: Vec3d(width, 0, depth))
    }
}

/// A simple quad mesh facing the camera (billboard)
public final class QuadMesh: Mesh, @unchecked Sendable {
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: Bounds
    
    /// Shared instance of a unit quad
    public static let shared = QuadMesh()
    
    /// Create a quad mesh with the given size
    public init(width: Float = 1.0, height: Float = 1.0) {
        let halfWidth = width / 2
        let halfHeight = height / 2
        let normal = Vec3d(0, 0, 1)
        
        self.vertices = [
            Vertex(position: Vec3d(-halfWidth, -halfHeight, 0), normal: normal, uv: Vec2d(0, 0)),
            Vertex(position: Vec3d(halfWidth, -halfHeight, 0), normal: normal, uv: Vec2d(1, 0)),
            Vertex(position: Vec3d(halfWidth, halfHeight, 0), normal: normal, uv: Vec2d(1, 1)),
            Vertex(position: Vec3d(-halfWidth, halfHeight, 0), normal: normal, uv: Vec2d(0, 1)),
        ]
        
        self.indices = [
            0, 1, 2,  // First triangle
            0, 2, 3   // Second triangle
        ]
        
        self.bounds = Bounds(center: .zero, size: Vec3d(width, height, 0))
    }
}
