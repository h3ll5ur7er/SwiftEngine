/// Main game engine class
@MainActor
public final class Engine {
    // Configuration
    private let config: EngineConfig
    private let baseTitle: String
    
    // Platform - using concrete types from PlatformInterface
    private let timer: PlatformTimer
    
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
    private let clock = ContinuousClock()
    private var lastFrameInstant: ContinuousClock.Instant?
    private var fpsUpdateTime: UInt64 = 0
    private var fpsFrameCount: Int = 0
    private var currentFps: Double = 0
    
    public init(config: EngineConfig) {
        self.config = config
        self.baseTitle = config.title
        
        // Create concrete platform timer
        self.timer = PlatformInterface.createTimer()
        
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
    public func run() async {
        guard window.create(title: config.title, width: config.width, height: config.height) else {
            print("Failed to create window")
            return
        }
        
        isRunning = true
        lastFrameInstant = clock.now
        fpsUpdateTime = timer.currentTimeMillis()
        
        // Main loop
        while isRunning && !window.shouldClose {
            // Calculate delta time (sub-millisecond precision)
            let frameInstant = clock.now
            let deltaTime = lastFrameInstant.map { (frameInstant - $0).seconds } ?? 0
            lastFrameInstant = frameInstant
            totalTime += deltaTime
            
            let now = timer.currentTimeMillis()
            
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
            
            // Exit immediately if window was closed during event processing
            if window.shouldClose {
                break
            }
            
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
            
            // Physics and off-main-actor game logic
            let gameObjects = (currentScene as? GameObjectScene)?.allGameObjects ?? []
            await ActorCoordinator.shared.update(deltaTime: Float(deltaTime), gameObjects: gameObjects)
            
            // Render
            Primitives.currentRenderer = renderer
            let renderContext = RenderContext(renderer: renderer)
            currentScene?.render(context: renderContext)
            Primitives.currentRenderer = nil
            
            // Present
            window.present()
            
            frameCount += 1
            
            // Let other main-actor work run (Task {} bodies, async asset load completions);
            // without a suspension point here the loop would starve them indefinitely
            await Task.yield()
            
            // Frame rate limiting
            if let targetFps = config.targetFps, targetFps > 0 {
                let frameTimeMs = UInt32(1000 / targetFps)
                let elapsed = timer.currentTimeMillis() - now
                if elapsed < UInt64(frameTimeMs) {
                    timer.sleep(milliseconds: UInt32(UInt64(frameTimeMs) - elapsed))
                }
            } else {
                timer.sleep(milliseconds: 1) // Yield to prevent 100% CPU
            }
        }
        
        // Terminate the process immediately
        // We call exitProcess directly because Swift's async runtime can block
        // indefinitely if there are global actors with pending work.
        // The OS will reclaim all resources (memory, handles, etc.)
        PlatformInterface.exitProcess(0)
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

extension Duration {
    /// The duration in seconds
    var seconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) * 1e-18
    }
}
