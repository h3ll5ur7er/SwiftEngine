// LinuxPlatform - Key code translator
// Generic name for cross-platform abstraction

#if os(Linux)

/// Virtual key codes enum matching X11 keysyms
public enum VirtualKey: Int32 {
    // Arrow keys
    case left = 0xFF51       // XK_Left
    case right = 0xFF53      // XK_Right
    case up = 0xFF52         // XK_Up
    case down = 0xFF54       // XK_Down
    
    // Special keys
    case escape = 0xFF1B     // XK_Escape
    case space = 0x0020      // XK_space
    case enter = 0xFF0D      // XK_Return
    case tab = 0xFF09        // XK_Tab
    case backspace = 0xFF08  // XK_BackSpace
    case delete = 0xFFFF     // XK_Delete
    
    // Modifiers
    case shift = 0xFFE1      // XK_Shift_L
    case control = 0xFFE3    // XK_Control_L
    case alt = 0xFFE9        // XK_Alt_L
    
    // Letters (lowercase ASCII)
    case a = 0x61, b = 0x62, c = 0x63, d = 0x64, e = 0x65
    case f = 0x66, g = 0x67, h = 0x68, i = 0x69, j = 0x6A
    case k = 0x6B, l = 0x6C, m = 0x6D, n = 0x6E, o = 0x6F
    case p = 0x70, q = 0x71, r = 0x72, s = 0x73, t = 0x74
    case u = 0x75, v = 0x76, w = 0x77, x = 0x78, y = 0x79
    case z = 0x7A
    
    // Numbers (ASCII)
    case num0 = 0x30, num1 = 0x31, num2 = 0x32, num3 = 0x33, num4 = 0x34
    case num5 = 0x35, num6 = 0x36, num7 = 0x37, num8 = 0x38, num9 = 0x39
    
    // Function keys
    case f1 = 0xFFBE, f2 = 0xFFBF, f3 = 0xFFC0, f4 = 0xFFC1
    case f5 = 0xFFC2, f6 = 0xFFC3, f7 = 0xFFC4, f8 = 0xFFC5
    case f9 = 0xFFC6, f10 = 0xFFC7, f11 = 0xFFC8, f12 = 0xFFC9
}

/// Translates X11 keysyms to VirtualKey enum
public struct KeyCodeTranslator: Sendable {
    public init() {}
    
    /// Translate an X11 keysym to VirtualKey
    public func translate(_ keysym: Int32) -> VirtualKey? {
        let normalized: Int32
        switch keysym {
        case 0x41...0x5A:
            normalized = keysym + 0x20  // Convert A-Z to a-z
        case 0xFFE2:
            normalized = VirtualKey.shift.rawValue    // XK_Shift_R
        case 0xFFE4:
            normalized = VirtualKey.control.rawValue  // XK_Control_R
        case 0xFFEA, 0xFE03:
            normalized = VirtualKey.alt.rawValue      // XK_Alt_R, XK_ISO_Level3_Shift (AltGr)
        case 0xFF8D:
            normalized = VirtualKey.enter.rawValue    // XK_KP_Enter
        default:
            normalized = keysym
        }
        return VirtualKey(rawValue: normalized)
    }
}

#endif
