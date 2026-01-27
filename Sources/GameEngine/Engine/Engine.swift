@preconcurrency import WinSDK

/// Main game engine class
@MainActor
public final class Engine {
    // Configuration
    private let config: EngineConfig
    private let baseTitle: String
    
    // Core systems
    private let backbuffer: Backbuffer
    private let window: Window
    public let input: Input
    public let renderer: Renderer
    
    // Scene management
    private var currentScene: Scene?
    
    // Timing
    private var isRunning: Bool = false
    private var frameCount: UInt64 = 0
    private var totalTime: Double = 0
    private var lastFrameTime: UInt64 = 0
    private var fpsUpdateTime: UInt64 = 0
    private var fpsFrameCount: Int = 0
    private var currentFps: Double = 0
    
    public init(config: EngineConfig) {
        self.config = config
        self.baseTitle = config.title
        
        self.backbuffer = Backbuffer()
        self.input = Input()
        self.window = Window(backbuffer: backbuffer, input: input)
        self.renderer = Renderer(backbuffer: backbuffer)
    }
    
    /// Load a scene (unloads current scene if any)
    public func loadScene(_ scene: Scene) {
        // Unload current scene
        if let current = currentScene {
            current.onDeactivate(engine: self)
            current.onUnload(engine: self)
        }
        
        // Load new scene
        currentScene = scene
        scene.onLoad(engine: self)
        scene.onActivate(engine: self)
    }
    
    /// Unload the current scene
    public func unloadScene() {
        if let current = currentScene {
            current.onDeactivate(engine: self)
            current.onUnload(engine: self)
            currentScene = nil
        }
    }
    
    /// Start the engine main loop
    public func run() {
        guard window.create(title: config.title, width: config.width, height: config.height) else {
            print("Failed to create window")
            return
        }
        
        isRunning = true
        lastFrameTime = GetTickCount64()
        fpsUpdateTime = lastFrameTime
        
        // Main loop
        while isRunning && !window.shouldClose {
            // Calculate delta time
            let now = GetTickCount64()
            let deltaMs = now - lastFrameTime
            let deltaTime = Double(deltaMs) / 1000.0
            lastFrameTime = now
            totalTime += deltaTime
            
            // Update FPS counter
            fpsFrameCount += 1
            let fpsElapsed = now - fpsUpdateTime
            if fpsElapsed >= 1000 {
                currentFps = Double(fpsFrameCount) * 1000.0 / Double(fpsElapsed)
                fpsFrameCount = 0
                fpsUpdateTime = now
                
                if config.showFpsInTitle {
                    let fpsInt = Int(currentFps)
                    let fpsFrac = Int((currentFps - Double(fpsInt)) * 10)
                    window.setTitle("\(baseTitle) - \(fpsInt).\(fpsFrac) FPS")
                }
            }
            
            // Process input
            input.beginFrame()
            window.pollEvents()
            
            // Check for escape key
            if input.isKeyPressed(.escape) {
                stop()
                break
            }
            
            // Create frame context
            let frameContext = FrameContext(
                deltaTime: deltaTime,
                totalTime: totalTime,
                frameCount: frameCount,
                fps: currentFps
            )
            
            // Update scene
            currentScene?.update(context: frameContext, input: input)
            
            // Render
            Primitives.currentRenderer = renderer
            let renderContext = RenderContext(renderer: renderer)
            currentScene?.render(context: renderContext)
            Primitives.currentRenderer = nil
            
            // Present
            window.present()
            
            frameCount += 1
            
            // Frame rate limiting
            if let targetFps = config.targetFps, targetFps > 0 {
                let frameTimeMs = UInt32(1000 / targetFps)
                let elapsed = GetTickCount64() - now
                if elapsed < UInt64(frameTimeMs) {
                    Sleep(UInt32(UInt64(frameTimeMs) - elapsed))
                }
            } else {
                Sleep(1) // Yield to prevent 100% CPU
            }
        }
        
        // Cleanup
        unloadScene()
    }
    
    /// Stop the engine
    public func stop() {
        isRunning = false
    }
    
    /// Get current window size
    public var windowSize: (width: Int32, height: Int32) {
        (window.width, window.height)
    }
    
    /// Whether the mouse is currently captured
    public var isMouseCaptured: Bool {
        window.isMouseCaptured
    }
    
    /// Capture the mouse cursor for FPS-style controls
    public func captureMouse() {
        window.captureMouse()
    }
    
    /// Release the mouse cursor
    public func releaseMouse() {
        window.releaseMouse()
    }
    
    /// Toggle mouse capture state
    public func toggleMouseCapture() {
        window.toggleMouseCapture()
    }
}
