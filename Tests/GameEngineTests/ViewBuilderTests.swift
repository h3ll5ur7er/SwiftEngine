import Testing
@testable import GameEngine

@Suite("ViewBuilder Tests")
@MainActor
struct ViewBuilderTests {

    let unbounded = ProposedSize(width: nil, height: nil)
    
    @Test("ForEach inside a stack lays out like the same views written out")
    func forEachExpandsInStack() {
        let generated = VStack { ForEach([1, 2, 3]) { i in Text("Item \(i)") } }
        let written = VStack {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        
        #expect(generated.children.count == 3)
        #expect(generated.sizeThatFits(unbounded) == written.sizeThatFits(unbounded))
    }
    
    @Test("Standalone ForEach measures its items stacked vertically")
    func standaloneForEach() {
        let forEach = ForEach(["a", "b"]) { Text($0) }
        let one = Text("a").sizeThatFits(unbounded)
        #expect(forEach.sizeThatFits(unbounded).height == one.height * 2)
    }
    
    @Test("If re-checks its condition and keeps its content")
    func ifReevaluates() {
        var show = false
        let view = If(show) { Text("Visible") }
        #expect(view.sizeThatFits(unbounded) == .zero)
        
        show = true
        #expect(view.sizeThatFits(unbounded).width > 0)
    }
    
    @Test("If/else switches branches")
    func ifElse() {
        var wide = true
        let view = If(wide) { Text("A long label") } else: { Text("Short") }
        let wideSize = view.sizeThatFits(unbounded)
        wide = false
        #expect(view.sizeThatFits(unbounded).width < wideSize.width)
    }
    
    @Test("A button inside If keeps its pressed state between press and release")
    func ifKeepsControlState() {
        var clicks = 0
        let view = If(true) { Button("OK") { clicks += 1 } }
        let bounds = UIRect(x: 0, y: 0, width: 100, height: 40)
        
        _ = view.handleMouse(MouseEvent(type: .pressed(.left), x: 5, y: 5), in: bounds)
        _ = view.handleMouse(MouseEvent(type: .released(.left), x: 5, y: 5), in: bounds)
        #expect(clicks == 1)
    }
}
