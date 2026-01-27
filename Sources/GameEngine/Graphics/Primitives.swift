/// Static drawing primitives that operate on the current renderer
@MainActor
public enum Primitives {
    /// Current renderer (set by Engine before each render call)
    static var currentRenderer: Renderer?
    
    /// Optional clip rectangle
    private static var clipRect: Rect?
    
    // MARK: - Clipping
    
    /// Set a clip rectangle for all drawing operations
    public static func setClipRect(_ rect: Rect) {
        clipRect = rect
    }
    
    /// Clear the clip rectangle
    public static func clearClipRect() {
        clipRect = nil
    }
    
    /// Get the current effective bounds (screen or clip rect)
    private static func getEffectiveBounds() -> (left: Int32, top: Int32, right: Int32, bottom: Int32)? {
        guard let renderer = currentRenderer else { return nil }
        
        if let clip = clipRect {
            // Intersect clip with screen bounds
            let left = max(0, clip.left)
            let top = max(0, clip.top)
            let right = min(renderer.width, clip.right)
            let bottom = min(renderer.height, clip.bottom)
            return (left, top, right, bottom)
        } else {
            return (0, 0, renderer.width, renderer.height)
        }
    }
    
    // MARK: - Pixel Operations
    
    /// Draw a single pixel
    @inline(__always)
    public static func drawPixel(_ x: Int32, _ y: Int32, _ color: Color) {
        guard let renderer = currentRenderer,
              let bits = renderer.rawBuffer else { return }
        
        // Check against clip rect or screen bounds
        if let clip = clipRect {
            guard x >= clip.left, x < clip.right, y >= clip.top, y < clip.bottom else { return }
        }
        guard x >= 0, y >= 0, x < renderer.width, y < renderer.height else { return }
        
        let idx = Int(y * renderer.width + x)
        bits[idx] = color.argb
    }
    
    /// Draw a single pixel at a Vec2 position
    @inline(__always)
    public static func drawPixel(_ pos: Vec2, _ color: Color) {
        drawPixel(pos.x, pos.y, color)
    }
    
    // MARK: - Line Drawing
    
    /// Draw a line using Bresenham's algorithm
    public static func drawLine(from p0: Vec2, to p1: Vec2, color: Color) {
        drawLine(x0: p0.x, y0: p0.y, x1: p1.x, y1: p1.y, color: color)
    }
    
    public static func drawLine(x0: Int32, y0: Int32, x1: Int32, y1: Int32, color: Color) {
        var x0 = x0, y0 = y0
        let dx = abs(x1 - x0), sx: Int32 = (x0 < x1) ? 1 : -1
        let dy = -abs(y1 - y0), sy: Int32 = (y0 < y1) ? 1 : -1
        var err = dx + dy
        
        while true {
            drawPixel(x0, y0, color)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }
    
    /// Draw a line with Int coordinates (convenience)
    public static func drawLine(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ color: Color) {
        drawLine(x0: Int32(x0), y0: Int32(y0), x1: Int32(x1), y1: Int32(y1), color: color)
    }
    
    // MARK: - Rectangle Drawing
    
    /// Draw a rectangle outline
    public static func drawRect(_ rect: Rect, color: Color) {
        let l = rect.left, t = rect.top, r = rect.right - 1, b = rect.bottom - 1
        drawLine(x0: l, y0: t, x1: r, y1: t, color: color) // Top
        drawLine(x0: l, y0: b, x1: r, y1: b, color: color) // Bottom
        drawLine(x0: l, y0: t, x1: l, y1: b, color: color) // Left
        drawLine(x0: r, y0: t, x1: r, y1: b, color: color) // Right
    }
    
    /// Fill a rectangle
    public static func fillRect(_ rect: Rect, color: Color) {
        guard let renderer = currentRenderer,
              let bits = renderer.rawBuffer else { return }
        
        let width = renderer.width
        let height = renderer.height
        
        // Calculate clip bounds
        var clipLeft: Int32 = 0
        var clipTop: Int32 = 0
        var clipRight = width
        var clipBottom = height
        
        if let clip = clipRect {
            clipLeft = max(0, clip.left)
            clipTop = max(0, clip.top)
            clipRight = min(width, clip.right)
            clipBottom = min(height, clip.bottom)
        }
        
        // Clip to screen and clip rect bounds
        let left = max(clipLeft, rect.left)
        let top = max(clipTop, rect.top)
        let right = min(clipRight, rect.right)
        let bottom = min(clipBottom, rect.bottom)
        
        if left >= right || top >= bottom { return }
        
        let argb = color.argb
        for y in top..<bottom {
            let rowStart = Int(y * width + left)
            for x in 0..<Int(right - left) {
                bits[rowStart + x] = argb
            }
        }
    }
    
    /// Fill a rectangle with x, y, width, height (convenience)
    public static func fillRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: Color) {
        fillRect(Rect(x: Int32(x), y: Int32(y), width: Int32(w), height: Int32(h)), color: color)
    }
    
