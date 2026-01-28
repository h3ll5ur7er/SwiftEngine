// WindowsPlatform - Native window
// Generic name for cross-platform abstraction

#if os(Windows)
@preconcurrency import WinSDK

/// Mouse button indices
public enum MouseButtonIndex: Int32, Sendable {
    case left = 0
    case right = 1
    case middle = 2
}

/// Helper to pass non-Sendable C types across actor boundaries
fileprivate struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

/// Win32 window implementation
@MainActor
public final class Window {
    nonisolated(unsafe) internal var hwnd: HWND?
    
    public private(set) var width: Int32 = 0
    public private(set) var height: Int32 = 0
    public private(set) var shouldClose: Bool = false
    public private(set) var isMouseCaptured: Bool = false
    
    internal var backbuffer: Backbuffer?
    private var classNameStorage: [WCHAR] = []
    
    // Callbacks
    public var onResize: ((Int32, Int32) -> Void)?
    public var onClose: (() -> Void)?
    public var onKeyEvent: ((Int32, Bool) -> Void)?
    public var onMouseMove: ((Int32, Int32) -> Void)?
    public var onMouseButton: ((Int32, Bool) -> Void)?
    
    /// Native window handle
    public var nativeHandle: HWND? { hwnd }
    
    public init() {}
    
    nonisolated deinit {
        if let hwnd = hwnd {
            DestroyWindow(hwnd)
        }
    }
    
    /// Set the backbuffer to use for presentation
    public func setBackbuffer(_ backbuffer: Backbuffer) {
        self.backbuffer = backbuffer
    }
    
