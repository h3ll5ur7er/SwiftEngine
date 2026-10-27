import Testing
@testable import GameEngine

@Suite("Key Tests")
struct KeyTests {
    
    @Test("Key enum has expected values")
    func keyValues() {
        // Test that we can access various key types
        let arrowKeys: [Key] = [.left, .right, .up, .down]
        #expect(arrowKeys.count == 4)
        
        let specialKeys: [Key] = [.escape, .space, .enter, .tab]
        #expect(specialKeys.count == 4)
        
        let letterKeys: [Key] = [.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
                                  .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]
        #expect(letterKeys.count == 26)
    }
    
    @Test("Key is CaseIterable")
    func keyIsCaseIterable() {
        let allKeys = Key.allCases
        #expect(allKeys.count > 0)
    }
}

@Suite("MouseButton Tests")
struct MouseButtonTests {
    
    @Test("MouseButton enum values")
    func mouseButtonValues() {
        let buttons: [MouseButton] = [.left, .right, .middle]
        #expect(buttons.count == 3)
    }
    
    @Test("MouseButton is CaseIterable")
    func mouseButtonIsCaseIterable() {
        let allButtons = MouseButton.allCases
        #expect(allButtons.count == 3)
    }
}

@Suite("Input State Tests")
@MainActor
struct InputStateTests {
    
    @Test("A key held across frames is pressed only on the first frame")
    func heldKey() {
        let input = Input()
        input.beginFrame()
        input.setKeyState(.space, down: true)
        #expect(input.isKeyPressed(.space))
        #expect(input.isKeyDown(.space))
        
        input.beginFrame()
        #expect(!input.isKeyPressed(.space))
        #expect(input.isKeyDown(.space))
        
        input.beginFrame()
        input.setKeyState(.space, down: false)
        #expect(input.isKeyReleased(.space))
        #expect(!input.isKeyDown(.space))
        
        input.beginFrame()
        #expect(!input.isKeyReleased(.space))
    }
    
    @Test("A tap shorter than one frame reports both press and release")
    func tapWithinFrame() {
        let input = Input()
        input.beginFrame()
        input.setKeyState(.escape, down: true)
        input.setKeyState(.escape, down: false)
        
        #expect(input.isKeyPressed(.escape))
        #expect(input.isKeyReleased(.escape))
        #expect(!input.isKeyDown(.escape))
    }
    
    @Test("Repeated key-down events (auto-repeat) don't re-trigger presses")
    func autoRepeat() {
        let input = Input()
        input.beginFrame()
        input.setKeyState(.a, down: true)
        input.beginFrame()
        input.setKeyState(.a, down: true)
        #expect(!input.isKeyPressed(.a))
    }
    
    @Test("A click shorter than one frame reports both press and release")
    func clickWithinFrame() {
        let input = Input()
        input.beginFrame()
        input.setMouseButtonState(.left, down: true)
        input.setMouseButtonState(.left, down: false)
        
        #expect(input.isMouseButtonPressed(.left))
        #expect(input.isMouseButtonReleased(.left))
        
        input.beginFrame()
        #expect(!input.isMouseButtonPressed(.left))
    }
}
