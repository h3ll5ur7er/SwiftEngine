/// High-level renderer that manages the backbuffer
@MainActor
public final class Renderer {
    private let backbuffer: Backbuffer
    
    /// Per-pixel depth for 3D rendering (NDC z, smaller is closer)
    nonisolated(unsafe) private var depthBuffer: UnsafeMutablePointer<Float>?
    private var depthBufferCapacity: Int = 0
    
    /// Current backbuffer width
    public var width: Int32 { backbuffer.width }
    
    /// Current backbuffer height
    public var height: Int32 { backbuffer.height }
    
    /// Screen bounds as a Rect
    public var bounds: Rect {
        Rect(x: 0, y: 0, width: width, height: height)
    }
    
    init(backbuffer: Backbuffer) {
        self.backbuffer = backbuffer
    }
    
    deinit {
        depthBuffer?.deallocate()
    }
    
    /// Clear the entire backbuffer with a solid color
    public func clear(_ color: Color) {
        guard let bits = backbuffer.bits else { return }
        let count = backbuffer.pixelCount
        let argb = color.argb
        for i in 0..<count {
            bits[i] = argb
        }
    }
    
    /// Reset the depth buffer so following 3D draws start from an empty scene
    public func clearDepth() {
        let count = backbuffer.pixelCount
        if count > depthBufferCapacity {
            depthBuffer?.deallocate()
            depthBuffer = .allocate(capacity: count)
            depthBufferCapacity = count
        }
        depthBuffer?.update(repeating: .infinity, count: count)
    }
    
    /// Color and depth buffers for the triangle rasterizer (call clearDepth() first each frame)
    var rasterTarget: RasterTarget? {
        guard let pixels = backbuffer.bits, let depth = depthBuffer,
              depthBufferCapacity >= backbuffer.pixelCount else { return nil }
        return RasterTarget(pixels: pixels, depth: depth, width: Int(width), height: Int(height))
    }
    
    /// Access to raw pixel buffer for advanced operations
    var rawBuffer: UnsafeMutablePointer<UInt32>? {
        backbuffer.bits
    }
    
    var pixelCount: Int {
        backbuffer.pixelCount
    }
}
