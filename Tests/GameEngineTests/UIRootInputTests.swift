import Testing
@testable import GameEngine

/// A view that records the keyboard events it receives
@MainActor
final class KeyboardRecorderView: View {
    var events: [KeyboardEventType] = []
    
    func sizeThatFits(_ proposal: ProposedSize) -> Size { Size(width: 10, height: 10) }
    func render(in bounds: UIRect, context: UIRenderContext) {}
    func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        events.append(event.type)
        return true
    }
}

@Suite("UIRoot Input Tests")
@MainActor
struct UIRootInputTests {

    @Test("A click within a single frame triggers a button")
    func clickWithinFrame() {
        var clicks = 0
        let root = UIRoot(content: Button("OK") { clicks += 1 })
        let input = Input()
        input.setMousePosition(x: 5, y: 5)
        
        input.beginFrame()
        input.setMouseButtonState(.left, down: true)
        input.setMouseButtonState(.left, down: false)
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        
        #expect(clicks == 1)
    }
    
    @Test("A click spread over frames triggers a button once")
    func clickAcrossFrames() {
        var clicks = 0
        let root = UIRoot(content: Button("OK") { clicks += 1 })
        let input = Input()
        input.setMousePosition(x: 5, y: 5)
        
        input.beginFrame()
        input.setMouseButtonState(.left, down: true)
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        input.beginFrame()
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        input.beginFrame()
        input.setMouseButtonState(.left, down: false)
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        input.beginFrame()
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        
        #expect(clicks == 1)
    }
    
    @Test("A key tap within a single frame is delivered with its character")
    func keyTapWithinFrame() {
        let recorder = KeyboardRecorderView()
        let root = UIRoot(content: recorder)
        let input = Input()
        
        input.beginFrame()
        input.setKeyState(.a, down: true)
        input.setKeyState(.a, down: false)
        root.handleInput(input, screenWidth: 100, screenHeight: 100)
        
        #expect(recorder.events.count == 3)
        if case .pressed = recorder.events.first {} else { Issue.record("expected press first") }
        if case .character(let c) = recorder.events[1] { #expect(c == "a") } else { Issue.record("expected character") }
        if case .released = recorder.events.last {} else { Issue.record("expected release last") }
    }
}
