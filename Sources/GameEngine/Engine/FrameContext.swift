/// Context passed to scene update methods
public struct FrameContext: Sendable {
    /// Time since last frame in seconds
    public let deltaTime: Double
    
    /// Total time since engine started in seconds
    public let totalTime: Double
    
    /// Current frame number
    public let frameCount: UInt64
    
    /// Current FPS
    public let fps: Double
    
    public init(deltaTime: Double, totalTime: Double, frameCount: UInt64, fps: Double) {
        self.deltaTime = deltaTime
        self.totalTime = totalTime
        self.frameCount = frameCount
        self.fps = fps
    }
}
