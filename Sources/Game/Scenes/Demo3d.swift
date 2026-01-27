import GameEngine

/// Demo scene showing 3D concepts with matrix transformations
@MainActor
public final class Demo3dScene: Scene {
    private var rotation: Float32 = 0
    private var cubeVertices: [Vec3d] = []
    private let rotationSpeed: Float32 = 1.0 // radians per second
    
    public init() {
        // Define unit cube vertices centered at origin
        cubeVertices = [
            Vec3d(-0.5, -0.5, -0.5),
            Vec3d( 0.5, -0.5, -0.5),
            Vec3d( 0.5,  0.5, -0.5),
            Vec3d(-0.5,  0.5, -0.5),
            Vec3d(-0.5, -0.5,  0.5),
            Vec3d( 0.5, -0.5,  0.5),
            Vec3d( 0.5,  0.5,  0.5),
            Vec3d(-0.5,  0.5,  0.5),
        ]
    }
    
    public func onLoad(engine: Engine) {}
    
    public func update(context: FrameContext, input: Input) {
        let delta = Float32(context.deltaTime)
        rotation += rotationSpeed * delta
    }
    
    public func render(context: RenderContext) {
        context.renderer.clear(.vsCodeDark)
        
        let centerX = Float32(context.width) / 2
        let centerY = Float32(context.height) / 2
        let scale: Float32 = 100
        
        // Create rotation matrix
        let rotMatrix = Mat4d.rotY(angle: rotation) * Mat4d.rotX(angle: rotation * 0.5)
        
        // Project and draw cube edges
        let edges: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 0), // front face
            (4, 5), (5, 6), (6, 7), (7, 4), // back face
            (0, 4), (1, 5), (2, 6), (3, 7)  // connecting edges
        ]
        
        // Transform vertices
        var projected: [Vec2] = []
        for v in cubeVertices {
            let transformed = rotMatrix.transformPoint(v)
            // Simple orthographic projection
            let x = Int32(centerX + transformed.x * scale)
            let y = Int32(centerY - transformed.y * scale) // flip Y for screen coords
            projected.append(Vec2(x, y))
        }
        
        // Draw edges with depth-based coloring
        for (i, j) in edges {
            let avgZ = (cubeVertices[i].z + cubeVertices[j].z) / 2
            let brightness = UInt8(128 + Int(avgZ * 100))
            let color = Color(r: brightness, g: brightness, b: 255, a: 255)
            Primitives.drawLine(from: projected[i], to: projected[j], color: color)
        }
    }
}
