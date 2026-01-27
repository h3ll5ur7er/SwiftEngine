import Foundation

/// Component that renders a mesh
@MainActor
public final class MeshRenderer: Component {
    /// The mesh to render
    public var mesh: (any Mesh)?
    
    /// The material used for rendering
    public var material: Material = Material.default
    
    /// The color/tint to apply to the mesh (convenience accessor for material.color)
    public var color: Color {
        get { material.color }
        set { material.color = newValue }
    }
    
    /// Multiple materials for sub-meshes (optional)
    public var materials: [Material] = []
    
    /// Whether this renderer casts shadows
    public var castShadows: Bool = true
    
    /// Whether this renderer receives shadows
    public var receiveShadows: Bool = true
    
    /// Render order within the same layer (lower values render first)
    public var sortingOrder: Int = 0
    
    /// Whether the mesh is visible
    public var isVisible: Bool = true
    
    // MARK: - Initialization
    
    public required init() {
        super.init()
        self.material = Material(color: .white)
    }
    
    public convenience init(mesh: any Mesh) {
        self.init()
        self.mesh = mesh
    }
    
    public convenience init(mesh: any Mesh, color: Color) {
        self.init()
        self.mesh = mesh
        self.material = Material(color: color)
    }
    
    public convenience init(mesh: any Mesh, material: Material) {
        self.init()
        self.mesh = mesh
        self.material = material
    }
    
    // MARK: - Bounds
    
    /// Get the world-space bounds of the mesh
    public var worldBounds: Bounds? {
        guard let mesh = mesh else { return nil }
        
        let localBounds = mesh.bounds
        let worldMatrix = transform.worldMatrix
        
        // Transform the 8 corners of the bounding box
        let corners = [
            Vec3d(localBounds.min.x, localBounds.min.y, localBounds.min.z),
            Vec3d(localBounds.max.x, localBounds.min.y, localBounds.min.z),
            Vec3d(localBounds.min.x, localBounds.max.y, localBounds.min.z),
            Vec3d(localBounds.max.x, localBounds.max.y, localBounds.min.z),
            Vec3d(localBounds.min.x, localBounds.min.y, localBounds.max.z),
            Vec3d(localBounds.max.x, localBounds.min.y, localBounds.max.z),
            Vec3d(localBounds.min.x, localBounds.max.y, localBounds.max.z),
            Vec3d(localBounds.max.x, localBounds.max.y, localBounds.max.z),
        ]
        
        var minPoint = worldMatrix.transformPoint(corners[0])
        var maxPoint = minPoint
        
        for i in 1..<8 {
            let transformed = worldMatrix.transformPoint(corners[i])
            minPoint = Vec3d(
                Swift.min(minPoint.x, transformed.x),
                Swift.min(minPoint.y, transformed.y),
                Swift.min(minPoint.z, transformed.z)
            )
            maxPoint = Vec3d(
                Swift.max(maxPoint.x, transformed.x),
                Swift.max(maxPoint.y, transformed.y),
                Swift.max(maxPoint.z, transformed.z)
            )
        }
        
        return Bounds.fromMinMax(min: minPoint, max: maxPoint)
    }
    
    // MARK: - Rendering
    
    /// Get transformed vertices in world space
    public func getWorldVertices() -> [Vertex] {
        guard let mesh = mesh else { return [] }
        
        let worldMatrix = transform.worldMatrix
        let normalMatrix = transform.worldMatrix.inverse?.transposed ?? .identity
        
        return mesh.vertices.map { vertex in
            Vertex(
                position: worldMatrix.transformPoint(vertex.position),
                normal: normalMatrix.transformDirection(vertex.normal).normalized,
                uv: vertex.uv
            )
        }
    }
    
    /// Get transformed vertices projected to screen space using the given camera
    public func getProjectedVertices(camera: Camera) -> [(position: Vec3d, screenPos: Vec2d, vertex: Vertex)] {
        guard let mesh = mesh else { return [] }
        
        let worldMatrix = transform.worldMatrix
        let normalMatrix = transform.worldMatrix.inverse?.transposed ?? .identity
        let viewProj = camera.viewProjectionMatrix
        
        return mesh.vertices.map { vertex in
            let worldPos = worldMatrix.transformPoint(vertex.position)
            let worldNormal = normalMatrix.transformDirection(vertex.normal).normalized
            let clipPos = viewProj.transformPoint(worldPos)
            
            // Perspective divide
            let ndcX = clipPos.x
            let ndcY = clipPos.y
            
            // Convert to screen coordinates (0-1)
            let screenX = (ndcX + 1.0) / 2.0
            let screenY = (ndcY + 1.0) / 2.0
            
            let transformedVertex = Vertex(position: worldPos, normal: worldNormal, uv: vertex.uv)
            return (clipPos, Vec2d(screenX, screenY), transformedVertex)
        }
    }
}
