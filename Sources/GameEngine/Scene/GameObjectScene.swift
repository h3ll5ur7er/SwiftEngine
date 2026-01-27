import Foundation

/// A scene that manages GameObjects and their components
@MainActor
open class GameObjectScene: Scene {
    /// All root GameObjects in this scene
    public private(set) var rootGameObjects: [GameObject] = []
    
    /// All GameObjects in this scene (including children)
    public private(set) var allGameObjects: [GameObject] = []
    
    /// Quick lookup by name
    private var gameObjectsByName: [String: [GameObject]] = [:]
    
    /// Quick lookup by tag
    private var gameObjectsByTag: [String: [GameObject]] = [:]
    
    /// GameObjects pending start() call
    private var pendingStart: [GameObject] = []
    
    /// GameObjects pending destruction
    private var pendingDestroy: [GameObject] = []
    
    /// Whether the scene has been initialized
    private var isInitialized: Bool = false
    
    /// Fixed update accumulator for physics
    private var fixedUpdateAccumulator: Float = 0
    
    /// Fixed timestep for physics updates (default: 50 Hz)
    public var fixedDeltaTime: Float = 1.0 / 50.0
    
    /// Reference to the engine
    public private(set) weak var engine: Engine?
    
    public init() {}
    
    // MARK: - Scene Protocol
    
    open func onLoad(engine: Engine) {
        self.engine = engine
    }
    
    open func onUnload(engine: Engine) {
        // Destroy all GameObjects
        for gameObject in allGameObjects {
            gameObject.internalDestroy()
        }
        rootGameObjects.removeAll()
        allGameObjects.removeAll()
        gameObjectsByName.removeAll()
        gameObjectsByTag.removeAll()
    }
    
    open func onActivate(engine: Engine) {}
    
    open func onDeactivate(engine: Engine) {}
    
    open func update(context: FrameContext, input: Input) {
        let deltaTime = Float(context.deltaTime)
        
        // Start pending GameObjects
        for gameObject in pendingStart {
            gameObject.internalStart()
        }
        pendingStart.removeAll()
        
        // Fixed update (for physics)
        fixedUpdateAccumulator += deltaTime
        while fixedUpdateAccumulator >= fixedDeltaTime {
            for gameObject in allGameObjects where gameObject.isActive {
                gameObject.internalFixedUpdate(fixedDeltaTime: fixedDeltaTime)
            }
            fixedUpdateAccumulator -= fixedDeltaTime
        }
        
        // Update all GameObjects
        for gameObject in allGameObjects where gameObject.isActive {
            gameObject.internalUpdate(deltaTime: deltaTime)
        }
        
        // Late update
        for gameObject in allGameObjects where gameObject.isActive {
            gameObject.internalLateUpdate(deltaTime: deltaTime)
        }
        
        // Destroy pending GameObjects
        for gameObject in pendingDestroy {
            internalDestroyGameObject(gameObject)
        }
        pendingDestroy.removeAll()
    }
    
    open func render(context: RenderContext) {
        // Override in subclasses to implement rendering
    }
    
    // MARK: - GameObject Management
    
    /// Create a new empty GameObject and add it to the scene
    @discardableResult
    public func createGameObject(name: String = "GameObject") -> GameObject {
        let gameObject = GameObject(name: name)
        addGameObject(gameObject)
        return gameObject
    }
    
    /// Create a new GameObject at a position
    @discardableResult
    public func createGameObject(name: String, at position: Vec3d) -> GameObject {
        let gameObject = GameObject(name: name, position: position)
        addGameObject(gameObject)
        return gameObject
    }
    
    /// Add an existing GameObject to the scene
    public func addGameObject(_ gameObject: GameObject) {
        guard gameObject.scene == nil else {
            print("Warning: GameObject '\(gameObject.name)' is already in a scene")
            return
        }
        
        gameObject.scene = self
        rootGameObjects.append(gameObject)
        registerGameObject(gameObject)
        
        if isInitialized {
            pendingStart.append(gameObject)
        }
    }
    
    /// Remove a GameObject from the scene (delayed until end of frame)
    public func destroy(_ gameObject: GameObject) {
        guard gameObject.scene === self else { return }
        pendingDestroy.append(gameObject)
    }
    
    /// Immediately remove a GameObject from the scene
    private func internalDestroyGameObject(_ gameObject: GameObject) {
        // Destroy children first
        for child in gameObject.transform.children {
            if let childGO = findGameObject(with: child) {
                internalDestroyGameObject(childGO)
            }
        }
        
        gameObject.internalDestroy()
        unregisterGameObject(gameObject)
        
        if let index = rootGameObjects.firstIndex(of: gameObject) {
            rootGameObjects.remove(at: index)
        }
        
        gameObject.scene = nil
    }
    
    // MARK: - Finding GameObjects
    
    /// Find first GameObject with the given name
    public func find(name: String) -> GameObject? {
        gameObjectsByName[name]?.first
    }
    
    /// Find all GameObjects with the given name
    public func findAll(name: String) -> [GameObject] {
        gameObjectsByName[name] ?? []
    }
    
    /// Find all GameObjects with the given tag
    public func findWithTag(_ tag: String) -> [GameObject] {
        gameObjectsByTag[tag] ?? []
    }
    
    /// Find first GameObject with the given tag
    public func findFirstWithTag(_ tag: String) -> GameObject? {
        gameObjectsByTag[tag]?.first
    }
    
    /// Find all GameObjects with a specific component type
    public func findObjectsOfType<T: Component>(_ type: T.Type) -> [GameObject] {
        allGameObjects.filter { $0.hasComponent(type) }
    }
    
    /// Find all components of a specific type across all GameObjects
    public func findComponentsOfType<T: Component>(_ type: T.Type) -> [T] {
        allGameObjects.flatMap { $0.getComponents(type) }
    }
    
    // MARK: - Internal Registration
    
    private func registerGameObject(_ gameObject: GameObject) {
        allGameObjects.append(gameObject)
        
        // Register by name
        if gameObjectsByName[gameObject.name] == nil {
            gameObjectsByName[gameObject.name] = []
        }
        gameObjectsByName[gameObject.name]?.append(gameObject)
        
        // Register by tag
        if gameObjectsByTag[gameObject.tag] == nil {
            gameObjectsByTag[gameObject.tag] = []
        }
        gameObjectsByTag[gameObject.tag]?.append(gameObject)
    }
    
    private func unregisterGameObject(_ gameObject: GameObject) {
        if let index = allGameObjects.firstIndex(of: gameObject) {
            allGameObjects.remove(at: index)
        }
        
        // Unregister by name
        if let index = gameObjectsByName[gameObject.name]?.firstIndex(of: gameObject) {
            gameObjectsByName[gameObject.name]?.remove(at: index)
        }
        
        // Unregister by tag
        if let index = gameObjectsByTag[gameObject.tag]?.firstIndex(of: gameObject) {
            gameObjectsByTag[gameObject.tag]?.remove(at: index)
        }
    }
    
    /// Find the GameObject associated with a transform
    private func findGameObject(with transform: Transform) -> GameObject? {
        allGameObjects.first { $0.transform === transform }
    }
    
    // MARK: - Scene Initialization
    
    /// Called after onLoad to start all initial GameObjects
    internal func initializeScene() {
        isInitialized = true
        for gameObject in allGameObjects {
            gameObject.internalStart()
        }
    }
}
