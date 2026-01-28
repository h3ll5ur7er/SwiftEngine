/// Platform-agnostic backbuffer for software rendering
/// Uses PlatformInterface to get concrete platform types
@MainActor
public final class Backbuffer {
    /// The underlying platform-specific backbuffer
    internal let platformBackbuffer: PlatformBackbuffer
    
    /// Current backbuffer width
    public var width: Int32 { platformBackbuffer.width }
    
    /// Current backbuffer height
    public var height: Int32 { platformBackbuffer.height }
    
    /// Raw pixel buffer (ARGB format, 0xAARRGGBB)
    public var bits: UnsafeMutablePointer<UInt32>? {
        platformBackbuffer.pixels
    }
    
    /// Total pixel count
    public var pixelCount: Int { platformBackbuffer.pixelCount }
    
    public init() {
        self.platformBackbuffer = PlatformInterface.createBackbuffer()
    }
    
    /// Resize the backbuffer (destroys current contents)
    public func resize(width: Int32, height: Int32) {
        platformBackbuffer.resize(width: width, height: height)
    }
}
