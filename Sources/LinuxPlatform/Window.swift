// LinuxPlatform - Native window
// Generic name for cross-platform abstraction

#if os(Linux)
import Glibc

// Additional X11 type definitions
public typealias Window_t = XID  // X11 Window type (renamed to avoid conflict)
public typealias Colormap = XID
public typealias Atom = UInt
public typealias KeySym = UInt
public typealias Time = UInt

// X11 event structures
public struct XKeyEvent {
    public var type: Int32
    public var serial: UInt
    public var send_event: Int32
    public var display: Display?
    public var window: Window_t
    public var root: Window_t
    public var subwindow: Window_t
    public var time: Time
    public var x, y: Int32
    public var x_root, y_root: Int32
    public var state: UInt32
    public var keycode: UInt32
    public var same_screen: Int32
}

public struct XButtonEvent {
    public var type: Int32
    public var serial: UInt
    public var send_event: Int32
    public var display: Display?
    public var window: Window_t
    public var root: Window_t
    public var subwindow: Window_t
    public var time: Time
    public var x, y: Int32
    public var x_root, y_root: Int32
    public var state: UInt32
    public var button: UInt32
    public var same_screen: Int32
}

public struct XMotionEvent {
    public var type: Int32
    public var serial: UInt
    public var send_event: Int32
    public var display: Display?
    public var window: Window_t
    public var root: Window_t
    public var subwindow: Window_t
    public var time: Time
    public var x, y: Int32
    public var x_root, y_root: Int32
    public var state: UInt32
    public var is_hint: CChar
    public var same_screen: Int32
}

public struct XConfigureEvent {
    public var type: Int32
    public var serial: UInt
    public var send_event: Int32
    public var display: Display?
    public var event: Window_t
    public var window: Window_t
    public var x, y: Int32
    public var width, height: Int32
    public var border_width: Int32
    public var above: Window_t
    public var override_redirect: Int32
}

public struct XClientMessageEvent {
    public var type: Int32
    public var serial: UInt
    public var send_event: Int32
    public var display: Display?
    public var window: Window_t
    public var message_type: Atom
    public var format: Int32
    public var data: (Int, Int, Int, Int, Int)  // union, simplified
}

// XEvent union (simplified - we use raw memory)
public struct XEvent {
    public var type: Int32
    public var padding: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
    
    public init() {
        type = 0
        padding = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    }
}

// X11 function declarations
@_silgen_name("XOpenDisplay")
func XOpenDisplay(_ name: UnsafePointer<CChar>?) -> Display?

@_silgen_name("XCloseDisplay")
func XCloseDisplay(_ display: Display?) -> Int32

@_silgen_name("XDefaultScreen")
func XDefaultScreen(_ display: Display?) -> Int32

@_silgen_name("XRootWindow")
func XRootWindow(_ display: Display?, _ screen: Int32) -> Window_t

@_silgen_name("XDefaultGC")
func XDefaultGC(_ display: Display?, _ screen: Int32) -> GC?

@_silgen_name("XCreateSimpleWindow")
func XCreateSimpleWindow(
    _ display: Display?,
    _ parent: Window_t,
    _ x: Int32, _ y: Int32,
    _ width: UInt32, _ height: UInt32,
    _ border_width: UInt32,
    _ border: UInt,
    _ background: UInt
) -> Window_t

@_silgen_name("XDestroyWindow")
func XDestroyWindow(_ display: Display?, _ window: Window_t) -> Int32

@_silgen_name("XMapWindow")
func XMapWindow(_ display: Display?, _ window: Window_t) -> Int32

@_silgen_name("XSelectInput")
func XSelectInput(_ display: Display?, _ window: Window_t, _ mask: Int) -> Int32

@_silgen_name("XStoreName")
func XStoreName(_ display: Display?, _ window: Window_t, _ name: UnsafePointer<CChar>?) -> Int32

@_silgen_name("XPending")
func XPending(_ display: Display?) -> Int32

@_silgen_name("XNextEvent")
func XNextEvent(_ display: Display?, _ event: UnsafeMutablePointer<XEvent>?) -> Int32

