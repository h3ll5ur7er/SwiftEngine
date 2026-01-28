// LinuxPlatform - Platform entry point
// Generic name for cross-platform abstraction

#if os(Linux)
import Glibc

/// Platform utilities and factory functions
public enum Platform {
    /// Exit the process with the given code
    public static func exitProcess(_ code: Int32) -> Never {
        Glibc.exit(code)
    }
}

#endif
