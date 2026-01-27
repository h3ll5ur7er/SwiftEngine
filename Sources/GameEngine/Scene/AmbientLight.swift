import Foundation

/// A component that represents ambient light in the scene
/// There should typically only be one ambient light per scene
@MainActor
public final class AmbientLight: Component {
    
    /// The current ambient light instance
    private static var _current: AmbientLight?
    
    /// The active ambient light in the scene
    public static var current: AmbientLight? {
        _current?.isEnabled == true ? _current : nil
    }
    
    /// Default ambient intensity when no AmbientLight component exists
    public static let defaultIntensity: Float = 0.1
    
    /// Ambient light intensity (0 to 1)
    public var intensity: Float = 0.3 {
        didSet { intensity = max(0, min(1, intensity)) }
    }
    
    /// Ambient light color (tints all surfaces)
    public var color: Color = .white
    
    public required init() {
        super.init()
    }
    
    /// Convenience initializer with intensity
    public convenience init(intensity: Float, color: Color = .white) {
        self.init()
        self.intensity = intensity
        self.color = color
    }
    
    public override func onEnable() {
        super.onEnable()
        AmbientLight._current = self
    }
    
    public override func onDisable() {
        super.onDisable()
        if AmbientLight._current === self {
            AmbientLight._current = nil
        }
    }
    
    public override func onDestroy() {
        super.onDestroy()
        if AmbientLight._current === self {
            AmbientLight._current = nil
        }
    }
    
    /// Get the effective ambient intensity (uses default if no component)
    public static var effectiveIntensity: Float {
        current?.intensity ?? defaultIntensity
    }
    
    /// Get the effective ambient color
    public static var effectiveColor: Color {
        current?.color ?? .white
    }
    
    /// Calculate ambient contribution for a base color
    public func calculateAmbient(baseColor: Color) -> Color {
        Color(
            r: UInt8(Float(baseColor.r) * intensity * Float(color.r) / 255),
            g: UInt8(Float(baseColor.g) * intensity * Float(color.g) / 255),
            b: UInt8(Float(baseColor.b) * intensity * Float(color.b) / 255),
            a: baseColor.a
        )
    }
}