@_silgen_name("XFlush")
func XFlush(_ display: Display?) -> Int32

@_silgen_name("XLookupKeysym")
func XLookupKeysym(_ event: UnsafeMutablePointer<XKeyEvent>?, _ index: Int32) -> KeySym

@_silgen_name("XInternAtom")
func XInternAtom(_ display: Display?, _ name: UnsafePointer<CChar>?, _ only_if_exists: Int32) -> Atom

@_silgen_name("XSetWMProtocols")
func XSetWMProtocols(_ display: Display?, _ window: Window_t, _ protocols: UnsafeMutablePointer<Atom>?, _ count: Int32) -> Int32

@_silgen_name("XGrabPointer")
func XGrabPointer(
    _ display: Display?,
    _ window: Window_t,
    _ owner_events: Int32,
    _ event_mask: UInt32,
    _ pointer_mode: Int32,
    _ keyboard_mode: Int32,
    _ confine_to: Window_t,
    _ cursor: UInt,
    _ time: Time
) -> Int32

@_silgen_name("XUngrabPointer")
func XUngrabPointer(_ display: Display?, _ time: Time) -> Int32

@_silgen_name("XWarpPointer")
func XWarpPointer(
    _ display: Display?,
    _ src_window: Window_t,
    _ dest_window: Window_t,
    _ src_x: Int32, _ src_y: Int32,
    _ src_width: UInt32, _ src_height: UInt32,
    _ dest_x: Int32, _ dest_y: Int32
) -> Int32

// Cursor-related types and functions
public typealias Pixmap = XID
public typealias Cursor = XID

public struct XColor {
    public var pixel: UInt
    public var red, green, blue: UInt16
    public var flags: CChar
    public var pad: CChar
    
    public init() {
        pixel = 0
        red = 0; green = 0; blue = 0
        flags = 0; pad = 0
    }
}

@_silgen_name("XCreatePixmap")
func XCreatePixmap(
    _ display: Display?,
    _ drawable: Drawable,
    _ width: UInt32,
    _ height: UInt32,
    _ depth: UInt32
) -> Pixmap

@_silgen_name("XFreePixmap")
func XFreePixmap(_ display: Display?, _ pixmap: Pixmap) -> Int32

@_silgen_name("XCreatePixmapCursor")
func XCreatePixmapCursor(
    _ display: Display?,
    _ source: Pixmap,
    _ mask: Pixmap,
    _ foreground: UnsafeMutablePointer<XColor>?,
    _ background: UnsafeMutablePointer<XColor>?,
    _ x: UInt32,
    _ y: UInt32
) -> Cursor

@_silgen_name("XFreeCursor")
func XFreeCursor(_ display: Display?, _ cursor: Cursor) -> Int32

@_silgen_name("XDefineCursor")
func XDefineCursor(_ display: Display?, _ window: Window_t, _ cursor: Cursor) -> Int32

@_silgen_name("XUndefineCursor")
func XUndefineCursor(_ display: Display?, _ window: Window_t) -> Int32

// Event type constants
let KeyPress: Int32 = 2
let KeyRelease: Int32 = 3
let ButtonPress: Int32 = 4
let ButtonRelease: Int32 = 5
let MotionNotify: Int32 = 6
let ConfigureNotify: Int32 = 22
let ClientMessage: Int32 = 33

// Event mask constants
let KeyPressMask: Int = 1 << 0
let KeyReleaseMask: Int = 1 << 1
let ButtonPressMask: Int = 1 << 2
let ButtonReleaseMask: Int = 1 << 3
let PointerMotionMask: Int = 1 << 6
let StructureNotifyMask: Int = 1 << 17
let ExposureMask: Int = 1 << 15

/// Mouse button indices
public enum MouseButtonIndex: Int32, Sendable {
    case left = 0
    case right = 1
    case middle = 2
}

