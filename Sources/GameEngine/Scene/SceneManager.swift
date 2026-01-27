/// Manages scene loading and transitions
@MainActor
public final class SceneManager {
    private var scenes: [String: Scene] = [:]
    private var activeSceneName: String?
    private weak var engine: Engine?
    
    public init(engine: Engine) {
        self.engine = engine
    }
    
    /// Register a scene with a name
    public func register(name: String, scene: Scene) {
        scenes[name] = scene
    }
    
    /// Unregister a scene
    public func unregister(name: String) {
        if activeSceneName == name {
            unloadCurrent()
        }
        scenes.removeValue(forKey: name)
    }
    
    /// Load a scene by name
    public func load(name: String) -> Bool {
        guard let engine = engine, let scene = scenes[name] else { return false }
        engine.loadScene(scene)
        activeSceneName = name
        return true
    }
    
    /// Unload the current scene
    public func unloadCurrent() {
        engine?.unloadScene()
        activeSceneName = nil
    }
    
    /// Get the currently active scene name
    public var currentSceneName: String? {
        activeSceneName
    }
    
    /// Check if a scene is registered
    public func hasScene(name: String) -> Bool {
        scenes[name] != nil
    }
}
