import Testing
@testable import GameEngine

/// Owns a small color + depth buffer for rasterizer tests
final class TestRasterBuffer {
    let width: Int
    let height: Int
    let pixels: UnsafeMutablePointer<UInt32>
    let depth: UnsafeMutablePointer<Float>
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = .allocate(capacity: width * height)
        depth = .allocate(capacity: width * height)
        clear()
    }
    
    deinit {
        pixels.deallocate()
        depth.deallocate()
    }
    
    var target: RasterTarget {
        RasterTarget(pixels: pixels, depth: depth, width: width, height: height)
    }
    
    func clear() {
        pixels.update(repeating: 0, count: width * height)
        depth.update(repeating: .infinity, count: width * height)
    }
    
    subscript(x: Int, y: Int) -> UInt32 {
        pixels[y * width + x]
    }
    
    /// Indices of all written pixels
    var covered: Set<Int> {
        Set((0..<(width * height)).filter { pixels[$0] != 0 })
    }
}

@Suite("TriangleRasterizer Tests")
struct TriangleRasterizerTests {

    func v(_ x: Float, _ y: Float, _ z: Float = 0) -> RasterVertex {
        RasterVertex(x: x, y: y, z: z)
    }
    
    @Test("Covers pixels whose centers are inside the triangle")
    func coversPixelCenters() {
        let buffer = TestRasterBuffer(width: 8, height: 8)
        // Right triangle covering the lower-left half of a 4x4 block
        TriangleRasterizer.fill(v(0, 0), v(0, 4), v(4, 4), color: .red, into: buffer.target)
        
        // Row y has centers at y+0.5 and the hypotenuse is x = y; centers exactly on
        // the right edge are excluded, so row y covers columns x < y
        for y in 0..<4 {
            for x in 0..<8 {
                let expected = x < y
                #expect((buffer[x, y] != 0) == expected, "pixel (\(x), \(y))")
            }
        }
    }
    
    @Test("Triangles sharing an edge cover a quad exactly once")
    func sharedEdgeNoGapsNoOverlap() {
        let a = TestRasterBuffer(width: 32, height: 32)
        let b = TestRasterBuffer(width: 32, height: 32)
        // Skewed quad split along its diagonal
        let p0 = v(2.3, 1.7), p1 = v(27.9, 4.2), p2 = v(29.1, 30.6), p3 = v(3.4, 26.8)
        TriangleRasterizer.fill(p0, p1, p2, color: .red, into: a.target)
        TriangleRasterizer.fill(p0, p2, p3, color: .red, into: b.target)
        
        // Reference: point-in-quad test at every pixel center
        func inside(_ x: Float, _ y: Float) -> Bool {
            let quad = [p0, p1, p2, p3]
            var sign: Float = 0
            for i in 0..<4 {
                let s = quad[i], e = quad[(i + 1) % 4]
                let cross = (e.x - s.x) * (y - s.y) - (e.y - s.y) * (x - s.x)
                if sign == 0 { sign = cross } else if cross * sign < 0 { return false }
            }
            return true
        }
        #expect(a.covered.isDisjoint(with: b.covered))
        let union = a.covered.union(b.covered)
        for y in 0..<32 {
            for x in 0..<32 {
                let center = inside(Float(x) + 0.5, Float(y) + 0.5)
                #expect(union.contains(y * 32 + x) == center, "pixel (\(x), \(y))")
            }
        }
    }
    
    @Test("Nearer triangles win regardless of draw order")
    func depthTest() {
        let buffer = TestRasterBuffer(width: 8, height: 8)
        let near = Color.green, far = Color.red
        
        TriangleRasterizer.fill(v(0, 0, -0.5), v(8, 0, -0.5), v(0, 8, -0.5), color: near, into: buffer.target)
        TriangleRasterizer.fill(v(0, 0, 0.5), v(8, 0, 0.5), v(0, 8, 0.5), color: far, into: buffer.target)
        #expect(buffer[1, 1] == near.argb)
        
        buffer.clear()
        TriangleRasterizer.fill(v(0, 0, 0.5), v(8, 0, 0.5), v(0, 8, 0.5), color: far, into: buffer.target)
        TriangleRasterizer.fill(v(0, 0, -0.5), v(8, 0, -0.5), v(0, 8, -0.5), color: near, into: buffer.target)
        #expect(buffer[1, 1] == near.argb)
    }
    
