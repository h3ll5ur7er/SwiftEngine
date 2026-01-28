// WindowsPlatform - Platform entry point
// Generic name for cross-platform abstraction

#if os(Windows)
@preconcurrency import WinSDK

/// Platform utilities and factory functions
public enum Platform {
    /// Exit the process with the given code
    @inlinable
    public static func exitProcess(_ code: Int32) -> Never {
        WinSDK.ExitProcess(UInt32(bitPattern: code))
    }
}

#endif
