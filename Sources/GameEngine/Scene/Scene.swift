/// Protocol for game scenes
@MainActor
public protocol Scene: AnyObject {
    /// Called when the scene is first loaded
    func onLoad(engine: Engine)
    
    /// Called when the scene is being unloaded
    func onUnload(engine: Engine)
    
    /// Called when the scene becomes active
    func onActivate(engine: Engine)
    
    /// Called when the scene is deactivated (but not unloaded)
    func onDeactivate(engine: Engine)
    
    /// Called each frame to update game logic
    func update(context: FrameContext, input: Input)
    
    /// Called each frame to render
    func render(context: RenderContext)
}

/// Default implementations for Scene protocol
extension Scene {
    public func onLoad(engine: Engine) {}
    public func onUnload(engine: Engine) {}
    public func onActivate(engine: Engine) {}
    public func onDeactivate(engine: Engine) {}
}