    @Test("Intersecting triangles are resolved per pixel")
    func intersectingTriangles() {
        let buffer = TestRasterBuffer(width: 16, height: 4)
        // Depth slopes in opposite directions and crosses at x = 8
        TriangleRasterizer.fill(v(0, 0, -1), v(16, 0, 1), v(0, 4, -1), color: .red, into: buffer.target)
        TriangleRasterizer.fill(v(16, 4, -1), v(0, 4, 1), v(16, 0, -1), color: .blue, into: buffer.target)
        
        // Each side shows the triangle that is nearer there
        #expect(buffer[2, 2] == Color.red.argb)
        #expect(buffer[13, 1] == Color.blue.argb)
    }
    
    @Test("Smooth fill interpolates vertex colors")
    func smoothInterpolates() {
        let buffer = TestRasterBuffer(width: 64, height: 64)
        let a = RasterVertex(x: 0, y: 0, z: 0, r: 0, g: 0, b: 0)
        let b = RasterVertex(x: 64, y: 0, z: 0, r: 255, g: 0, b: 0)
        let c = RasterVertex(x: 0, y: 64, z: 0, r: 0, g: 0, b: 255)
        TriangleRasterizer.fillSmooth(a, b, c, into: buffer.target)
        
        let left = Color(argb: buffer[0, 0])
        let right = Color(argb: buffer[60, 0])
        #expect(left.r < 10)
        #expect(right.r > 230)
        #expect(Color(argb: buffer[0, 60]).b > 230)
    }
    
    @Test("Off-screen parts are clipped to the target")
    func clipsToTarget() {
        let buffer = TestRasterBuffer(width: 8, height: 8)
        TriangleRasterizer.fill(v(-100, -100), v(300, -100), v(-100, 300), color: .red, into: buffer.target)
        #expect(buffer.covered.count == 64)
    }
    
    @Test("Degenerate triangles draw nothing")
    func degenerate() {
        let buffer = TestRasterBuffer(width: 8, height: 8)
        TriangleRasterizer.fill(v(0, 0), v(4, 4), v(8, 8), color: .red, into: buffer.target)
        #expect(buffer.covered.isEmpty)
    }
}

@Suite("TriangleClipper Tests")
struct TriangleClipperTests {

    func vertex(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> TriangleClipper.Vertex {
        TriangleClipper.Vertex(position: Vec4d(x, y, z, w))
    }
    
    @Test("Triangle inside the depth range is unchanged")
    func insideUnchanged() {
        let polygon = TriangleClipper.clip(vertex(0, 0, 0, 1), vertex(1, 0, 0, 1), vertex(0, 1, 0, 1))
        #expect(polygon.count == 3)
        #expect(TriangleClipper.isInsideDepthRange(Vec4d(0, 0, 0, 1), Vec4d(1, 0, 0, 1), Vec4d(0, 1, 0, 1)))
    }
    
    @Test("One vertex behind the near plane yields a quad on the near plane")
    func oneBehindNear() {
        // Third vertex behind the camera (w < 0, z < -w)
        let polygon = TriangleClipper.clip(vertex(0, 0, 0, 1), vertex(1, 0, 0, 1), vertex(0, 1, 2, -2))
        #expect(polygon.count == 4)
        for v in polygon {
            #expect(v.position.z + v.position.w >= -1e-5)
        }
    }
    
    @Test("Two vertices behind the near plane yield a smaller triangle")
    func twoBehindNear() {
        let polygon = TriangleClipper.clip(vertex(0, 0, 0, 1), vertex(1, 0, 2, -2), vertex(0, 1, 2, -2))
        #expect(polygon.count == 3)
        for v in polygon {
            #expect(v.position.z + v.position.w >= -1e-5)
        }
    }
    
    @Test("Triangle entirely behind the camera is removed")
    func allBehind() {
        let polygon = TriangleClipper.clip(vertex(0, 0, 2, -2), vertex(1, 0, 2, -2), vertex(0, 1, 2, -2))
        #expect(polygon.isEmpty)
    }
    
    @Test("Far plane clipping")
    func farPlane() {
        let polygon = TriangleClipper.clip(vertex(0, 0, 0, 1), vertex(1, 0, 0, 1), vertex(0, 1, 5, 1))
        #expect(polygon.count == 4)
        for v in polygon {
            #expect(v.position.w - v.position.z >= -1e-5)
        }
    }
    
    @Test("Attributes are interpolated at the clip point")
    func attributesInterpolated() {
        // Edge from z=0,w=1 (near distance 1) to z=-3,w=1 (near distance -2): crosses at t = 1/3
        let a = TriangleClipper.Vertex(position: Vec4d(0, 0, 0, 1), r: 0)
        let b = TriangleClipper.Vertex(position: Vec4d(0, 0, -3, 1), r: 90)
        let c = TriangleClipper.Vertex(position: Vec4d(1, 0, 0, 1), r: 0)
        let polygon = TriangleClipper.clip(a, b, c)
        
        #expect(polygon.contains { abs($0.r - 30) < 0.001 })
    }
}