/// X11 window implementation
@MainActor
public final class Window {
    nonisolated(unsafe) private var display: Display?
    nonisolated(unsafe) private var window: Window_t = 0
    nonisolated(unsafe) private var gc: GC?
    nonisolated(unsafe) private var wmDeleteWindow: Atom = 0
    nonisolated(unsafe) private var invisibleCursor: Cursor = 0
    private var screen: Int32 = 0
    
    public private(set) var width: Int32 = 0
    public private(set) var height: Int32 = 0
    public private(set) var shouldClose: Bool = false
    public private(set) var isMouseCaptured: Bool = false
    
    internal var backbuffer: Backbuffer?
    
    // Callbacks
    public var onResize: ((Int32, Int32) -> Void)?
    public var onClose: (() -> Void)?
    public var onKeyEvent: ((Int32, Bool) -> Void)?
    public var onMouseMove: ((Int32, Int32) -> Void)?
    public var onMouseButton: ((Int32, Bool) -> Void)?
    
    /// Native window handle
    public var nativeHandle: Window_t { window }
    
    public init() {}
    
    nonisolated deinit {
        if let display = display {
            if invisibleCursor != 0 {
                _ = XFreeCursor(display, invisibleCursor)
            }
            if window != 0 {
                _ = XDestroyWindow(display, window)
            }
            _ = XCloseDisplay(display)
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
        
        // Open X11 display
        display = XOpenDisplay(nil)
        guard let display = display else {
            print("Failed to open X display")
            return false
        }
        
        screen = XDefaultScreen(display)
        let rootWindow = XRootWindow(display, screen)
        gc = XDefaultGC(display, screen)
        
        // Create window
        window = XCreateSimpleWindow(
            display,
            rootWindow,
            0, 0,
            UInt32(width), UInt32(height),
            1,
            0,  // border
            0   // background (black)
        )
        
        guard window != 0 else {
            print("Failed to create X window")
            return false
        }
        
        // Set window title
        _ = title.withCString { XStoreName(display, window, $0) }

        // Select events
        let eventMask = KeyPressMask | KeyReleaseMask | ButtonPressMask | 
                       ButtonReleaseMask | PointerMotionMask | 
                       StructureNotifyMask | ExposureMask
        _ = XSelectInput(display, window, eventMask)
        
        // Handle window close
        wmDeleteWindow = "WM_DELETE_WINDOW".withCString { XInternAtom(display, $0, 0) }
        withUnsafeMutablePointer(to: &wmDeleteWindow) { ptr in
            _ = XSetWMProtocols(display, window, ptr, 1)
        }
        
        // Setup backbuffer with display info
        if let backbuffer = backbuffer {
            let visual = XDefaultVisual(display, screen)
            let depth = XDefaultDepth(display, screen)
            backbuffer.setDisplay(display, visual: visual, depth: depth)
        }
        
        // Show window
        _ = XMapWindow(display, window)
        _ = XFlush(display)
        
        // Create invisible cursor for mouse capture
        createInvisibleCursor()
        
        // Trigger initial resize
        onResize?(width, height)
        
        return true
    }
    
    /// Create an invisible cursor for mouse capture
    private func createInvisibleCursor() {
        guard let display = display else { return }
        
        // Create a 1x1 pixmap
        let pixmap = XCreatePixmap(display, window, 1, 1, 1)
        guard pixmap != 0 else { return }
        
        var fgColor = XColor()
        var bgColor = XColor()
        invisibleCursor = XCreatePixmapCursor(display, pixmap, pixmap, &fgColor, &bgColor, 0, 0)
        
        _ = XFreePixmap(display, pixmap)
    }
    
    /// Process pending window events
    public func pollEvents() {
        guard let display = display else { return }
        
        while XPending(display) > 0 {
            var event = XEvent()
            _ = XNextEvent(display, &event)
            handleEvent(&event)
        }
    }
    
    private func handleEvent(_ event: inout XEvent) {
        switch event.type {
        case KeyPress, KeyRelease:
            let isPress = event.type == KeyPress
            withUnsafePointer(to: &event) { ptr in
                let keyEvent = UnsafeRawPointer(ptr).assumingMemoryBound(to: XKeyEvent.self)
                var mutableKeyEvent = keyEvent.pointee
                let keysym = XLookupKeysym(&mutableKeyEvent, 0)
                onKeyEvent?(Int32(keysym), isPress)
            }
            
        case ButtonPress, ButtonRelease:
            let isPress = event.type == ButtonPress
            withUnsafePointer(to: &event) { ptr in
                let buttonEvent = UnsafeRawPointer(ptr).assumingMemoryBound(to: XButtonEvent.self).pointee
                // X11 buttons: 1=left, 2=middle, 3=right
                let buttonIndex: Int32
                switch buttonEvent.button {
                case 1: buttonIndex = MouseButtonIndex.left.rawValue
                case 2: buttonIndex = MouseButtonIndex.middle.rawValue
                case 3: buttonIndex = MouseButtonIndex.right.rawValue
                default: return
                }
                onMouseButton?(buttonIndex, isPress)
            }
            
        case MotionNotify:
            withUnsafePointer(to: &event) { ptr in
                let motionEvent = UnsafeRawPointer(ptr).assumingMemoryBound(to: XMotionEvent.self).pointee
                onMouseMove?(motionEvent.x, motionEvent.y)
                
                if isMouseCaptured {
                    let centerX = width / 2
                    let centerY = height / 2
                    if motionEvent.x != centerX || motionEvent.y != centerY {
                        centerCursor()
                    }
                }
            }
            
        case ConfigureNotify:
            withUnsafePointer(to: &event) { ptr in
                let configEvent = UnsafeRawPointer(ptr).assumingMemoryBound(to: XConfigureEvent.self).pointee
                if configEvent.width != width || configEvent.height != height {
                    width = configEvent.width
                    height = configEvent.height
                    onResize?(width, height)
                }
            }
            
        case ClientMessage:
            withUnsafePointer(to: &event) { ptr in
                let clientEvent = UnsafeRawPointer(ptr).assumingMemoryBound(to: XClientMessageEvent.self).pointee
                if UInt(clientEvent.data.0) == wmDeleteWindow {
                    shouldClose = true
                    onClose?()
                }
            }
            
        default:
            break
        }
    }
    
    /// Present the backbuffer to the window
    public func present() {
        guard let display = display, let backbuffer = backbuffer, let gc = gc else { return }
        backbuffer.present(drawable: window, gc: gc)
        _ = XFlush(display)
    }
    
    /// Set window title
    public func setTitle(_ title: String) {
        guard let display = display, window != 0 else { return }
        _ = title.withCString { XStoreName(display, window, $0) }
    }
    
    /// Capture the mouse cursor
    public func captureMouse() {
        guard let display = display, !isMouseCaptured else { return }
        isMouseCaptured = true
        
        // Hide cursor
        if invisibleCursor != 0 {
            _ = XDefineCursor(display, window, invisibleCursor)
        }
        
        let GrabModeAsync: Int32 = 1
        let PointerMotionMask: UInt32 = 1 << 6
        let ButtonPressMask: UInt32 = 1 << 2
        let ButtonReleaseMask: UInt32 = 1 << 3
        
        // Try to grab pointer (may fail in X11 forwarding, but cursor hiding should still work)
        _ = XGrabPointer(
            display, window, 1,
            PointerMotionMask | ButtonPressMask | ButtonReleaseMask,
            GrabModeAsync, GrabModeAsync,
            window, invisibleCursor, 0  // Use invisible cursor in grab, CurrentTime
        )
        centerCursor()
        _ = XFlush(display)
    }
    
    /// Release the mouse cursor
    public func releaseMouse() {
        guard let display = display, isMouseCaptured else { return }
        isMouseCaptured = false
        
        // Release grab
        _ = XUngrabPointer(display, 0)  // CurrentTime
        
        // Restore default cursor
        _ = XUndefineCursor(display, window)
        _ = XFlush(display)
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
        guard let display = display, window != 0 else { return }
        _ = XWarpPointer(display, 0, window, 0, 0, 0, 0, width / 2, height / 2)
        _ = XFlush(display)
    }
}

#endif
