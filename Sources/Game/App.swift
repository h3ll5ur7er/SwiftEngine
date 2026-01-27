import GameEngine

/// Main entry point
@main
@MainActor
struct Main {
    static func main() {
        let config = EngineConfig(
            title: "Swift Low-Level Renderer - Overlay Demo",
            width: 1024,
            height: 768,
            targetFps: nil,  // Uncapped
            showFpsInTitle: true
        )
        
        let engine = Engine(config: config)
        // engine.loadScene(OverlayDemoScene())
        engine.loadScene(GameObjectDemoScene())
        engine.run()
    }
}
