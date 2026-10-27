/// A vertex ready for rasterization
public struct RasterVertex: Sendable {
    /// Screen-space position in pixels (y down)
    public var x: Float
    public var y: Float
    
    /// NDC depth (-1 = near plane, 1 = far plane)
    public var z: Float
    
    /// Color channels (0-255, unclamped)
    public var r: Float
    public var g: Float
    public var b: Float
    
    public init(x: Float, y: Float, z: Float, r: Float = 0, g: Float = 0, b: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.r = r
        self.g = g
        self.b = b
    }
}

/// Color and depth buffers a triangle is rasterized into
public struct RasterTarget {
    public let pixels: UnsafeMutablePointer<UInt32>
    public let depth: UnsafeMutablePointer<Float>
    public let width: Int
    public let height: Int
    
    public init(pixels: UnsafeMutablePointer<UInt32>, depth: UnsafeMutablePointer<Float>, width: Int, height: Int) {
        self.pixels = pixels
        self.depth = depth
        self.width = width
        self.height = height
    }
}

/// Depth-tested scanline triangle rasterizer.
///
/// Pixels are covered when their center lies inside the triangle, with half-open
/// spans and rows, so triangles sharing an edge never leave gaps or overlap.
/// Depth and color are interpolated linearly in screen space.
public enum TriangleRasterizer {

    /// Fill a triangle with a single color
    public static func fill(_ v0: RasterVertex, _ v1: RasterVertex, _ v2: RasterVertex, color: Color, into target: RasterTarget) {
        rasterize(v0, v1, v2, smooth: false, flatColor: color.argb, alpha: color.a, into: target)
    }
    
    /// Fill a triangle, interpolating the vertex colors
    public static func fillSmooth(_ v0: RasterVertex, _ v1: RasterVertex, _ v2: RasterVertex, alpha: UInt8 = 255, into target: RasterTarget) {
        rasterize(v0, v1, v2, smooth: true, flatColor: 0, alpha: alpha, into: target)
    }
    
    @inline(__always)
    private static func rasterize(
        _ v0: RasterVertex, _ v1: RasterVertex, _ v2: RasterVertex,
        smooth: Bool, flatColor: UInt32, alpha: UInt8,
        into target: RasterTarget
    ) {
        let area = (v1.x - v0.x) * (v2.y - v0.y) - (v2.x - v0.x) * (v1.y - v0.y)
        guard abs(area) > 1e-6, area.isFinite else { return }
        let invArea = 1 / area
        
        // Screen-space gradients of an attribute over the triangle's plane
        @inline(__always)
        func gradients(_ a0: Float, _ a1: Float, _ a2: Float) -> (dx: Float, dy: Float) {
            let dx = ((a1 - a0) * (v2.y - v0.y) - (a2 - a0) * (v1.y - v0.y)) * invArea
            let dy = ((a2 - a0) * (v1.x - v0.x) - (a1 - a0) * (v2.x - v0.x)) * invArea
            return (dx, dy)
        }
        
        let dz = gradients(v0.z, v1.z, v2.z)
        let dr = smooth ? gradients(v0.r, v1.r, v2.r) : (dx: 0, dy: 0)
        let dg = smooth ? gradients(v0.g, v1.g, v2.g) : (dx: 0, dy: 0)
        let db = smooth ? gradients(v0.b, v1.b, v2.b) : (dx: 0, dy: 0)
        let alphaBits = UInt32(alpha) << 24
        
        // Rows whose pixel centers lie in [minY, maxY)
        let minY = min(v0.y, v1.y, v2.y)
        let maxY = max(v0.y, v1.y, v2.y)
        let yStart = max(0, Int((minY - 0.5).rounded(.up)))
        let yEnd = min(target.height - 1, Int((maxY - 0.5).rounded(.up)) - 1)
        guard yStart <= yEnd else { return }
        
        // Edges ordered top to bottom so shared edges produce identical x values
        @inline(__always)
        func ordered(_ a: RasterVertex, _ b: RasterVertex) -> (top: RasterVertex, bottom: RasterVertex) {
            a.y <= b.y ? (a, b) : (b, a)
        }
        let e0 = ordered(v0, v1)
        let e1 = ordered(v1, v2)
        let e2 = ordered(v2, v0)
        
        for y in yStart...yEnd {
            let yc = Float(y) + 0.5
            
            // Span between the two edges crossing this row's pixel centers
            var xl = Float.infinity
            var xr = -Float.infinity
            @inline(__always)
            func cross(_ edge: (top: RasterVertex, bottom: RasterVertex)) {
                guard edge.top.y <= yc && yc < edge.bottom.y else { return }
                let x = edge.top.x + (yc - edge.top.y) * (edge.bottom.x - edge.top.x) / (edge.bottom.y - edge.top.y)
                xl = min(xl, x)
                xr = max(xr, x)
            }
            cross(e0)
            cross(e1)
            cross(e2)
            guard xl < xr else { continue }
            
            // Columns whose pixel centers lie in [xl, xr)
            let xStart = max(0, Int((xl - 0.5).rounded(.up)))
            let xEnd = min(target.width - 1, Int((xr - 0.5).rounded(.up)) - 1)
            guard xStart <= xEnd else { continue }
            
            let fx = Float(xStart) + 0.5 - v0.x
            let fy = yc - v0.y
            var z = v0.z + dz.dx * fx + dz.dy * fy
            var r = v0.r + dr.dx * fx + dr.dy * fy
            var g = v0.g + dg.dx * fx + dg.dy * fy
            var b = v0.b + db.dx * fx + db.dy * fy
            
            let row = y * target.width
            for x in xStart...xEnd {
                let i = row + x
                if z < target.depth[i] {
                    target.depth[i] = z
                    if smooth {
                        target.pixels[i] = alphaBits
                            | UInt32(max(0, min(255, r))) << 16
                            | UInt32(max(0, min(255, g))) << 8
                            | UInt32(max(0, min(255, b)))
                    } else {
                        target.pixels[i] = flatColor
                    }
                }
                z += dz.dx
                r += dr.dx
                g += dg.dx
                b += db.dx
            }
        }
    }
}

