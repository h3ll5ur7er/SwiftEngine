/// Handles keyboard and mouse input state
@MainActor
public final class Input {
    // Current frame state
    private var currentKeyStates: [Key: Bool] = [:]
    private var previousKeyStates: [Key: Bool] = [:]
    
    private var currentMouseStates: [MouseButton: Bool] = [:]
    private var previousMouseStates: [MouseButton: Bool] = [:]
    
    private(set) var mouseX: Int32 = 0
    private(set) var mouseY: Int32 = 0
    
    // Mouse capture and delta tracking
    private(set) public var isMouseCaptured: Bool = false
    private(set) public var mouseDeltaX: Int32 = 0
    private(set) public var mouseDeltaY: Int32 = 0
    private var lastMouseX: Int32 = 0
    private var lastMouseY: Int32 = 0
    private var captureCenter: (x: Int32, y: Int32) = (0, 0)
    
    public init() {}
    
    // MARK: - Frame Update
    
    /// Call at the start of each frame to update previous states
    func beginFrame() {
        previousKeyStates = currentKeyStates
        previousMouseStates = currentMouseStates
        
        // Reset mouse delta at frame start
        mouseDeltaX = 0
        mouseDeltaY = 0
    }
    
    // MARK: - Keyboard Queries
    
    /// Returns true if the key is currently held down
    public func isKeyDown(_ key: Key) -> Bool {
        currentKeyStates[key] ?? false
    }
    
    /// Returns true if the key is not pressed
    public func isKeyUp(_ key: Key) -> Bool {
        !isKeyDown(key)
    }
    
    /// Returns true only on the frame the key was first pressed
    public func isKeyPressed(_ key: Key) -> Bool {
        let current = currentKeyStates[key] ?? false
        let previous = previousKeyStates[key] ?? false
        return current && !previous
    }
    
    /// Returns true only on the frame the key was released
    public func isKeyReleased(_ key: Key) -> Bool {
        let current = currentKeyStates[key] ?? false
        let previous = previousKeyStates[key] ?? false
        return !current && previous
    }
    
    // MARK: - Mouse Queries
    
    /// Returns the current mouse position
    public func getMousePosition() -> (x: Int32, y: Int32) {
        (mouseX, mouseY)
    }
    
    /// Returns the mouse movement delta since last frame
    public func getMouseDelta() -> (x: Int32, y: Int32) {
        (mouseDeltaX, mouseDeltaY)
    }
    
    /// Returns true if the mouse button is currently held down
    public func isMouseButtonDown(_ button: MouseButton) -> Bool {
        currentMouseStates[button] ?? false
    }
    
    /// Returns true if the mouse button is not pressed
    public func isMouseButtonUp(_ button: MouseButton) -> Bool {
        !isMouseButtonDown(button)
    }
    
    /// Returns true only on the frame the mouse button was first pressed
    public func isMouseButtonPressed(_ button: MouseButton) -> Bool {
        let current = currentMouseStates[button] ?? false
        let previous = previousMouseStates[button] ?? false
        return current && !previous
    }
    
    /// Returns true only on the frame the mouse button was released
    public func isMouseButtonReleased(_ button: MouseButton) -> Bool {
        let current = currentMouseStates[button] ?? false
        let previous = previousMouseStates[button] ?? false
        return !current && previous
    }
    
    // MARK: - Internal State Updates (called from Window message handling)
    
    func setKeyState(_ key: Key, down: Bool) {
        currentKeyStates[key] = down
    }
    
    func setMouseButtonState(_ button: MouseButton, down: Bool) {
        currentMouseStates[button] = down
    }
    
    func setMousePosition(x: Int32, y: Int32) {
        // Calculate delta from last position
        if isMouseCaptured {
            // When captured, calculate delta from center
            mouseDeltaX += x - captureCenter.x
            mouseDeltaY += y - captureCenter.y
        } else {
            // Normal mode: calculate delta from last position
            mouseDeltaX += x - lastMouseX
            mouseDeltaY += y - lastMouseY
        }
        
        lastMouseX = x
        lastMouseY = y
        mouseX = x
        mouseY = y
    }
    
    func setMouseCaptured(_ captured: Bool, centerX: Int32 = 0, centerY: Int32 = 0) {
        isMouseCaptured = captured
        if captured {
            captureCenter = (centerX, centerY)
            lastMouseX = centerX
            lastMouseY = centerY
        }
        mouseDeltaX = 0
        mouseDeltaY = 0
    }
    
    // MARK: - Virtual Key Translation
    
    /// Translate a platform virtual key code to Key enum
    public func keyFromVirtualKey(_ vk: Int32) -> Key? {
        PlatformInterface.translateKeyCode(vk)
    }
    
    /// Static method for convenience
    public static func keyFromVirtualKey(_ vk: Int32) -> Key? {
        MainActor.assumeIsolated {
            PlatformInterface.translateKeyCode(vk)
        }
    }
}
