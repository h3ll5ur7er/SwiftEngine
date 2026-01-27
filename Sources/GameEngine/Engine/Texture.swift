import Foundation

/// Texture filtering mode
public enum TextureFilter: Sendable {
    /// Nearest neighbor (pixelated)
    case point
    /// Bilinear filtering (smooth)
    case bilinear
}

/// Texture wrap mode
public enum TextureWrap: Sendable {
    /// Repeat the texture
    case `repeat`
    /// Clamp to edge pixels
    case clamp
    /// Mirror the texture
    case mirror
}

/// A 2D texture that can be sampled
public final class Texture: @unchecked Sendable {
    
    /// Width in pixels
    public let width: Int
    
    /// Height in pixels
    public let height: Int
    
    /// Raw pixel data (RGBA, 4 bytes per pixel)
    public private(set) var pixels: [UInt8]
    
    /// Filtering mode
    public var filterMode: TextureFilter = .bilinear
    
    /// Horizontal wrap mode
    public var wrapModeU: TextureWrap = .repeat
    
    /// Vertical wrap mode
    public var wrapModeV: TextureWrap = .repeat
    
    // MARK: - Initialization
    
    /// Create an empty texture
    public init(width: Int, height: Int) {
        self.width = max(1, width)
        self.height = max(1, height)
        self.pixels = [UInt8](repeating: 255, count: width * height * 4)
    }
    
    /// Create a texture from pixel data
    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = max(1, width)
        self.height = max(1, height)
        self.pixels = pixels
    }
    
    /// Create a solid color texture
    public init(color: Color, width: Int = 1, height: Int = 1) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: width * height * 4)
        fill(with: color)
    }
    
    // MARK: - Static Textures
    
    /// 1x1 white texture
    public static let white = Texture(color: .white)
    
    /// 1x1 black texture
    public static let black = Texture(color: .black)
    
    /// 1x1 normal map (flat surface pointing up)
    public static let normalFlat = Texture(color: Color(r: 128, g: 128, b: 255))
    
    /// Checkerboard pattern texture
    public static func checkerboard(size: Int = 8, color1: Color = .white, color2: Color = .black) -> Texture {
        let tex = Texture(width: size * 2, height: size * 2)
        for y in 0..<tex.height {
            for x in 0..<tex.width {
                let isEven = ((x / size) + (y / size)) % 2 == 0
                tex.setPixel(x: x, y: y, color: isEven ? color1 : color2)
            }
        }
        return tex
    }
    
    /// Gradient texture (horizontal)
    public static func gradientH(from: Color, to: Color, width: Int = 256) -> Texture {
        let tex = Texture(width: width, height: 1)
        for x in 0..<width {
            let t = Float(x) / Float(width - 1)
            let color = from.lerp(to: to, t: t)
            tex.setPixel(x: x, y: 0, color: color)
        }
        return tex
    }
    
    // MARK: - Pixel Access
    
    /// Get pixel color at integer coordinates
    public func getPixel(x: Int, y: Int) -> Color {
        let wx = wrapCoordinate(x, size: width, mode: wrapModeU)
        let wy = wrapCoordinate(y, size: height, mode: wrapModeV)
        let idx = (wy * width + wx) * 4
        
        guard idx >= 0 && idx + 3 < pixels.count else {
            return .black
        }
        
        return Color(r: pixels[idx], g: pixels[idx + 1], b: pixels[idx + 2], a: pixels[idx + 3])
    }
    
    /// Set pixel color at integer coordinates
    public func setPixel(x: Int, y: Int, color: Color) {
        guard x >= 0 && x < width && y >= 0 && y < height else { return }
        let idx = (y * width + x) * 4
        pixels[idx] = color.r
        pixels[idx + 1] = color.g
        pixels[idx + 2] = color.b
        pixels[idx + 3] = color.a
    }
    
    /// Fill entire texture with a color
    public func fill(with color: Color) {
        for y in 0..<height {
            for x in 0..<width {
                setPixel(x: x, y: y, color: color)
            }
        }
    }
    
    // MARK: - Sampling
    
    /// Sample the texture at UV coordinates (0-1 range)
    public func sample(u: Float, v: Float) -> Color {
        switch filterMode {
        case .point:
            return samplePoint(u: u, v: v)
        case .bilinear:
            return sampleBilinear(u: u, v: v)
        }
    }
    
    /// Point/nearest neighbor sampling
    private func samplePoint(u: Float, v: Float) -> Color {
        let x = Int(u * Float(width))
        let y = Int(v * Float(height))
        return getPixel(x: x, y: y)
    }
    
    /// Bilinear filtered sampling
    private func sampleBilinear(u: Float, v: Float) -> Color {
        let fx = u * Float(width) - 0.5
        let fy = v * Float(height) - 0.5
        
        let x0 = Int(floor(fx))
        let y0 = Int(floor(fy))
        let x1 = x0 + 1
        let y1 = y0 + 1
        
        let tx = fx - Float(x0)
        let ty = fy - Float(y0)
        
        let c00 = getPixel(x: x0, y: y0)
        let c10 = getPixel(x: x1, y: y0)
        let c01 = getPixel(x: x0, y: y1)
        let c11 = getPixel(x: x1, y: y1)
        
        // Bilinear interpolation
        let c0 = c00.lerp(to: c10, t: tx)
        let c1 = c01.lerp(to: c11, t: tx)
        return c0.lerp(to: c1, t: ty)
    }
    
    // MARK: - Helpers
    
    private func wrapCoordinate(_ coord: Int, size: Int, mode: TextureWrap) -> Int {
        switch mode {
        case .repeat:
            var c = coord % size
            if c < 0 { c += size }
            return c
        case .clamp:
            return max(0, min(size - 1, coord))
        case .mirror:
            var c = coord % (size * 2)
            if c < 0 { c += size * 2 }
            if c >= size { c = size * 2 - 1 - c }
            return max(0, min(size - 1, c))
        }
    }
}
