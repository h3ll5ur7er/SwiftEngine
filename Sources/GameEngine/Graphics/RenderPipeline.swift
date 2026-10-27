import Foundation

/// Handles the rendering pipeline for 3D scenes
/// Transforms, clips, lights, and rasterizes meshes into a depth-tested backbuffer
@MainActor
public final class RenderPipeline {

    /// Singleton instance
    public static let shared = RenderPipeline()
    
    /// Per-mesh scratch buffers, reused across meshes and frames to avoid allocations
    private var clipVertices: [Vec4d] = []
    private var worldVertices: [Vec3d] = []
    private var vertexColors: [Vec3d] = []
    
    private init() {}
    
    /// Lighting inputs gathered once per frame
    private struct Lighting {
        let ambientIntensity: Float
        let ambientColor: Color
        let directionalLights: [DirectionalLight]
    }
    
    /// Render all mesh renderers visible to the camera.
    /// Clears the depth buffer first, so each call renders an independent 3D pass.
    public func render(
        meshRenderers: [MeshRenderer],
        camera: Camera,
        context: RenderContext
    ) {
        let renderer = context.renderer
        renderer.clearDepth()
        guard let target = renderer.rasterTarget else { return }
        
        let viewProj = camera.viewProjectionMatrix
        let frustum = camera.frustum
        let screenWidth = Float(context.width)
        let screenHeight = Float(context.height)
        
        let lighting = Lighting(
            ambientIntensity: AmbientLight.effectiveIntensity,
            ambientColor: AmbientLight.effectiveColor,
            directionalLights: DirectionalLight.all
        )
        
        for meshRenderer in meshRenderers where meshRenderer.isVisible && meshRenderer.isEnabled {
            guard let mesh = meshRenderer.mesh else { continue }
            
            // Early frustum culling using world bounds
            if let worldBounds = meshRenderer.worldBounds, !frustum.intersectsBounds(worldBounds) {
                continue
            }
            
            let material = meshRenderer.material
            let smooth = material.shadingModel == .gouraud
            let worldMatrix = meshRenderer.transform.worldMatrix
            let normalMatrix = smooth ? (worldMatrix.inverse?.transposed ?? .identity) : .identity
            let mvp = viewProj * worldMatrix
            
            // Transform vertices to world and clip space (and light them for Gouraud shading)
            clipVertices.removeAll(keepingCapacity: true)
            worldVertices.removeAll(keepingCapacity: true)
            vertexColors.removeAll(keepingCapacity: true)
            
            for vertex in mesh.vertices {
                let p = vertex.position
                worldVertices.append(worldMatrix.transformPoint(p))
                clipVertices.append(Vec4d(
                    mvp.m00 * p.x + mvp.m01 * p.y + mvp.m02 * p.z + mvp.m03,
                    mvp.m10 * p.x + mvp.m11 * p.y + mvp.m12 * p.z + mvp.m13,
                    mvp.m20 * p.x + mvp.m21 * p.y + mvp.m22 * p.z + mvp.m23,
                    mvp.m30 * p.x + mvp.m31 * p.y + mvp.m32 * p.z + mvp.m33
                ))
                if smooth {
                    let worldNormal = normalMatrix.transformDirection(vertex.normal).normalized
                    vertexColors.append(lit(material.color, normal: worldNormal, material: material, lighting: lighting))
                }
            }
            
            let indices = mesh.indices
            var i = 0
            while i + 2 < indices.count {
                drawTriangle(
                    Int(indices[i]), Int(indices[i + 1]), Int(indices[i + 2]),
                    material: material,
                    smooth: smooth,
                    lighting: lighting,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    target: target
                )
                i += 3
            }
        }
    }
    
