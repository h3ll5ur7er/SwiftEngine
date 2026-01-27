@preconcurrency import WinSDK

/// DIB-based backbuffer for software rendering
@MainActor
public final class Backbuffer {
    private(set) var width: Int32 = 0
    private(set) var height: Int32 = 0
    
    nonisolated(unsafe) private var memDC: HDC?
    nonisolated(unsafe) private var dib: HBITMAP?
    nonisolated(unsafe) private var oldObj: HGDIOBJ?
    nonisolated(unsafe) private var _bits: UnsafeMutableRawPointer?
    
    /// Raw pixel buffer (ARGB format, 0xAARRGGBB)
    var bits: UnsafeMutablePointer<UInt32>? {
        _bits?.assumingMemoryBound(to: UInt32.self)
    }
    
    /// Total pixel count
    var pixelCount: Int { Int(width * height) }
    
    public init() {}
    
    deinit { destroy() }
    
    nonisolated func destroy() {
        if let dc = memDC {
            if let old = oldObj { _ = SelectObject(dc, old) }
            oldObj = nil
            if let bmp = dib { _ = DeleteObject(bmp) }
            dib = nil
            _ = DeleteDC(dc)
        }
        memDC = nil
        _bits = nil
    }
    
    /// Resize the backbuffer (destroys current contents)
    func resize(width: Int32, height: Int32) {
        destroy()
        self.width = max(1, width)
        self.height = max(1, height)
        
        guard let mem = CreateCompatibleDC(nil) else { return }
        memDC = mem
        
        var bmi = BITMAPINFO()
        bmi.bmiHeader.biSize = DWORD(MemoryLayout<BITMAPINFOHEADER>.size)
        bmi.bmiHeader.biWidth = self.width
        bmi.bmiHeader.biHeight = -self.height // top-down
        bmi.bmiHeader.biPlanes = 1
        bmi.bmiHeader.biBitCount = 32
        bmi.bmiHeader.biCompression = DWORD(BI_RGB)
        
        var outBits: UnsafeMutableRawPointer? = nil
        let hbm = CreateDIBSection(mem, &bmi, UINT(DIB_RGB_COLORS), &outBits, nil, 0)
        guard let hbm, let outBits else {
            destroy()
            return
        }
        
        dib = hbm
        _bits = outBits
        oldObj = SelectObject(mem, HGDIOBJ(hbm))
    }
    
    /// Blit backbuffer contents to the given device context
    func present(to hdc: HDC?) {
        guard let hdc, let mem = memDC else { return }
        _ = BitBlt(hdc, 0, 0, width, height, mem, 0, 0, DWORD(SRCCOPY))
    }
}