    /// Create and show the window
    public func create(title: String, width: Int32, height: Int32) -> Bool {
        self.width = width
        self.height = height
        
        let hInstance = GetModuleHandleW(nil)
        
        classNameStorage = Array("SwiftEngineWindow".utf16) + [0]
        
        var wc = WNDCLASSEXW()
        wc.cbSize = UINT(MemoryLayout<WNDCLASSEXW>.size)
        wc.lpfnWndProc = windowsWindowProc
        wc.hInstance = hInstance
        wc.hCursor = LoadCursorW(nil, PCWSTR(bitPattern: 32512)) // IDC_ARROW
        wc.hbrBackground = HBRUSH(bitPattern: UInt(COLOR_WINDOW + 1))
        
        let registered = classNameStorage.withUnsafeBufferPointer { ptr -> Bool in
            wc.lpszClassName = ptr.baseAddress
            return RegisterClassExW(&wc) != 0
        }
        
        guard registered else {
            print("RegisterClassExW failed")
            return false
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let titleChars: [WCHAR] = Array(title.utf16) + [0]
        
        let createdHwnd = titleChars.withUnsafeBufferPointer { titlePtr in
            classNameStorage.withUnsafeBufferPointer { classPtr in
                CreateWindowExW(
                    0,
                    classPtr.baseAddress,
                    titlePtr.baseAddress,
                    DWORD(UInt32(WS_OVERLAPPEDWINDOW) | UInt32(WS_VISIBLE)),
                    Int32(CW_USEDEFAULT), Int32(CW_USEDEFAULT),
                    width, height,
                    nil, nil, hInstance, selfPtr
                )
            }
        }
        
        guard let createdHwnd else {
            print("CreateWindowExW failed")
            return false
        }
        
        hwnd = createdHwnd
        
        ShowWindow(createdHwnd, Int32(SW_SHOW))
        UpdateWindow(createdHwnd)
        
        // Get actual client size and notify
        var rc = RECT()
        GetClientRect(createdHwnd, &rc)
        let clientWidth = rc.right - rc.left
        let clientHeight = rc.bottom - rc.top
        self.width = clientWidth
        self.height = clientHeight
        onResize?(clientWidth, clientHeight)
        
        return true
    }
    
    /// Process pending window events
    public func pollEvents() {
        var msg = MSG()
        while PeekMessageW(&msg, nil, 0, 0, UINT(PM_REMOVE)) != false {
            if msg.message == UINT(WM_QUIT) {
                shouldClose = true
                break
            }
            TranslateMessage(&msg)
            DispatchMessageW(&msg)
        }
    }
    
    /// Present the backbuffer to the window
    public func present() {
        guard let hwnd else { return }
        InvalidateRect(hwnd, nil, false)
        UpdateWindow(hwnd)
    }
    
    /// Internal method called from WM_PAINT handler
    fileprivate func paintToHDC(_ hdc: HDC?) {
        guard let hdc, let backbuffer, let mem = backbuffer.memDC else { return }
        _ = BitBlt(hdc, 0, 0, width, height, mem, 0, 0, DWORD(SRCCOPY))
    }
    
    /// Set window title
    public func setTitle(_ title: String) {
        guard let hwnd else { return }
        let titleChars: [WCHAR] = Array(title.utf16) + [0]
        _ = titleChars.withUnsafeBufferPointer { SetWindowTextW(hwnd, $0.baseAddress) }
    }
    
    /// Capture the mouse cursor
    public func captureMouse() {
        guard let hwnd, !isMouseCaptured else { return }
        isMouseCaptured = true
        _ = ShowCursor(false)
        _ = SetCapture(hwnd)
        centerCursor()
    }
    
    /// Release the mouse cursor
    public func releaseMouse() {
        guard isMouseCaptured else { return }
        isMouseCaptured = false
        _ = ShowCursor(true)
        _ = ReleaseCapture()
    }
    
    /// Toggle mouse capture state
    public func toggleMouseCapture() {
        if isMouseCaptured {
            releaseMouse()
        } else {
            captureMouse()
        }
    }
    
    private func centerCursor() {
        guard let hwnd else { return }
        var pt = POINT(x: width / 2, y: height / 2)
        _ = ClientToScreen(hwnd, &pt)
        _ = SetCursorPos(pt.x, pt.y)
    }
    
    // MARK: - Message Handling
    
    fileprivate func handleMessage(_ msg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT? {
        switch msg {
        case UINT(WM_CLOSE):
            shouldClose = true
            onClose?()
            return nil
            
        case UINT(WM_DESTROY):
            shouldClose = true
            PostQuitMessage(0)
            return 0
            
        case UINT(WM_SIZE):
            let newWidth = Int32(Int16(truncatingIfNeeded: lParam & 0xFFFF))
            let newHeight = Int32(Int16(truncatingIfNeeded: (lParam >> 16) & 0xFFFF))
            width = newWidth
            height = newHeight
            onResize?(newWidth, newHeight)
            return 0
            
        case UINT(WM_MOUSEMOVE):
            let x = Int32(Int16(truncatingIfNeeded: lParam & 0xFFFF))
            let y = Int32(Int16(truncatingIfNeeded: (lParam >> 16) & 0xFFFF))
            onMouseMove?(x, y)
            if isMouseCaptured {
                let centerX = width / 2
                let centerY = height / 2
                if x != centerX || y != centerY {
                    centerCursor()
                }
            }
            return 0
            
        case UINT(WM_LBUTTONDOWN):
            onMouseButton?(MouseButtonIndex.left.rawValue, true)
            return 0
            
        case UINT(WM_LBUTTONUP):
            onMouseButton?(MouseButtonIndex.left.rawValue, false)
            return 0
            
        case UINT(WM_RBUTTONDOWN):
            onMouseButton?(MouseButtonIndex.right.rawValue, true)
            return 0
            
        case UINT(WM_RBUTTONUP):
            onMouseButton?(MouseButtonIndex.right.rawValue, false)
            return 0
            
        case UINT(WM_MBUTTONDOWN):
            onMouseButton?(MouseButtonIndex.middle.rawValue, true)
            return 0
            
        case UINT(WM_MBUTTONUP):
            onMouseButton?(MouseButtonIndex.middle.rawValue, false)
            return 0
            
        case UINT(WM_KEYDOWN):
            onKeyEvent?(Int32(wParam), true)
            return 0
            
        case UINT(WM_KEYUP):
            onKeyEvent?(Int32(wParam), false)
            return 0
            
        case UINT(WM_PAINT):
            guard let hwnd = self.hwnd else { return nil }
            var ps = PAINTSTRUCT()
            let hdc = BeginPaint(hwnd, &ps)
            paintToHDC(hdc)
            EndPaint(hwnd, &ps)
            return 0
            
        default:
            return nil
        }
    }
}

// MARK: - Window Procedure Helpers

@inline(__always)
fileprivate func setWindowPtr(_ hwnd: HWND, _ window: Window) {
    let p = Unmanaged.passUnretained(window).toOpaque()
    _ = SetWindowLongPtrW(hwnd, Int32(GWLP_USERDATA), LONG_PTR(Int(bitPattern: p)))
}

@inline(__always)
fileprivate func getWindowPtr(_ hwnd: HWND) -> Window? {
    let v = GetWindowLongPtrW(hwnd, Int32(GWLP_USERDATA))
    guard v != 0, let p = UnsafeRawPointer(bitPattern: UInt(v)) else { return nil }
    return Unmanaged<Window>.fromOpaque(p).takeUnretainedValue()
}

@inline(__always)
fileprivate func withWindow<R: Sendable>(_ body: @MainActor (Window) -> R, hwnd: HWND?) -> R? {
    guard let hwnd, let window = getWindowPtr(hwnd) else { return nil }
    return MainActor.assumeIsolated { body(window) }
}

fileprivate func windowsWindowProc(hwnd: HWND?, msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT {
    switch msg {
    case UINT(WM_NCCREATE):
        guard let rawPtr = UnsafeRawPointer(bitPattern: Int(lParam)) else {
            return DefWindowProcW(hwnd, msg, wParam, lParam)
        }
        let cs = rawPtr.assumingMemoryBound(to: CREATESTRUCTW.self).pointee
        if let p = cs.lpCreateParams, let hwnd = hwnd {
            let window = Unmanaged<Window>.fromOpaque(p).takeUnretainedValue()
            setWindowPtr(hwnd, window)
            let hwndSendable = UncheckedSendable(hwnd)
            MainActor.assumeIsolated { window.hwnd = hwndSendable.value }
        }
        return DefWindowProcW(hwnd, msg, wParam, lParam)
        
    default:
        if let result = withWindow({ $0.handleMessage(msg, wParam, lParam) }, hwnd: hwnd), let lresult = result {
            return lresult
        }
        return DefWindowProcW(hwnd, msg, wParam, lParam)
    }
}

#endif
