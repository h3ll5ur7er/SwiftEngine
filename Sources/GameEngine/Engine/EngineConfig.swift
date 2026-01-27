/// Configuration for engine initialization
public struct EngineConfig: Sendable {
    /// Window title
    public var title: String
    
    /// Initial window width
    public var width: Int32
    
    /// Initial window height
    public var height: Int32
    
    /// Target FPS (nil for uncapped)
    public var targetFps: Int?
    
    /// Show FPS in window title
    public var showFpsInTitle: Bool
    
    public init(
        title: String = "Swift Engine",
        width: Int32 = 800,
        height: Int32 = 600,
        targetFps: Int? = nil,
        showFpsInTitle: Bool = true
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.targetFps = targetFps
        self.showFpsInTitle = showFpsInTitle
    }
}
