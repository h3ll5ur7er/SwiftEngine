import Foundation

/// Data for a single triangle ready to be rasterized
public struct RenderTriangle {
    /// Average depth for sorting (in NDC space, -1 to 1)
    public let depth: Float
    
    /// Screen-space vertices
    public let vertices: [Vec2]
    
    /// Final shaded color
    public let color: Color
    
    public init(depth: Float, vertices: [Vec2], color: Color) {
        self.depth = depth
        self.vertices = vertices
        self.color = color
    }
}

/// Handles the rendering pipeline for 3D scenes
/// Transforms, culls, lights, and rasterizes meshes
@MainActor
public final class RenderPipeline {
    
    /// Singleton instance
    public static let shared = RenderPipeline()
    
    private init() {}
    
    /// Render all mesh renderers visible to the camera
    public func render(
        meshRenderers: [MeshRenderer],
        camera: Camera,
        context: RenderContext
    ) {
        let viewProj = camera.viewProjectionMatrix
        let frustum = camera.frustum
        let screenWidth = Float(context.width)
        let screenHeight = Float(context.height)
        
        // Get lighting
        let ambientIntensity = AmbientLight.effectiveIntensity
        let ambientColor = AmbientLight.effectiveColor
        let directionalLights = DirectionalLight.all
        
        // Collect triangles for depth sorting
        var trianglesToRender: [RenderTriangle] = []
        
        for renderer in meshRenderers where renderer.isVisible && renderer.isEnabled {
            guard let mesh = renderer.mesh else { continue }
            
            // Early frustum culling using world bounds
            if let worldBounds = renderer.worldBounds {
                if !frustum.intersectsBounds(worldBounds) {
                    continue
                }
            }
            
            let worldMatrix = renderer.transform.worldMatrix
            let normalMatrix = worldMatrix.inverse?.transposed ?? .identity
            let mvp = viewProj * worldMatrix
            let material = renderer.material
            let baseColor = material.color
            
            // Transform vertices to clip space
            var clipVertices: [Vec4d] = []
            var worldVertices: [Vec3d] = []
            var worldNormals: [Vec3d] = []
            
            for vertex in mesh.vertices {
                let worldPos = worldMatrix.transformPoint(vertex.position)
                worldVertices.append(worldPos)
                
                let worldNormal = normalMatrix.transformDirection(vertex.normal).normalized
                worldNormals.append(worldNormal)
                
                let clip = Vec4d(
                    mvp.m00 * vertex.position.x + mvp.m01 * vertex.position.y + mvp.m02 * vertex.position.z + mvp.m03,
                    mvp.m10 * vertex.position.x + mvp.m11 * vertex.position.y + mvp.m12 * vertex.position.z + mvp.m13,
                    mvp.m20 * vertex.position.x + mvp.m21 * vertex.position.y + mvp.m22 * vertex.position.z + mvp.m23,
                    mvp.m30 * vertex.position.x + mvp.m31 * vertex.position.y + mvp.m32 * vertex.position.z + mvp.m33
                )
                clipVertices.append(clip)
            }
            
            let indices = mesh.indices
            
            // Process triangles
            for i in stride(from: 0, to: indices.count, by: 3) {
                if let triangle = processTriangle(
                    indices: [Int(indices[i]), Int(indices[i + 1]), Int(indices[i + 2])],
                    clipVertices: clipVertices,
                    worldVertices: worldVertices,
                    material: material,
                    baseColor: baseColor,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    ambientIntensity: ambientIntensity,
                    ambientColor: ambientColor,
                    directionalLights: directionalLights
                ) {
                    trianglesToRender.append(triangle)
                }
            }
        }
        
        // Sort triangles by depth (back to front for painter's algorithm)
        trianglesToRender.sort { $0.depth > $1.depth }
        
        // Render sorted triangles
        for tri in trianglesToRender {
            Primitives.fillTriangle(tri.vertices[0], tri.vertices[1], tri.vertices[2], color: tri.color)
        }
    }
    
