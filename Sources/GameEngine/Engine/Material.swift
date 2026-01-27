import Foundation

/// How the material should be rendered
public enum RenderMode: Sendable {
    /// Fully opaque rendering
    case opaque
    /// Transparent rendering with alpha blending
    case transparent
    /// Cutout rendering (alpha testing)
    case cutout
    /// Wireframe rendering (edges only)
    case wireframe
}

/// How faces should be culled
public enum CullMode: Sendable {
    /// Cull back faces (default)
    case back
    /// Cull front faces
    case front
    /// No culling (render both sides)
    case none
}

/// Shading model for the material
public enum ShadingModel: Sendable {
    /// Unlit - just shows the color/texture without lighting
    case unlit
    /// Simple flat shading per triangle
    case flat
    /// Smooth shading with interpolated normals
    case gouraud
    /// Full PBR-style shading (for future use)
    case pbr
}

/// A material defines the visual appearance of a rendered surface
public final class Material: @unchecked Sendable {
    
    // MARK: - Static Materials
    
    /// Default white material
    public static let `default` = Material(color: .white)
    
    /// Unlit white material
    public static let unlit = Material(color: .white, shadingModel: .unlit)
    
    /// Wireframe material
    public static let wireframe: Material = {
        let mat = Material(color: .white)
        mat.renderMode = .wireframe
        return mat
    }()
    
    // MARK: - Basic Properties
    
    /// Display name for the material
    public var name: String = "Material"
    
    /// Base color (albedo) of the material
    public var color: Color {
        didSet { _needsUpdate = true }
    }
    
    /// Texture for the base color (overrides color if set)
    public var mainTexture: Texture? {
        didSet { _needsUpdate = true }
    }
    
    /// Tint applied to the texture
    public var mainTextureTint: Color = .white
    
    /// UV tiling for the main texture
    public var mainTextureScale: Vec2d = Vec2d(1, 1)
    
    /// UV offset for the main texture
    public var mainTextureOffset: Vec2d = Vec2d(0, 0)
    
    // MARK: - Rendering Properties
    
    /// How the material should be rendered
    public var renderMode: RenderMode = .opaque
    
    /// Face culling mode
    public var cullMode: CullMode = .back
    
    /// Shading model
    public var shadingModel: ShadingModel = .flat
    
    /// Opacity (0 = fully transparent, 1 = fully opaque)
    public var opacity: Float = 1.0 {
        didSet { opacity = max(0, min(1, opacity)) }
    }
    
    /// Alpha cutoff threshold for cutout mode
    public var alphaCutoff: Float = 0.5
    
    // MARK: - Lighting Properties
    
    /// Roughness (0 = smooth/shiny, 1 = rough/matte)
    public var roughness: Float = 0.5 {
        didSet { roughness = max(0, min(1, roughness)) }
    }
    
    /// Metallic (0 = dielectric, 1 = metal)
    public var metallic: Float = 0.0 {
        didSet { metallic = max(0, min(1, metallic)) }
    }
    
    /// Emission color (self-illumination)
    public var emissionColor: Color = .black
    
    /// Emission intensity multiplier
    public var emissionIntensity: Float = 1.0
    
    /// Ambient occlusion strength
    public var aoStrength: Float = 1.0
    
    // MARK: - Additional Textures (for future PBR support)
    
    /// Normal map texture
    public var normalMap: Texture?
    
    /// Normal map strength
    public var normalStrength: Float = 1.0
    
    /// Roughness/metallic texture (R = roughness, G = metallic)
    public var roughnessMetallicMap: Texture?
    
    /// Emission texture
    public var emissionMap: Texture?
    
    /// Ambient occlusion texture
    public var aoMap: Texture?
    
    // MARK: - Internal
    
    private var _needsUpdate: Bool = true
    
    /// Whether the material properties have changed
    public var needsUpdate: Bool {
        get { _needsUpdate }
        set { _needsUpdate = newValue }
    }
    
    // MARK: - Initialization
    
    public init(color: Color = .white) {
        self.color = color
    }
    
    public init(color: Color, shadingModel: ShadingModel) {
        self.color = color
        self.shadingModel = shadingModel
    }
    
    public init(texture: Texture) {
        self.color = .white
        self.mainTexture = texture
    }
    
    // MARK: - Convenience Factories
    
    /// Create a solid color material
    public static func solid(_ color: Color) -> Material {
        Material(color: color)
    }
    
    /// Create a transparent material
    public static func transparent(_ color: Color, opacity: Float) -> Material {
        let mat = Material(color: color)
        mat.renderMode = .transparent
        mat.opacity = opacity
        return mat
    }
    
