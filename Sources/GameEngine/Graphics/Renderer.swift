/// High-level renderer that manages the backbuffer
@MainActor
public final class Renderer {
    private let backbuffer: Backbuffer
    
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
    
    /// Clear the entire backbuffer with a solid color
    public func clear(_ color: Color) {
        guard let bits = backbuffer.bits else { return }
        let count = backbuffer.pixelCount
        let argb = color.argb
        for i in 0..<count {
            bits[i] = argb
        }
    }
    
    /// Access to raw pixel buffer for advanced operations
    var rawBuffer: UnsafeMutablePointer<UInt32>? {
        backbuffer.bits
    }
    
    var pixelCount: Int {
        backbuffer.pixelCount
    }
}