    /// Process a single triangle through the pipeline
    private func processTriangle(
        indices: [Int],
        clipVertices: [Vec4d],
        worldVertices: [Vec3d],
        material: Material,
        baseColor: Color,
        screenWidth: Float,
        screenHeight: Float,
        ambientIntensity: Float,
        ambientColor: Color,
        directionalLights: [DirectionalLight]
    ) -> RenderTriangle? {
        let v0 = clipVertices[indices[0]]
        let v1 = clipVertices[indices[1]]
        let v2 = clipVertices[indices[2]]
        
        // Near plane clipping check - skip if all behind
        let nearW: Float = 0.001
        if v0.w < nearW && v1.w < nearW && v2.w < nearW {
            return nil
        }
        
        // Skip if any vertex is behind near plane (simplified - full clipping would split the triangle)
        if v0.w < nearW || v1.w < nearW || v2.w < nearW {
            return nil
        }
        
        // Perspective divide
        let ndc0 = Vec3d(v0.x / v0.w, v0.y / v0.w, v0.z / v0.w)
        let ndc1 = Vec3d(v1.x / v1.w, v1.y / v1.w, v1.z / v1.w)
        let ndc2 = Vec3d(v2.x / v2.w, v2.y / v2.w, v2.z / v2.w)
        
        // Frustum culling - skip if entirely outside
        if (ndc0.x < -1 && ndc1.x < -1 && ndc2.x < -1) ||
           (ndc0.x > 1 && ndc1.x > 1 && ndc2.x > 1) ||
           (ndc0.y < -1 && ndc1.y < -1 && ndc2.y < -1) ||
           (ndc0.y > 1 && ndc1.y > 1 && ndc2.y > 1) {
            return nil
        }
        
        // Convert to screen coordinates
        let screen0 = Vec2(
            Int32((ndc0.x + 1) * 0.5 * screenWidth),
            Int32((1 - ndc0.y) * 0.5 * screenHeight)
        )
        let screen1 = Vec2(
            Int32((ndc1.x + 1) * 0.5 * screenWidth),
            Int32((1 - ndc1.y) * 0.5 * screenHeight)
        )
        let screen2 = Vec2(
            Int32((ndc2.x + 1) * 0.5 * screenWidth),
            Int32((1 - ndc2.y) * 0.5 * screenHeight)
        )
        
        // Backface culling (in screen space)
        // With Y-down screen coords, front faces (CCW in 3D) have negative cross product
        let edge1x = Float(screen1.x - screen0.x)
        let edge1y = Float(screen1.y - screen0.y)
        let edge2x = Float(screen2.x - screen0.x)
        let edge2y = Float(screen2.y - screen0.y)
        let cross = edge1x * edge2y - edge1y * edge2x
        
        // Cull based on material settings
        if material.cullMode == .back && cross > 0 { return nil }
        if material.cullMode == .front && cross < 0 { return nil }
        
        // Calculate face normal for flat shading
        let worldP0 = worldVertices[indices[0]]
        let worldP1 = worldVertices[indices[1]]
        let worldP2 = worldVertices[indices[2]]
        let faceNormal = (worldP1 - worldP0).cross(worldP2 - worldP0).normalized
        
        // Calculate lighting
        let shadedColor = calculateLighting(
            baseColor: baseColor,
            normal: faceNormal,
            material: material,
            ambientIntensity: ambientIntensity,
            ambientColor: ambientColor,
            directionalLights: directionalLights
        )
        
        // Average depth for sorting
        let avgDepth = (ndc0.z + ndc1.z + ndc2.z) / 3
        
        return RenderTriangle(
            depth: avgDepth,
            vertices: [screen0, screen1, screen2],
            color: shadedColor
        )
    }
    
    /// Calculate the final lit color for a surface
    private func calculateLighting(
        baseColor: Color,
        normal: Vec3d,
        material: Material,
        ambientIntensity: Float,
        ambientColor: Color,
        directionalLights: [DirectionalLight]
    ) -> Color {
        // Unlit materials don't receive lighting
        if material.shadingModel == .unlit {
            return baseColor
        }
        
        // Start with ambient contribution
        var totalR = Float(baseColor.r) * ambientIntensity * Float(ambientColor.r) / 255
        var totalG = Float(baseColor.g) * ambientIntensity * Float(ambientColor.g) / 255
        var totalB = Float(baseColor.b) * ambientIntensity * Float(ambientColor.b) / 255
        
        // Add contribution from each directional light
        for light in directionalLights {
            let nDotL = max(0, normal.dot(light.direction))
            let contribution = nDotL * light.intensity
            
            totalR += Float(baseColor.r) * contribution * Float(light.color.r) / 255
            totalG += Float(baseColor.g) * contribution * Float(light.color.g) / 255
            totalB += Float(baseColor.b) * contribution * Float(light.color.b) / 255
        }
        
        return Color(
            r: UInt8(min(255, totalR)),
            g: UInt8(min(255, totalG)),
            b: UInt8(min(255, totalB)),
            a: baseColor.a
        )
    }
}
