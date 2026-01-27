import Foundation


/// Simple BMP image loader
/// Supports uncompressed 24-bit and 32-bit BMP files
public enum BMPLoader {
    
    /// Load a BMP file and return a Texture
    public static func load(from path: String) -> Texture? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("BMPLoader: Failed to read file at \(path)")
            return nil
        }
        return load(from: data)
    }
    
    /// Load a BMP from data
    public static func load(from data: Data) -> Texture? {
        guard data.count > 54 else {
            print("BMPLoader: File too small to be a valid BMP")
            return nil
        }
        
        // Check BMP signature
        guard data[0] == 0x42, data[1] == 0x4D else { // "BM"
            print("BMPLoader: Invalid BMP signature")
            return nil
        }
        
        // Read header
        let pixelDataOffset = readUInt32(data, offset: 10)
        let dibHeaderSize = readUInt32(data, offset: 14)
        
        // Read DIB header (BITMAPINFOHEADER or later)
        guard dibHeaderSize >= 40 else {
            print("BMPLoader: Unsupported DIB header size: \(dibHeaderSize)")
            return nil
        }
        
        let width = Int(readInt32(data, offset: 18))
        let height = Int(readInt32(data, offset: 22))
        let bitsPerPixel = readUInt16(data, offset: 28)
        let compression = readUInt32(data, offset: 30)
        
        // Check for supported formats
        guard compression == 0 || compression == 3 else {
            print("BMPLoader: Unsupported compression: \(compression)")
            return nil
        }
        
        guard bitsPerPixel == 24 || bitsPerPixel == 32 else {
            print("BMPLoader: Unsupported bits per pixel: \(bitsPerPixel)")
            return nil
        }
        
        // Handle negative height (top-down image)
        let isTopDown = height < 0
        let absHeight = abs(height)
        
        // Calculate row stride (rows are padded to 4-byte boundaries)
        let bytesPerPixel = Int(bitsPerPixel) / 8
        let rowSize = (width * bytesPerPixel + 3) & ~3  // Round up to 4 bytes
        
        // Create texture
        var pixels = [UInt8](repeating: 255, count: width * absHeight * 4)
        
        for row in 0..<absHeight {
            // BMP stores rows bottom-to-top by default
            let srcRow = isTopDown ? row : (absHeight - 1 - row)
            let srcOffset = Int(pixelDataOffset) + srcRow * rowSize
            
            for col in 0..<width {
                let srcIdx = srcOffset + col * bytesPerPixel
                let dstIdx = (row * width + col) * 4
                
                guard srcIdx + bytesPerPixel <= data.count else { continue }
                
                // BMP stores BGR(A)
                let b = data[srcIdx]
                let g = data[srcIdx + 1]
                let r = data[srcIdx + 2]
                let a: UInt8 = bytesPerPixel == 4 ? data[srcIdx + 3] : 255
                
                pixels[dstIdx] = r
                pixels[dstIdx + 1] = g
                pixels[dstIdx + 2] = b
                pixels[dstIdx + 3] = a
            }
        }
        
        return Texture(width: width, height: absHeight, pixels: pixels)
    }
    
    // MARK: - Private Helpers
    
    private static func readUInt16(_ data: Data, offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }
    
    private static func readUInt32(_ data: Data, offset: Int) -> UInt32 {
        UInt32(data[offset]) |
        (UInt32(data[offset + 1]) << 8) |
        (UInt32(data[offset + 2]) << 16) |
        (UInt32(data[offset + 3]) << 24)
    }
    
    private static func readInt32(_ data: Data, offset: Int) -> Int32 {
        Int32(bitPattern: readUInt32(data, offset: offset))
    }
}