    /// Clip, cull, shade and rasterize a single triangle
    private func drawTriangle(
        _ i0: Int, _ i1: Int, _ i2: Int,
        material: Material,
        smooth: Bool,
        lighting: Lighting,
        screenWidth: Float,
        screenHeight: Float,
        target: RasterTarget
    ) {
        let c0 = clipVertices[i0]
        let c1 = clipVertices[i1]
        let c2 = clipVertices[i2]
        
        // Trivially reject triangles entirely outside one side of the frustum
        if (c0.x > c0.w && c1.x > c1.w && c2.x > c2.w) ||
           (c0.x < -c0.w && c1.x < -c1.w && c2.x < -c2.w) ||
           (c0.y > c0.w && c1.y > c1.w && c2.y > c2.w) ||
           (c0.y < -c0.w && c1.y < -c1.w && c2.y < -c2.w) {
            return
        }
        
        // Vertex colors: per-vertex for Gouraud, otherwise one color from the face normal
        let color0, color1, color2: Vec3d
        if smooth {
            color0 = vertexColors[i0]
            color1 = vertexColors[i1]
            color2 = vertexColors[i2]
        } else {
            let w0 = worldVertices[i0]
            let faceNormal = (worldVertices[i1] - w0).cross(worldVertices[i2] - w0).normalized
            color0 = lit(material.color, normal: faceNormal, material: material, lighting: lighting)
            color1 = color0
            color2 = color0
        }
        
        @inline(__always)
        func project(_ c: Vec4d, _ color: Vec3d) -> RasterVertex {
            let invW = 1 / c.w
            return RasterVertex(
                x: (c.x * invW + 1) * 0.5 * screenWidth,
                y: (1 - c.y * invW) * 0.5 * screenHeight,
                z: c.z * invW,
                r: color.x, g: color.y, b: color.z
            )
        }
        
        if TriangleClipper.isInsideDepthRange(c0, c1, c2) {
            // Common case: no clipping needed
            rasterize(project(c0, color0), project(c1, color1), project(c2, color2), material: material, smooth: smooth, target: target)
        } else {
            // Crosses the near or far plane: clip, then draw the resulting polygon as a fan
            let polygon = TriangleClipper.clip(
                TriangleClipper.Vertex(position: c0, r: color0.x, g: color0.y, b: color0.z),
                TriangleClipper.Vertex(position: c1, r: color1.x, g: color1.y, b: color1.z),
                TriangleClipper.Vertex(position: c2, r: color2.x, g: color2.y, b: color2.z)
            )
            guard polygon.count >= 3 else { return }
            
            let projected = polygon.map { project($0.position, Vec3d($0.r, $0.g, $0.b)) }
            for k in 1..<(projected.count - 1) {
                rasterize(projected[0], projected[k], projected[k + 1], material: material, smooth: smooth, target: target)
            }
        }
    }
    
    /// Cull by winding, then fill (or outline for wireframe materials)
    private func rasterize(_ v0: RasterVertex, _ v1: RasterVertex, _ v2: RasterVertex, material: Material, smooth: Bool, target: RasterTarget) {
        // Backface culling (in screen space)
        // With Y-down screen coords, front faces (CCW in 3D) have negative cross product
        let cross = (v1.x - v0.x) * (v2.y - v0.y) - (v1.y - v0.y) * (v2.x - v0.x)
        if material.cullMode == .back && cross > 0 { return }
        if material.cullMode == .front && cross < 0 { return }
        
        switch material.renderMode {
        case .wireframe:
            let color = Color(r: clampChannel(v0.r), g: clampChannel(v0.g), b: clampChannel(v0.b))
            let p0 = Vec2(Int32(v0.x), Int32(v0.y))
            let p1 = Vec2(Int32(v1.x), Int32(v1.y))
            let p2 = Vec2(Int32(v2.x), Int32(v2.y))
            Primitives.drawTriangle(p0, p1, p2, color: color)
        case .opaque, .transparent, .cutout:
            if smooth {
                TriangleRasterizer.fillSmooth(v0, v1, v2, alpha: material.color.a, into: target)
            } else {
                let color = Color(r: clampChannel(v0.r), g: clampChannel(v0.g), b: clampChannel(v0.b), a: material.color.a)
                TriangleRasterizer.fill(v0, v1, v2, color: color, into: target)
            }
        }
    }
    
    @inline(__always)
    private func clampChannel(_ value: Float) -> UInt8 {
        UInt8(max(0, min(255, value)))
    }
    
    /// Calculate the lit color (unclamped 0-255 channels) for a surface normal
    private func lit(_ baseColor: Color, normal: Vec3d, material: Material, lighting: Lighting) -> Vec3d {
        let base = Vec3d(Float(baseColor.r), Float(baseColor.g), Float(baseColor.b))
        
        // Unlit materials don't receive lighting
        if material.shadingModel == .unlit {
            return base
        }
        
        // Start with ambient contribution
        let ambient = lighting.ambientColor
        var total = Vec3d(
            base.x * lighting.ambientIntensity * Float(ambient.r) / 255,
            base.y * lighting.ambientIntensity * Float(ambient.g) / 255,
            base.z * lighting.ambientIntensity * Float(ambient.b) / 255
        )
        
        // Add contribution from each directional light
        for light in lighting.directionalLights {
            let contribution = max(0, normal.dot(light.direction)) * light.intensity
            total = total + Vec3d(
                base.x * contribution * Float(light.color.r) / 255,
                base.y * contribution * Float(light.color.g) / 255,
                base.z * contribution * Float(light.color.b) / 255
            )
        }
        
        return total
    }
}
