@preconcurrency import WinSDK

/// Wrapper to pass non-Sendable C types across actor boundaries
struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

/// Win32 Window abstraction
@MainActor
public final class Window {
    // nonisolated(unsafe) so deinit can access it
    nonisolated(unsafe) var hwnd: HWND?
    private(set) var width: Int32 = 0
    private(set) var height: Int32 = 0
    private(set) var shouldClose: Bool = false
    
    private let backbuffer: Backbuffer
    private let input: Input
    
    // Mouse capture state
    private(set) public var isMouseCaptured: Bool = false
    
    // Callbacks
    var onResize: ((Int32, Int32) -> Void)?
    var onClose: (() -> Void)?
    
    // Class name storage (must outlive window)
    private var classNameStorage: [WCHAR] = []
    
    public init(backbuffer: Backbuffer, input: Input) {
        self.backbuffer = backbuffer
        self.input = input
    }
    
    nonisolated deinit {
        if let hwnd = hwnd {
            DestroyWindow(hwnd)
        }
    }
    
    /// Create and show the window
    public func create(title: String, width: Int32, height: Int32) -> Bool {
        self.width = width
        self.height = height
        
        let hInstance = GetModuleHandleW(nil)
        
        // Store class name
        classNameStorage = Array("SwiftEngineWindow".utf16) + [0]
        
        var wc = WNDCLASSEXW()
        wc.cbSize = UINT(MemoryLayout<WNDCLASSEXW>.size)
        wc.lpfnWndProc = windowProc
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
        
        // Store self pointer for window proc
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
        
        // Initialize backbuffer to client size
        var rc = RECT()
        GetClientRect(createdHwnd, &rc)
        backbuffer.resize(width: rc.right - rc.left, height: rc.bottom - rc.top)
        
        return true
    }
    
    /// Process pending window messages
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
    
    /// Set window title
    public func setTitle(_ title: String) {
        guard let hwnd else { return }
        let titleChars: [WCHAR] = Array(title.utf16) + [0]
        _ = titleChars.withUnsafeBufferPointer { SetWindowTextW(hwnd, $0.baseAddress) }
    }
    
    /// Capture the mouse cursor (locks it to the window center for FPS-style look)
    public func captureMouse() {
        guard let hwnd, !isMouseCaptured else { return }
        isMouseCaptured = true
        
        // Hide cursor
        _ = ShowCursor(false)
        
        // Capture mouse input
        _ = SetCapture(hwnd)
        
        // Move cursor to window center and notify input
        let centerX = width / 2
        let centerY = height / 2
        centerCursor()
        input.setMouseCaptured(true, centerX: centerX, centerY: centerY)
    }
    
    /// Release the mouse cursor
    public func releaseMouse() {
        guard isMouseCaptured else { return }
        isMouseCaptured = false
        
        // Show cursor
        _ = ShowCursor(true)
        
        // Release capture
        _ = ReleaseCapture()
        
        input.setMouseCaptured(false)
    }
    
    /// Toggle mouse capture state
    public func toggleMouseCapture() {
        if isMouseCaptured {
            releaseMouse()
        } else {
            captureMouse()
        }
    }
    
    /// Center the cursor in the window (used for FPS-style mouse look)
    private func centerCursor() {
        guard let hwnd else { return }
        var pt = POINT(x: width / 2, y: height / 2)
        _ = ClientToScreen(hwnd, &pt)
        _ = SetCursorPos(pt.x, pt.y)
    }
    
    // MARK: - Internal Message Handling
    
    fileprivate func handleMessage(_ msg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT? {
        switch msg {
        case UINT(WM_CLOSE):
            // User requested to close the window (clicked X, Alt+F4, etc.)
            // Signal that we should close, then let DefWindowProc handle destruction
            shouldClose = true
            onClose?()
            // Fall through to default handling which calls DestroyWindow
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
            backbuffer.resize(width: newWidth, height: newHeight)
            onResize?(newWidth, newHeight)
            return 0
            
        case UINT(WM_MOUSEMOVE):
            let x = Int32(Int16(truncatingIfNeeded: lParam & 0xFFFF))
            let y = Int32(Int16(truncatingIfNeeded: (lParam >> 16) & 0xFFFF))
            input.setMousePosition(x: x, y: y)
            
            // When captured, recenter the cursor after processing movement
            if isMouseCaptured {
                let centerX = width / 2
                let centerY = height / 2
                // Only recenter if we've moved significantly from center
                if x != centerX || y != centerY {
                    centerCursor()
                }
            }
            return 0
            
        case UINT(WM_LBUTTONDOWN):
            input.setMouseButtonState(.left, down: true)
            return 0
            
        case UINT(WM_LBUTTONUP):
            input.setMouseButtonState(.left, down: false)
            return 0
            
        case UINT(WM_RBUTTONDOWN):
            input.setMouseButtonState(.right, down: true)
            return 0
            
        case UINT(WM_RBUTTONUP):
            input.setMouseButtonState(.right, down: false)
            return 0
            
        case UINT(WM_MBUTTONDOWN):
            input.setMouseButtonState(.middle, down: true)
            return 0
            
        case UINT(WM_MBUTTONUP):
            input.setMouseButtonState(.middle, down: false)
            return 0
            
        case UINT(WM_KEYDOWN):
            if let key = Input.keyFromVirtualKey(Int32(wParam)) {
                input.setKeyState(key, down: true)
            }
            return 0
            
        case UINT(WM_KEYUP):
            if let key = Input.keyFromVirtualKey(Int32(wParam)) {
                input.setKeyState(key, down: false)
            }
            return 0
            
        case UINT(WM_PAINT):
            var ps = PAINTSTRUCT()
            let hdc = BeginPaint(hwnd, &ps)
            backbuffer.present(to: hdc)
            EndPaint(hwnd, &ps)
            return 0
            
        default:
            return nil
        }
    }
}

// MARK: - Window Procedure

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

fileprivate func windowProc(hwnd: HWND?, msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT {
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
