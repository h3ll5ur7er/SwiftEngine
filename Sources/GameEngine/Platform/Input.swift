@preconcurrency import WinSDK

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
    
    static func keyFromVirtualKey(_ vk: Int32) -> Key? {
        switch vk {
        case VK_LEFT: return .left
        case VK_RIGHT: return .right
        case VK_UP: return .up
        case VK_DOWN: return .down
        case VK_ESCAPE: return .escape
        case VK_SPACE: return .space
        case VK_RETURN: return .enter
        case VK_TAB: return .tab
        case VK_BACK: return .backspace
        case VK_DELETE: return .delete
        case VK_SHIFT: return .shift
        case VK_CONTROL: return .control
        case VK_MENU: return .alt
        case 0x41: return .a
        case 0x42: return .b
        case 0x43: return .c
        case 0x44: return .d
        case 0x45: return .e
        case 0x46: return .f
        case 0x47: return .g
        case 0x48: return .h
        case 0x49: return .i
        case 0x4A: return .j
        case 0x4B: return .k
        case 0x4C: return .l
        case 0x4D: return .m
        case 0x4E: return .n
        case 0x4F: return .o
        case 0x50: return .p
        case 0x51: return .q
        case 0x52: return .r
        case 0x53: return .s
        case 0x54: return .t
        case 0x55: return .u
        case 0x56: return .v
        case 0x57: return .w
        case 0x58: return .x
        case 0x59: return .y
        case 0x5A: return .z
        case 0x30: return .num0
        case 0x31: return .num1
        case 0x32: return .num2
        case 0x33: return .num3
        case 0x34: return .num4
        case 0x35: return .num5
        case 0x36: return .num6
        case 0x37: return .num7
        case 0x38: return .num8
        case 0x39: return .num9
        case VK_F1: return .f1
        case VK_F2: return .f2
        case VK_F3: return .f3
        case VK_F4: return .f4
        case VK_F5: return .f5
        case VK_F6: return .f6
        case VK_F7: return .f7
        case VK_F8: return .f8
        case VK_F9: return .f9
        case VK_F10: return .f10
        case VK_F11: return .f11
        case VK_F12: return .f12
        default: return nil
        }
    }
}