    /// Draw a rectangle outline with x, y, width, height (convenience)
    public static func drawRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: Color) {
        drawRect(Rect(x: Int32(x), y: Int32(y), width: Int32(w), height: Int32(h)), color: color)
    }
    
    // MARK: - Triangle Drawing
    
    /// Draw a triangle outline
    public static func drawTriangle(_ a: Vec2, _ b: Vec2, _ c: Vec2, color: Color) {
        drawLine(from: a, to: b, color: color)
        drawLine(from: b, to: c, color: color)
        drawLine(from: c, to: a, color: color)
    }
    
    /// Fill a triangle using scanline rasterization
    public static func fillTriangle(_ a0: Vec2, _ b0: Vec2, _ c0: Vec2, color: Color) {
        guard let renderer = currentRenderer else { return }
        
        // Sort vertices by Y
        var a = a0, b = b0, c = c0
        if b.y < a.y { swap(&a, &b) }
        if c.y < a.y { swap(&a, &c) }
        if c.y < b.y { swap(&b, &c) }
        
        if a.y == c.y { return }
        
        let width = renderer.width
        let height = renderer.height
        
        func fillFlatBottom(top: Vec2, left: Vec2, right: Vec2) {
            guard left.y != top.y else { return }
            let inv1 = Float(left.x - top.x) / Float(left.y - top.y)
            let inv2 = Float(right.x - top.x) / Float(right.y - top.y)
            var cx1 = Float(top.x)
            var cx2 = Float(top.x)
            var y = top.y
            while y <= left.y {
                drawSpan(x0: Int32(cx1.rounded()), x1: Int32(cx2.rounded()), y: y, color: color, width: width, height: height)
                cx1 += inv1
                cx2 += inv2
                y += 1
            }
        }
        
        func fillFlatTop(left: Vec2, right: Vec2, bottom: Vec2) {
            guard bottom.y != left.y else { return }
            let inv1 = Float(bottom.x - left.x) / Float(bottom.y - left.y)
            let inv2 = Float(bottom.x - right.x) / Float(bottom.y - right.y)
            var cx1 = Float(bottom.x)
            var cx2 = Float(bottom.x)
            var y = bottom.y
            while y >= left.y {
                drawSpan(x0: Int32(cx1.rounded()), x1: Int32(cx2.rounded()), y: y, color: color, width: width, height: height)
                cx1 -= inv1
                cx2 -= inv2
                y -= 1
            }
        }
        
        if b.y == c.y {
            fillFlatBottom(top: a, left: b, right: c)
        } else if a.y == b.y {
            fillFlatTop(left: a, right: b, bottom: c)
        } else {
            let t = Float(b.y - a.y) / Float(c.y - a.y)
            let d = Vec2(x: a.x + Int32((Float(c.x - a.x) * t).rounded()), y: b.y)
            fillFlatBottom(top: a, left: b, right: d)
            fillFlatTop(left: b, right: d, bottom: c)
        }
    }
    
    // MARK: - Circle Drawing
    
    /// Draw a circle outline using midpoint algorithm
    public static func drawCircle(center: Vec2, radius: Int32, color: Color) {
        var x: Int32 = 0
        var y = radius
        var d = 3 - 2 * radius
        
        func plot8Points(_ cx: Int32, _ cy: Int32, _ x: Int32, _ y: Int32) {
            drawPixel(cx + x, cy + y, color)
            drawPixel(cx - x, cy + y, color)
            drawPixel(cx + x, cy - y, color)
            drawPixel(cx - x, cy - y, color)
            drawPixel(cx + y, cy + x, color)
            drawPixel(cx - y, cy + x, color)
            drawPixel(cx + y, cy - x, color)
            drawPixel(cx - y, cy - x, color)
        }
        
        while y >= x {
            plot8Points(center.x, center.y, x, y)
            x += 1
            if d > 0 {
                y -= 1
                d = d + 4 * (x - y) + 10
            } else {
                d = d + 4 * x + 6
            }
        }
    }
    
    /// Fill a circle
    public static func fillCircle(center: Vec2, radius: Int32, color: Color) {
        guard let renderer = currentRenderer else { return }
        let width = renderer.width
        let height = renderer.height
        
        var x: Int32 = 0
        var y = radius
        var d = 3 - 2 * radius
        
        func drawHLine(_ y: Int32, _ x1: Int32, _ x2: Int32) {
            drawSpan(x0: x1, x1: x2, y: y, color: color, width: width, height: height)
        }
        
        while y >= x {
            drawHLine(center.y + y, center.x - x, center.x + x)
            drawHLine(center.y - y, center.x - x, center.x + x)
            drawHLine(center.y + x, center.x - y, center.x + y)
            drawHLine(center.y - x, center.x - y, center.x + y)
            
            x += 1
            if d > 0 {
                y -= 1
                d = d + 4 * (x - y) + 10
            } else {
                d = d + 4 * x + 6
            }
        }
    }
    
    // MARK: - Private Helpers
    
    @inline(__always)
    private static func drawSpan(x0: Int32, x1: Int32, y: Int32, color: Color, width: Int32, height: Int32) {
        guard let renderer = currentRenderer,
              let bits = renderer.rawBuffer,
              y >= 0, y < height else { return }
        
        var a = x0, b = x1
        if a > b { swap(&a, &b) }
        a = max(0, min(a, width - 1))
        b = max(0, min(b, width - 1))
        if a > b { return }
        
        let argb = color.argb
        let rowStart = Int(y * width)
        for x in Int(a)...Int(b) {
            bits[rowStart + x] = argb
        }
    }
}
