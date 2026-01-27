import Testing
@testable import GameEngine

@Suite("Color Tests")
struct ColorTests {
    
    @Test("Color ARGB initialization")
    func argbInitialization() {
        let color = Color(argb: 0xAABBCCDD)
        #expect(color.a == 0xAA)
        #expect(color.r == 0xBB)
        #expect(color.g == 0xCC)
        #expect(color.b == 0xDD)
    }
    
    @Test("Color RGBA initialization")
    func rgbaInitialization() {
        let color = Color(r: 100, g: 150, b: 200, a: 255)
        #expect(color.r == 100)
        #expect(color.g == 150)
        #expect(color.b == 200)
        #expect(color.a == 255)
        
        // Check ARGB format
        #expect(color.argb == 0xFF6496C8)
    }
    
    @Test("Color gray initialization")
    func grayInitialization() {
        let color = Color(gray: 128)
        #expect(color.r == 128)
        #expect(color.g == 128)
        #expect(color.b == 128)
        #expect(color.a == 255)
    }
    
    @Test("Color with modified components")
    func componentModification() {
        let original = Color(r: 100, g: 100, b: 100, a: 255)
        
        let withNewAlpha = original.withAlpha(128)
        #expect(withNewAlpha.a == 128)
        #expect(withNewAlpha.r == 100)
        
        let withNewRed = original.withRed(200)
        #expect(withNewRed.r == 200)
        #expect(withNewRed.g == 100)
    }
    
    @Test("Color lerp")
    func lerp() {
        let black = Color.black
        let white = Color.white
        
        let mid = Color.lerp(black, white, t: 0.5)
        // Should be approximately gray (127 or 128 due to rounding)
        #expect(mid.r >= 127 && mid.r <= 128)
        #expect(mid.g >= 127 && mid.g <= 128)
        #expect(mid.b >= 127 && mid.b <= 128)
        
        // t = 0 should return first color
        let start = Color.lerp(black, white, t: 0.0)
        #expect(start.r == 0)
        
        // t = 1 should return second color
        let end = Color.lerp(black, white, t: 1.0)
        #expect(end.r == 255)
    }
    
    @Test("Color scaled")
    func scaled() {
        let color = Color(r: 100, g: 100, b: 100, a: 255)
        let brighter = color.scaled(by: 2.0)
        #expect(brighter.r == 200)
        #expect(brighter.a == 255) // Alpha unchanged
        
        let darker = color.scaled(by: 0.5)
        #expect(darker.r == 50)
    }
    
    @Test("Predefined colors")
    func predefinedColors() {
        #expect(Color.black.argb == 0xFF000000)
        #expect(Color.white.argb == 0xFFFFFFFF)
        #expect(Color.red.argb == 0xFFFF0000)
        #expect(Color.green.argb == 0xFF00FF00)
        #expect(Color.blue.argb == 0xFF0000FF)
        #expect(Color.transparent.argb == 0x00000000)
    }
    
    @Test("Color equality")
    func equality() {
        let a = Color(r: 100, g: 150, b: 200, a: 255)
        let b = Color(r: 100, g: 150, b: 200, a: 255)
        let c = Color(r: 100, g: 150, b: 201, a: 255)
        #expect(a == b)
        #expect(a != c)
    }
}
