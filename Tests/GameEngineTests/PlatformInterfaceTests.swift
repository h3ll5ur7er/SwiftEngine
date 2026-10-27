import Testing
@testable import GameEngine

@Suite("PlatformInterface Tests")
@MainActor
struct PlatformInterfaceTests {

    #if os(Linux)
    @Test("X11 keysyms map to engine keys, including right-hand modifiers")
    func linuxKeysyms() {
        #expect(PlatformInterface.translateKeyCode(0x61) == .a)     // XK_a
        #expect(PlatformInterface.translateKeyCode(0x41) == .a)     // XK_A (shifted)
        #expect(PlatformInterface.translateKeyCode(0xFFE1) == .shift)
        #expect(PlatformInterface.translateKeyCode(0xFFE2) == .shift)
        #expect(PlatformInterface.translateKeyCode(0xFFE3) == .control)
        #expect(PlatformInterface.translateKeyCode(0xFFE4) == .control)
        #expect(PlatformInterface.translateKeyCode(0xFFE9) == .alt)
        #expect(PlatformInterface.translateKeyCode(0xFFEA) == .alt)
        #expect(PlatformInterface.translateKeyCode(0xFF0D) == .enter)
        #expect(PlatformInterface.translateKeyCode(0xFF8D) == .enter)
        #expect(PlatformInterface.translateKeyCode(0x1234) == nil)
    }
    #endif
    
    @Test("Duration converts to fractional seconds")
    func durationSeconds() {
        #expect(Duration.milliseconds(1500).seconds == 1.5)
        #expect(abs(Duration.microseconds(16_667).seconds - 0.016667) < 1e-9)
    }
}
