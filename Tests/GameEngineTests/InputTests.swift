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
