/// Keyboard key codes abstraction
public enum Key: Int, CaseIterable, Sendable {
    // Arrow keys
    case left
    case right
    case up
    case down
    
    // Special keys
    case escape
    case space
    case enter
    case tab
    case backspace
    case delete
    
    // Modifier keys
    case shift
    case control
    case alt
    
    // Letter keys
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    
    // Number keys
    case num0, num1, num2, num3, num4
    case num5, num6, num7, num8, num9
    
    // Function keys
    case f1, f2, f3, f4, f5, f6
    case f7, f8, f9, f10, f11, f12
}
