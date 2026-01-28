// WindowsPlatform - Key code translator
// Generic name for cross-platform abstraction

#if os(Windows)
@preconcurrency import WinSDK

/// Virtual key codes enum matching Windows VK_* constants
public enum VirtualKey: Int32 {
    case left = 0x25       // VK_LEFT
    case right = 0x27      // VK_RIGHT
    case up = 0x26         // VK_UP
    case down = 0x28       // VK_DOWN
    case escape = 0x1B     // VK_ESCAPE
    case space = 0x20      // VK_SPACE
    case enter = 0x0D      // VK_RETURN
    case tab = 0x09        // VK_TAB
    case backspace = 0x08  // VK_BACK
    case delete = 0x2E     // VK_DELETE
    case shift = 0x10      // VK_SHIFT
    case control = 0x11    // VK_CONTROL
    case alt = 0x12        // VK_MENU
    
    // Letters A-Z (0x41-0x5A)
    case a = 0x41, b = 0x42, c = 0x43, d = 0x44, e = 0x45
    case f = 0x46, g = 0x47, h = 0x48, i = 0x49, j = 0x4A
    case k = 0x4B, l = 0x4C, m = 0x4D, n = 0x4E, o = 0x4F
    case p = 0x50, q = 0x51, r = 0x52, s = 0x53, t = 0x54
    case u = 0x55, v = 0x56, w = 0x57, x = 0x58, y = 0x59
    case z = 0x5A
    
    // Numbers 0-9 (0x30-0x39)
    case num0 = 0x30, num1 = 0x31, num2 = 0x32, num3 = 0x33, num4 = 0x34
    case num5 = 0x35, num6 = 0x36, num7 = 0x37, num8 = 0x38, num9 = 0x39
    
    // Function keys (0x70-0x7B)
    case f1 = 0x70, f2 = 0x71, f3 = 0x72, f4 = 0x73
    case f5 = 0x74, f6 = 0x75, f7 = 0x76, f8 = 0x77
    case f9 = 0x78, f10 = 0x79, f11 = 0x7A, f12 = 0x7B
}

/// Translates Windows virtual key codes to VirtualKey enum
public struct KeyCodeTranslator: Sendable {
    public init() {}
    
    /// Translate a Windows virtual key code to VirtualKey
    public func translate(_ vk: Int32) -> VirtualKey? {
        VirtualKey(rawValue: vk)
    }
}

#endif
