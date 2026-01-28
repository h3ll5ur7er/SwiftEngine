/// PlatformInterface - Unified interface to platform-specific implementations
/// Uses #if os(...) to redirect to the correct platform module at compile time
/// This provides a clean API while maintaining native performance by using concrete types

#if os(Windows)
import WindowsPlatform
#elseif os(Linux)
import LinuxPlatform
#endif

// MARK: - Type Aliases for Clean API

#if os(Windows)
/// Platform-specific window type
public typealias PlatformWindow = WindowsPlatform.Window

/// Platform-specific backbuffer type
public typealias PlatformBackbuffer = WindowsPlatform.Backbuffer

/// Platform-specific timer type
public typealias PlatformTimer = WindowsPlatform.Timer

/// Platform-specific key code translator type
public typealias PlatformKeyCodeTranslator = WindowsPlatform.KeyCodeTranslator

/// Platform-specific virtual key type
public typealias PlatformVirtualKey = WindowsPlatform.VirtualKey

/// Platform-specific mouse button index type
public typealias PlatformMouseButtonIndex = WindowsPlatform.MouseButtonIndex

#elseif os(Linux)
/// Platform-specific window type
public typealias PlatformWindow = LinuxPlatform.Window

/// Platform-specific backbuffer type
public typealias PlatformBackbuffer = LinuxPlatform.Backbuffer

/// Platform-specific timer type
public typealias PlatformTimer = LinuxPlatform.Timer

/// Platform-specific key code translator type
public typealias PlatformKeyCodeTranslator = LinuxPlatform.KeyCodeTranslator

/// Platform-specific virtual key type
public typealias PlatformVirtualKey = LinuxPlatform.VirtualKey

/// Platform-specific mouse button index type
public typealias PlatformMouseButtonIndex = LinuxPlatform.MouseButtonIndex
#endif

// MARK: - PlatformInterface

/// Central access point for platform-specific functionality
/// All engine code should go through this interface
@MainActor
public enum PlatformInterface {
    
    // MARK: - Factory Methods
    
    /// Create a new platform window
    public static func createWindow() -> PlatformWindow {
        #if os(Windows)
        return WindowsPlatform.Window()
        #elseif os(Linux)
        return LinuxPlatform.Window()
        #else
        fatalError("Platform not implemented")
        #endif
    }
    
    /// Create a new platform backbuffer
    public static func createBackbuffer() -> PlatformBackbuffer {
        #if os(Windows)
        return WindowsPlatform.Backbuffer()
        #elseif os(Linux)
        return LinuxPlatform.Backbuffer()
        #else
        fatalError("Platform not implemented")
        #endif
    }
    
    /// Create a new platform timer
    public static func createTimer() -> PlatformTimer {
        #if os(Windows)
        return WindowsPlatform.Timer()
        #elseif os(Linux)
        return LinuxPlatform.Timer()
        #else
        fatalError("Platform not implemented")
        #endif
    }
    
    /// Create a new key code translator
    public static func createKeyCodeTranslator() -> PlatformKeyCodeTranslator {
        #if os(Windows)
        return WindowsPlatform.KeyCodeTranslator()
        #elseif os(Linux)
        return LinuxPlatform.KeyCodeTranslator()
        #else
        fatalError("Platform not implemented")
        #endif
    }
    
    // MARK: - Utilities
    
    /// Exit the process immediately
    public static func exitProcess(_ code: Int32) -> Never {
        #if os(Windows)
        WindowsPlatform.Platform.exitProcess(code)
        #elseif os(Linux)
        LinuxPlatform.Platform.exitProcess(code)
        #else
        fatalError("Platform not implemented")
        #endif
    }
    
    /// Translate a platform virtual key code to engine Key
    public static func translateKeyCode(_ vk: Int32) -> Key? {
        #if os(Windows) || os(Linux)
        guard let platformKey = PlatformVirtualKey(rawValue: vk) else { return nil }
        return keyFromPlatformKey(platformKey)
        #else
        return nil
        #endif
    }
    
    #if os(Windows) || os(Linux)
    /// Convert platform virtual key to engine Key
    public static func keyFromPlatformKey(_ vk: PlatformVirtualKey) -> Key {
        switch vk {
        case .left: return .left
        case .right: return .right
        case .up: return .up
        case .down: return .down
        case .escape: return .escape
        case .space: return .space
        case .enter: return .enter
        case .tab: return .tab
        case .backspace: return .backspace
        case .delete: return .delete
        case .shift: return .shift
        case .control: return .control
        case .alt: return .alt
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .f: return .f
        case .g: return .g
        case .h: return .h
        case .i: return .i
        case .j: return .j
        case .k: return .k
        case .l: return .l
        case .m: return .m
        case .n: return .n
        case .o: return .o
        case .p: return .p
        case .q: return .q
        case .r: return .r
        case .s: return .s
        case .t: return .t
        case .u: return .u
        case .v: return .v
        case .w: return .w
        case .x: return .x
        case .y: return .y
        case .z: return .z
        case .num0: return .num0
        case .num1: return .num1
        case .num2: return .num2
        case .num3: return .num3
        case .num4: return .num4
        case .num5: return .num5
        case .num6: return .num6
        case .num7: return .num7
        case .num8: return .num8
        case .num9: return .num9
        case .f1: return .f1
        case .f2: return .f2
        case .f3: return .f3
        case .f4: return .f4
        case .f5: return .f5
        case .f6: return .f6
        case .f7: return .f7
        case .f8: return .f8
        case .f9: return .f9
        case .f10: return .f10
        case .f11: return .f11
        case .f12: return .f12
        }
    }
    #endif
}

// MARK: - Mouse Button Mapping

extension PlatformInterface {
    /// Convert platform mouse button index to engine MouseButton
    public static func mouseButtonFromPlatformIndex(_ index: Int32) -> MouseButton? {
        #if os(Windows) || os(Linux)
        switch index {
        case PlatformMouseButtonIndex.left.rawValue: return .left
        case PlatformMouseButtonIndex.right.rawValue: return .right
        case PlatformMouseButtonIndex.middle.rawValue: return .middle
        default: return nil
        }
        #else
        return nil
        #endif
    }
}

// MARK: - Shared Timer Access

/// Sendable wrapper for timer access from any context
public struct SharedTimer: Sendable {
    #if os(Windows)
    private let timer: WindowsPlatform.Timer
    
    public init() {
        self.timer = WindowsPlatform.Timer()
    }
    
    public func currentTimeMillis() -> UInt64 {
        timer.currentTimeMillis()
    }
    
    public func sleep(milliseconds: UInt32) {
        timer.sleep(milliseconds: milliseconds)
    }
    #elseif os(Linux)
    private let timer: LinuxPlatform.Timer
    
    public init() {
        self.timer = LinuxPlatform.Timer()
    }
    
    public func currentTimeMillis() -> UInt64 {
        timer.currentTimeMillis()
    }
    
    public func sleep(milliseconds: UInt32) {
        timer.sleep(milliseconds: milliseconds)
    }
    #else
    public init() {}
    
    public func currentTimeMillis() -> UInt64 { 0 }
    public func sleep(milliseconds: UInt32) {}
    #endif
}

/// Global shared timer instance for non-MainActor contexts
public let sharedTimer = SharedTimer()
