import Foundation

/// A component that represents a directional light source (like the sun)
@MainActor
public final class DirectionalLight: Component {
    
    /// All active directional lights in the scene
    private static var activeLights: [DirectionalLight] = []
    
    /// The primary directional light
    public static var main: DirectionalLight? {
        activeLights.first { $0.isEnabled }
    }
    
    /// All enabled directional lights
    public static var all: [DirectionalLight] {
        activeLights.filter { $0.isEnabled }
    }
    
    /// Light direction (normalized, pointing towards the light source)
    public var direction: Vec3d = Vec3d(0.5, 1.0, 0.3).normalized {
        didSet { direction = direction.normalized }
    }
    
    /// Light color
    public var color: Color = .white
    
    /// Light intensity (0 to 1+, can be > 1 for HDR)
    public var intensity: Float = 1.0
    
    /// Whether this light casts shadows (for future implementation)
    public var castsShadows: Bool = false
    
    public required init() {
        super.init()
    }
    
    /// Convenience initializer with direction
    public convenience init(direction: Vec3d, intensity: Float = 1.0) {
        self.init()
        self.direction = direction.normalized
        self.intensity = intensity
    }
    
    public override func onEnable() {
        super.onEnable()
        if !DirectionalLight.activeLights.contains(where: { $0 === self }) {
            DirectionalLight.activeLights.append(self)
        }
    }
    
    public override func onDisable() {
        super.onDisable()
        DirectionalLight.activeLights.removeAll { $0 === self }
    }
    
    public override func onDestroy() {
        super.onDestroy()
        DirectionalLight.activeLights.removeAll { $0 === self }
    }
    
    /// Calculate the light contribution at a surface with given normal
    public func calculateLighting(normal: Vec3d) -> Float {
        let nDotL = max(0, normal.dot(direction))
        return nDotL * intensity
    }
    
    /// Calculate the lit color for a surface
    public func calculateLitColor(baseColor: Color, normal: Vec3d) -> Color {
        let lightContribution = calculateLighting(normal: normal)
        return Color(
            r: UInt8(min(255, Float(baseColor.r) * lightContribution * Float(color.r) / 255)),
            g: UInt8(min(255, Float(baseColor.g) * lightContribution * Float(color.g) / 255)),
            b: UInt8(min(255, Float(baseColor.b) * lightContribution * Float(color.b) / 255)),
            a: baseColor.a
        )
    }
}
