import Testing
@testable import GameEngine

@Suite("FrameContext Tests")
struct FrameContextTests {
    
    @Test("FrameContext initialization")
    func initialization() {
        let context = FrameContext(
            deltaTime: 0.016,
            totalTime: 1.5,
            frameCount: 100,
            fps: 60.0
        )
        
        #expect(context.deltaTime == 0.016)
        #expect(context.totalTime == 1.5)
        #expect(context.frameCount == 100)
        #expect(context.fps == 60.0)
    }
}

@Suite("EngineConfig Tests")
struct EngineConfigTests {
    
    @Test("EngineConfig default values")
    func defaultValues() {
        let config = EngineConfig()
        #expect(config.title == "Swift Engine")
        #expect(config.width == 800)
        #expect(config.height == 600)
        #expect(config.targetFps == nil)
        #expect(config.showFpsInTitle == true)
    }
    
    @Test("EngineConfig custom values")
    func customValues() {
        let config = EngineConfig(
            title: "My Game",
            width: 1920,
            height: 1080,
            targetFps: 60,
            showFpsInTitle: false
        )
        
        #expect(config.title == "My Game")
        #expect(config.width == 1920)
        #expect(config.height == 1080)
        #expect(config.targetFps == 60)
        #expect(config.showFpsInTitle == false)
    }
}
