// LinuxPlatform - High-precision timer
// Generic name for cross-platform abstraction

#if os(Linux)
import Glibc

/// High-precision timer using POSIX APIs
public struct Timer: Sendable {
    public init() {}
    
    /// Get current time in milliseconds since some epoch
    public func currentTimeMillis() -> UInt64 {
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return UInt64(ts.tv_sec) * 1000 + UInt64(ts.tv_nsec) / 1_000_000
    }
    
    /// Sleep for the specified number of milliseconds
    public func sleep(milliseconds: UInt32) {
        var req = timespec()
        req.tv_sec = Int(milliseconds / 1000)
        req.tv_nsec = Int((milliseconds % 1000)) * 1_000_000
        nanosleep(&req, nil)
    }
}

#endif
