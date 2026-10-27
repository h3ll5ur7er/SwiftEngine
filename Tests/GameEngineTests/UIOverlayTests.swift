import Testing
@testable import GameEngine

@Suite("UIOverlay Layout Tests")
@MainActor
struct UIOverlayTests {

    /// A render context of the given size (no pixel memory is needed for layout)
    func context(width: Int32 = 800, height: Int32 = 600) -> RenderContext {
        let backbuffer = Backbuffer()
        backbuffer.resize(width: width, height: height)
        return RenderContext(renderer: Renderer(backbuffer: backbuffer))
    }
    
    func overlay(_ configure: (UIOverlay) -> Void) -> UIOverlay {
        let overlay = GameObject(name: "Overlay").addComponent(UIOverlay.self)
        configure(overlay)
        overlay.setContent(UIRectangle().frame(width: 100, height: 50))
        return overlay
    }
    
    @Test("Without anchor or size the overlay covers the screen")
    func fullScreen() {
        let o = overlay { _ in }
        o.render(context: context())
        #expect(o.lastBounds == UIRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    @Test("An anchored overlay fits its content plus padding")
    func anchoredFitsContent() {
        let o = overlay { $0.anchor(.bottomRight).padding(10) }
        o.render(context: context())
        #expect(o.lastBounds == UIRect(x: 680, y: 530, width: 120, height: 70))
    }
    
    @Test("A fixed size is placed by its anchor")
    func fixedSizeAnchored() {
        let o = overlay { $0.anchor(.center).size(200, 100) }
        o.render(context: context())
        #expect(o.lastBounds == UIRect(x: 300, y: 250, width: 200, height: 100))
    }
}
