// LinuxPlatform - Software rendering backbuffer
// Generic name for cross-platform abstraction

#if os(Linux)
import Glibc

// X11 type definitions (minimal subset needed)
public typealias Display = OpaquePointer
public typealias XID = UInt
public typealias Drawable = XID
public typealias GC = OpaquePointer
public typealias Visual = OpaquePointer

// XImage structure (simplified)
public struct XImage {
    public var width: Int32
    public var height: Int32
    public var xoffset: Int32
    public var format: Int32
    public var data: UnsafeMutablePointer<CChar>?
    public var byte_order: Int32
    public var bitmap_unit: Int32
    public var bitmap_bit_order: Int32
    public var bitmap_pad: Int32
    public var depth: Int32
    public var bytes_per_line: Int32
    public var bits_per_pixel: Int32
    public var red_mask: UInt
    public var green_mask: UInt
    public var blue_mask: UInt
    public var obdata: UnsafeMutablePointer<CChar>?
    // Function pointers omitted - we won't call them directly
}

// X11 function declarations
@_silgen_name("XCreateImage")
func XCreateImage(
    _ display: Display?,
    _ visual: Visual?,
    _ depth: UInt32,
    _ format: Int32,
    _ offset: Int32,
    _ data: UnsafeMutablePointer<CChar>?,
    _ width: UInt32,
    _ height: UInt32,
    _ bitmap_pad: Int32,
    _ bytes_per_line: Int32
) -> UnsafeMutablePointer<XImage>?

@_silgen_name("XDestroyImage")
func XDestroyImage(_ image: UnsafeMutablePointer<XImage>?) -> Int32

@_silgen_name("XPutImage")
func XPutImage(
    _ display: Display?,
    _ drawable: Drawable,
    _ gc: GC?,
    _ image: UnsafeMutablePointer<XImage>?,
    _ src_x: Int32,
    _ src_y: Int32,
    _ dest_x: Int32,
    _ dest_y: Int32,
    _ width: UInt32,
    _ height: UInt32
) -> Int32

@_silgen_name("XDefaultVisual")
func XDefaultVisual(_ display: Display?, _ screen: Int32) -> Visual?

@_silgen_name("XDefaultDepth")
func XDefaultDepth(_ display: Display?, _ screen: Int32) -> Int32

/// X11-based software rendering backbuffer
@MainActor
public final class Backbuffer {
    public private(set) var width: Int32 = 0
    public private(set) var height: Int32 = 0
    
    nonisolated(unsafe) private var pixelData: UnsafeMutablePointer<UInt32>?
    nonisolated(unsafe) private var ximage: UnsafeMutablePointer<XImage>?
    nonisolated(unsafe) internal var display: Display?
    nonisolated(unsafe) internal var visual: Visual?
    private var depth: Int32 = 24
    
    /// Raw pixel buffer (ARGB format, 0xAARRGGBB)
    public var pixels: UnsafeMutablePointer<UInt32>? {
        pixelData
    }
    
    /// Total pixel count
    public var pixelCount: Int { Int(width * height) }
    
    public init() {}
    
    deinit { destroy() }
    
    nonisolated func destroy() {
        if let ximage = ximage {
            // XDestroyImage frees the data pointer too
            _ = XDestroyImage(ximage)
        }
        ximage = nil
        pixelData = nil
    }
    
    /// Set the X11 display connection (called by Window)
    internal func setDisplay(_ display: Display?, visual: Visual?, depth: Int32) {
        self.display = display
        self.visual = visual
        self.depth = depth
    }
    
    /// Resize the backbuffer (destroys current contents)
    public func resize(width: Int32, height: Int32) {
        destroy()
        self.width = max(1, width)
        self.height = max(1, height)
        
        guard let display = display, let visual = visual else { return }
        
        // Allocate pixel data (4 bytes per pixel for BGRA) with malloc,
        // because XDestroyImage releases it with free()
        let dataSize = Int(self.width * self.height) * 4
        guard let raw = calloc(dataSize, 1) else { return }
        let data = raw.assumingMemoryBound(to: CChar.self)
        
        // Create XImage
        let ZPixmap: Int32 = 2  // X11 ZPixmap format constant
        ximage = XCreateImage(
            display,
            visual,
            UInt32(depth),
            ZPixmap,
            0,
            data,
            UInt32(self.width),
            UInt32(self.height),
            32,
            Int32(self.width) * 4
        )
        
        if ximage != nil {
            pixelData = UnsafeMutableRawPointer(data).assumingMemoryBound(to: UInt32.self)
        } else {
            free(data)
        }
    }
    
    /// Present to an X11 drawable
    public func present(drawable: Drawable, gc: GC?) {
        guard let display = display, let ximage = ximage else { return }
        _ = XPutImage(display, drawable, gc, ximage, 0, 0, 0, 0, UInt32(width), UInt32(height))
    }
}

#endif
