/// Platform-agnostic window wrapper
/// Uses PlatformInterface to get concrete platform types
@MainActor
public final class Window {
    private let platformWindow: PlatformWindow
    private let backbuffer: Backbuffer
    private let input: Input
    
    public var width: Int32 { platformWindow.width }
    public var height: Int32 { platformWindow.height }
    public var shouldClose: Bool { platformWindow.shouldClose }
    public var isMouseCaptured: Bool { platformWindow.isMouseCaptured }
    
    // Callbacks
    public var onResize: ((Int32, Int32) -> Void)? {
        didSet { platformWindow.onResize = onResize }
    }
    public var onClose: (() -> Void)? {
        didSet { platformWindow.onClose = onClose }
    }
    
    public init(backbuffer: Backbuffer, input: Input) {
        self.backbuffer = backbuffer
        self.input = input
        self.platformWindow = PlatformInterface.createWindow()
        
        // Set up callbacks to route to input system
        setupInputCallbacks()
    }
    
    private func setupInputCallbacks() {
        // Key events
        platformWindow.onKeyEvent = { [weak self] virtualKey, isDown in
            guard let self else { return }
            if let key = PlatformInterface.translateKeyCode(virtualKey) {
                self.input.setKeyState(key, down: isDown)
            }
        }
        
        // Mouse move events
        platformWindow.onMouseMove = { [weak self] x, y in
            guard let self else { return }
            self.input.setMousePosition(x: x, y: y)
        }
        
        // Mouse button events
        platformWindow.onMouseButton = { [weak self] buttonIndex, isDown in
            guard let self else { return }
            if let button = PlatformInterface.mouseButtonFromPlatformIndex(buttonIndex) {
                self.input.setMouseButtonState(button, down: isDown)
            }
        }
        
        // Resize events - also resize backbuffer
        platformWindow.onResize = { [weak self] width, height in
            guard let self else { return }
            self.backbuffer.resize(width: width, height: height)
            self.onResize?(width, height)
        }
    }
    
    /// Create and show the window
    public func create(title: String, width: Int32, height: Int32) -> Bool {
        // Link backbuffer to platform window
        platformWindow.setBackbuffer(backbuffer.platformBackbuffer)
        
        let result = platformWindow.create(title: title, width: width, height: height)
        
        if result {
            // Initialize backbuffer to window size
            backbuffer.resize(width: platformWindow.width, height: platformWindow.height)
        }
        
        return result
    }
    
    /// Process pending window messages
    public func pollEvents() {
        platformWindow.pollEvents()
    }
    
    /// Present the backbuffer to the window
    public func present() {
        platformWindow.present()
    }
    
    /// Set window title
    public func setTitle(_ title: String) {
        platformWindow.setTitle(title)
    }
    
    /// Capture the mouse cursor (locks it to the window center for FPS-style look)
    public func captureMouse() {
        platformWindow.captureMouse()
        let centerX = width / 2
        let centerY = height / 2
        input.setMouseCaptured(true, centerX: centerX, centerY: centerY)
    }
    
    /// Release the mouse cursor
    public func releaseMouse() {
        platformWindow.releaseMouse()
        input.setMouseCaptured(false)
    }
    
    /// Toggle mouse capture state
    public func toggleMouseCapture() {
        if isMouseCaptured {
            releaseMouse()
        } else {
            captureMouse()
        }
    }
}
