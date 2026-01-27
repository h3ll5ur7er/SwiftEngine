import GameEngine

/// Demo scene with draggable triangle
@MainActor
public final class TriangleDemoScene: Scene {
    private var triPosition: Vec2 = Vec2(200, 180)
    private var mousePosition: Vec2 = Vec2(0, 0)
    private let moveSpeed: Float = 200.0 // pixels per second
    
    public init() {}
    
    public func onLoad(engine: Engine) {
        // Center the triangle
        let (width, height) = engine.windowSize
        triPosition = Vec2(width / 2, height / 2)
    }
    
    public func update(context: FrameContext, input: Input) {
        let delta = Float(context.deltaTime)
        let step = Int32(moveSpeed * delta)
        
        // Keyboard movement
        if input.isKeyDown(.left)  { triPosition.x -= step }
        if input.isKeyDown(.right) { triPosition.x += step }
        if input.isKeyDown(.up)    { triPosition.y -= step }
        if input.isKeyDown(.down)  { triPosition.y += step }
        
        // Track mouse position for rendering
        let (mx, my) = input.getMousePosition()
        mousePosition = Vec2(mx, my)
        
        // Mouse drag
        if input.isMouseButtonDown(.left) {
            triPosition = mousePosition
        }
    }
    
    public func render(context: RenderContext) {
        // Clear background
        context.renderer.clear(.vsCodeDark)
        
        // Draw triangle
        let size: Int32 = 70
        let p0 = Vec2(triPosition.x, triPosition.y - size)
        let p1 = Vec2(triPosition.x - size, triPosition.y + size - 20)
        let p2 = Vec2(triPosition.x + size, triPosition.y + size - 20)
        Primitives.fillTriangle(p0, p1, p2, color: .magenta)
        
        // Draw crosshair at mouse position
        Primitives.drawLine(
            from: Vec2(mousePosition.x - 10, mousePosition.y),
            to: Vec2(mousePosition.x + 10, mousePosition.y),
            color: .white
        )
        Primitives.drawLine(
            from: Vec2(mousePosition.x, mousePosition.y - 10),
            to: Vec2(mousePosition.x, mousePosition.y + 10),
            color: .white
        )
        
        // Draw some demo shapes
        Primitives.drawRect(Rect(x: 10, y: 10, width: 100, height: 30), color: .white)
        Primitives.drawCircle(center: Vec2(context.width - 50, 50), radius: 30, color: .cyan)
        Primitives.fillCircle(center: Vec2(context.width - 50, 120), radius: 25, color: .orange)
    }
}
