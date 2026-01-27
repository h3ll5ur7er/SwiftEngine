

/// Context for rendering UI elements
@MainActor
public final class UIRenderContext {
    /// The underlying renderer
    public let renderer: Renderer
    
    /// The font to use for text rendering
    public var font: BitmapFont?
    
    /// Screen width
    public var width: Float { Float(renderer.width) }
    
    /// Screen height  
    public var height: Float { Float(renderer.height) }
    
    /// Screen bounds
    public var bounds: UIRect {
        UIRect(x: 0, y: 0, width: width, height: height)
    }
    
    public init(renderer: Renderer, font: BitmapFont? = nil) {
        self.renderer = renderer
        self.font = font
    }
    
    // MARK: - Drawing Primitives
    
    /// Fill a rectangle with a solid color
    public func fillRect(_ rect: UIRect, color: Color) {
        Primitives.fillRect(rect.toRect(), color: color)
    }
    
    /// Draw a rectangle outline
    public func strokeRect(_ rect: UIRect, color: Color, lineWidth: Float = 1) {
        let r = rect.toRect()
        // Draw each edge
        // Top
        Primitives.fillRect(Rect(x: r.x, y: r.y, width: r.width, height: Int32(lineWidth)), color: color)
        // Bottom
        Primitives.fillRect(Rect(x: r.x, y: r.bottom - Int32(lineWidth), width: r.width, height: Int32(lineWidth)), color: color)
        // Left
        Primitives.fillRect(Rect(x: r.x, y: r.y, width: Int32(lineWidth), height: r.height), color: color)
        // Right
        Primitives.fillRect(Rect(x: r.right - Int32(lineWidth), y: r.y, width: Int32(lineWidth), height: r.height), color: color)
    }
    
    /// Fill a rounded rectangle (simplified - just draws corners as small rects for now)
    public func fillRoundedRect(_ rect: UIRect, color: Color, cornerRadius: Float) {
        // For now, just fill a regular rect
        // TODO: Implement proper rounded corners with circle drawing
        fillRect(rect, color: color)
    }
    
    /// Draw text at the given position
    public func drawText(_ text: String, at position: (x: Float, y: Float), color: Color, scale: Int = 1) {
        guard let font = font else { return }
        font.drawText(text, x: Int32(position.x), y: Int32(position.y), color: color, scale: scale, renderer: renderer)
    }
    
    /// Measure text size
    public func measureText(_ text: String, scale: Int = 1) -> Size {
        guard let font = font else { return .zero }
        let measured = font.measureText(text, scale: scale)
        return Size(width: Float(measured.width), height: Float(measured.height))
    }
    
    /// Draw a line
    public func drawLine(from: (x: Float, y: Float), to: (x: Float, y: Float), color: Color) {
        Primitives.drawLine(
            x0: Int32(from.x), y0: Int32(from.y),
            x1: Int32(to.x), y1: Int32(to.y),
            color: color
        )
    }
    
    /// Fill a circle
    public func fillCircle(center: (x: Float, y: Float), radius: Float, color: Color) {
        Primitives.fillCircle(
            center: Vec2(Int32(center.x), Int32(center.y)),
            radius: Int32(radius),
            color: color
        )
    }
    
    // MARK: - Clipping
    
    private var clipStack: [UIRect] = []
    
    /// Push a clip rect onto the stack
    public func pushClipRect(_ rect: UIRect) {
        // If there's an existing clip, intersect with it
        if let current = clipStack.last {
            let intersection = rect.intersection(with: current)
            clipStack.append(intersection)
        } else {
            clipStack.append(rect)
        }
        applyClipRect()
    }
    
    /// Pop the current clip rect
    public func popClipRect() {
        if !clipStack.isEmpty {
            clipStack.removeLast()
        }
        applyClipRect()
    }
    
    private func applyClipRect() {
        if let clip = clipStack.last {
            Primitives.setClipRect(clip.toRect())
        } else {
            Primitives.clearClipRect()
        }
    }
    
    // MARK: - Primitives Access
    
    /// Direct access to Primitives for advanced drawing
    public var primitives: Primitives.Type {
        Primitives.self
    }
}
