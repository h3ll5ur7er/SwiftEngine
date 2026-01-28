// WindowsPlatform - High-precision timer
// Generic name for cross-platform abstraction

#if os(Windows)
@preconcurrency import WinSDK

/// High-precision timer using Windows API
public struct Timer: Sendable {
    public init() {}
    
    /// Get current time in milliseconds since system start
    public func currentTimeMillis() -> UInt64 {
        GetTickCount64()
    }
    
    /// Sleep for the specified number of milliseconds
    public func sleep(milliseconds: UInt32) {
        Sleep(milliseconds)
    }
}

#endif