    /// Create an emissive/glowing material
    public static func emissive(_ color: Color, intensity: Float = 1.0) -> Material {
        let mat = Material(color: color)
        mat.emissionColor = color
        mat.emissionIntensity = intensity
        mat.shadingModel = .unlit
        return mat
    }
    
    /// Create a metallic material
    public static func metallic(_ color: Color, roughness: Float = 0.3) -> Material {
        let mat = Material(color: color)
        mat.metallic = 1.0
        mat.roughness = roughness
        return mat
    }
    
    /// Create a matte/diffuse material
    public static func matte(_ color: Color) -> Material {
        let mat = Material(color: color)
        mat.roughness = 1.0
        mat.metallic = 0.0
        return mat
    }
    
    // MARK: - Color Sampling
    
    /// Get the effective color at a UV coordinate
    public func sampleColor(at uv: Vec2d) -> Color {
        if let texture = mainTexture {
            // Apply tiling and offset
            let tiledU = uv.x * mainTextureScale.x + mainTextureOffset.x
            let tiledV = uv.y * mainTextureScale.y + mainTextureOffset.y
            let texColor = texture.sample(u: tiledU, v: tiledV)
            return texColor.blendMultiply(mainTextureTint)
        }
        return color
    }
    
    /// Get the final color with opacity applied
    public func getFinalColor(at uv: Vec2d = Vec2d(0, 0)) -> Color {
        var finalColor = sampleColor(at: uv)
        
        // Apply opacity
        if opacity < 1.0 {
            finalColor = Color(
                r: finalColor.r,
                g: finalColor.g,
                b: finalColor.b,
                a: UInt8(Float(finalColor.a) * opacity)
            )
        }
        
        return finalColor
    }
    
    // MARK: - Copying
    
    /// Create a copy of this material
    public func copy() -> Material {
        let mat = Material(color: color)
        mat.name = name
        mat.mainTexture = mainTexture
        mat.mainTextureTint = mainTextureTint
        mat.mainTextureScale = mainTextureScale
        mat.mainTextureOffset = mainTextureOffset
        mat.renderMode = renderMode
        mat.cullMode = cullMode
        mat.shadingModel = shadingModel
        mat.opacity = opacity
        mat.alphaCutoff = alphaCutoff
        mat.roughness = roughness
        mat.metallic = metallic
        mat.emissionColor = emissionColor
        mat.emissionIntensity = emissionIntensity
        mat.aoStrength = aoStrength
        mat.normalMap = normalMap
        mat.normalStrength = normalStrength
        mat.roughnessMetallicMap = roughnessMetallicMap
        mat.emissionMap = emissionMap
        mat.aoMap = aoMap
        return mat
    }
}

// MARK: - Color Blending Extension

extension Color {
    /// Multiply blend two colors
    func blendMultiply(_ other: Color) -> Color {
        Color(
            r: UInt8((Int(r) * Int(other.r)) / 255),
            g: UInt8((Int(g) * Int(other.g)) / 255),
            b: UInt8((Int(b) * Int(other.b)) / 255),
            a: UInt8((Int(a) * Int(other.a)) / 255)
        )
    }
    
    /// Alpha blend this color over another
    func blendOver(_ background: Color) -> Color {
        let srcA = Float(a) / 255.0
        let dstA = Float(background.a) / 255.0
        let outA = srcA + dstA * (1 - srcA)
        
        guard outA > 0 else { return .clear }
        
        let outR = (Float(r) * srcA + Float(background.r) * dstA * (1 - srcA)) / outA
        let outG = (Float(g) * srcA + Float(background.g) * dstA * (1 - srcA)) / outA
        let outB = (Float(b) * srcA + Float(background.b) * dstA * (1 - srcA)) / outA
        
        return Color(
            r: UInt8(min(255, max(0, outR))),
            g: UInt8(min(255, max(0, outG))),
            b: UInt8(min(255, max(0, outB))),
            a: UInt8(min(255, max(0, outA * 255)))
        )
    }
    
    /// Linearly interpolate between two colors
    func lerp(to other: Color, t: Float) -> Color {
        let t = max(0, min(1, t))
        return Color(
            r: UInt8(Float(r) + (Float(other.r) - Float(r)) * t),
            g: UInt8(Float(g) + (Float(other.g) - Float(g)) * t),
            b: UInt8(Float(b) + (Float(other.b) - Float(b)) * t),
            a: UInt8(Float(a) + (Float(other.a) - Float(a)) * t)
        )
    }
}