// MARK: - Clipping

/// Clips clip-space polygons against the near and far planes
public enum TriangleClipper {

    /// A clip-space vertex with the attributes interpolated across clipped edges
    public struct Vertex: Sendable {
        public var position: Vec4d
        public var r: Float
        public var g: Float
        public var b: Float
        
        public init(position: Vec4d, r: Float = 0, g: Float = 0, b: Float = 0) {
            self.position = position
            self.r = r
            self.g = g
            self.b = b
        }
        
        func lerp(to other: Vertex, t: Float) -> Vertex {
            Vertex(
                position: Vec4d(
                    position.x + (other.position.x - position.x) * t,
                    position.y + (other.position.y - position.y) * t,
                    position.z + (other.position.z - position.z) * t,
                    position.w + (other.position.w - position.w) * t
                ),
                r: r + (other.r - r) * t,
                g: g + (other.g - g) * t,
                b: b + (other.b - b) * t
            )
        }
    }
    
    /// Signed distance to the near plane (z = -w); inside when >= 0
    @inline(__always)
    static func nearDistance(_ p: Vec4d) -> Float { p.z + p.w }
    
    /// Signed distance to the far plane (z = w); inside when >= 0
    @inline(__always)
    static func farDistance(_ p: Vec4d) -> Float { p.w - p.z }
    
    /// Whether the triangle lies entirely between the near and far planes
    @inline(__always)
    public static func isInsideDepthRange(_ a: Vec4d, _ b: Vec4d, _ c: Vec4d) -> Bool {
        nearDistance(a) >= 0 && nearDistance(b) >= 0 && nearDistance(c) >= 0 &&
            farDistance(a) >= 0 && farDistance(b) >= 0 && farDistance(c) >= 0
    }
    
    /// Clip a triangle against the near and far planes (Sutherland-Hodgman).
    /// Returns a convex polygon (0, or 3 to 5 vertices) in the triangle's winding order.
    public static func clip(_ a: Vertex, _ b: Vertex, _ c: Vertex) -> [Vertex] {
        let nearClipped = clip([a, b, c], distance: nearDistance)
        return clip(nearClipped, distance: farDistance)
    }
    
    private static func clip(_ polygon: [Vertex], distance: (Vec4d) -> Float) -> [Vertex] {
        guard !polygon.isEmpty else { return [] }
        var output: [Vertex] = []
        output.reserveCapacity(polygon.count + 1)
        
        for i in polygon.indices {
            let current = polygon[i]
            let next = polygon[(i + 1) % polygon.count]
            let dCurrent = distance(current.position)
            let dNext = distance(next.position)
            
            if dCurrent >= 0 {
                output.append(current)
            }
            if (dCurrent >= 0) != (dNext >= 0) {
                output.append(current.lerp(to: next, t: dCurrent / (dCurrent - dNext)))
            }
        }
        
        return output.count >= 3 ? output : []
    }
}
