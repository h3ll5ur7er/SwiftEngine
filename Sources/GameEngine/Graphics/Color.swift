/// ARGB color (0xAARRGGBB format)
public struct Color: Equatable, Hashable, Sendable {
    public let argb: UInt32
    
    public init(argb: UInt32) {
        self.argb = argb
    }
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.argb = (UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
    }
    
    public init(gray: UInt8, a: UInt8 = 255) {
        self.init(r: gray, g: gray, b: gray, a: a)
    }
    
    // MARK: - Component Access
    
    public var a: UInt8 { UInt8((argb >> 24) & 0xFF) }
    public var r: UInt8 { UInt8((argb >> 16) & 0xFF) }
    public var g: UInt8 { UInt8((argb >> 8) & 0xFF) }
    public var b: UInt8 { UInt8(argb & 0xFF) }
    
    // MARK: - Component Modification
    
    public func withAlpha(_ a: UInt8) -> Color {
        Color(r: r, g: g, b: b, a: a)
    }
    
    public func withRed(_ r: UInt8) -> Color {
        Color(r: r, g: g, b: b, a: a)
    }
    
    public func withGreen(_ g: UInt8) -> Color {
        Color(r: r, g: g, b: b, a: a)
    }
    
    public func withBlue(_ b: UInt8) -> Color {
        Color(r: r, g: g, b: b, a: a)
    }
    
    // MARK: - Color Operations
    
    /// Linearly interpolate between two colors
    public static func lerp(_ a: Color, _ b: Color, t: Float) -> Color {
        let t = max(0, min(1, t))
        let invT = 1 - t
        return Color(
            r: UInt8(Float(a.r) * invT + Float(b.r) * t),
            g: UInt8(Float(a.g) * invT + Float(b.g) * t),
            b: UInt8(Float(a.b) * invT + Float(b.b) * t),
            a: UInt8(Float(a.a) * invT + Float(b.a) * t)
        )
    }
    
    /// Multiply color by a scalar (brightness)
    public func scaled(by factor: Float) -> Color {
        Color(
            r: UInt8(min(255, Float(r) * factor)),
            g: UInt8(min(255, Float(g) * factor)),
            b: UInt8(min(255, Float(b) * factor)),
            a: a
        )
    }
    
    /// Make the color lighter by a percentage (0.0 - 1.0)
    public func lighter(by amount: Float) -> Color {
        let amount = max(0, min(1, amount))
        return Color(
            r: UInt8(min(255, Float(r) + (255 - Float(r)) * amount)),
            g: UInt8(min(255, Float(g) + (255 - Float(g)) * amount)),
            b: UInt8(min(255, Float(b) + (255 - Float(b)) * amount)),
            a: a
        )
    }
    
    /// Make the color darker by a percentage (0.0 - 1.0)
    public func darker(by amount: Float) -> Color {
        let amount = max(0, min(1, amount))
        return Color(
            r: UInt8(Float(r) * (1 - amount)),
            g: UInt8(Float(g) * (1 - amount)),
            b: UInt8(Float(b) * (1 - amount)),
            a: a
        )
    }
    
    // MARK: - Common Colors
    
    public static let transparent = Color(argb: 0x00000000)
    public static let clear = transparent
    public static let black = Color(argb: 0xFF000000)
    public static let white = Color(argb: 0xFFFFFFFF)
    public static let red = Color(argb: 0xFFFF0000)
    public static let green = Color(argb: 0xFF00FF00)
    public static let blue = Color(argb: 0xFF0000FF)
    public static let yellow = Color(argb: 0xFFFFFF00)
    public static let cyan = Color(argb: 0xFF00FFFF)
    public static let magenta = Color(argb: 0xFFFF00FF)
    public static let orange = Color(argb: 0xFFFF8000)
    public static let purple = Color(argb: 0xFF8000FF)
    public static let pink = Color(argb: 0xFFFF80C0)
    
    // Grays
    public static let darkGray = Color(gray: 30)
    public static let gray = Color(gray: 128)
    public static let lightGray = Color(gray: 192)
    
    // Material-ish colors
    public static let androidGreen = Color(argb: 0xFF3DDC84)
    public static let vsCodeDark = Color(argb: 0xFF1E1E1E)
    public static let cornflowerBlue = Color(r: 100, g: 149, b: 237)
    public static let steelBlue = Color(r: 70, g: 130, b: 180)
}

extension Color: CustomStringConvertible {
    public var description: String {
        "Color(r: \(r), g: \(g), b: \(b), a: \(a))"
    }
}
