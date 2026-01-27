/// Context passed to scene render methods
@MainActor
public struct RenderContext {
    /// The renderer for clearing and low-level access
    public let renderer: Renderer
    
    /// Screen width
    public var width: Int32 { renderer.width }
    
    /// Screen height
    public var height: Int32 { renderer.height }
    
    /// Screen bounds
    public var bounds: Rect { renderer.bounds }
    
    public init(renderer: Renderer) {
        self.renderer = renderer
    }
}
