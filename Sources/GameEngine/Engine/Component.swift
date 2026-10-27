import Foundation

/// Base class for all components that can be attached to GameObjects
@MainActor
open class Component {
    /// The GameObject this component is attached to
    public private(set) weak var gameObject: GameObject?
    
    /// Whether this component is enabled
    /// Changing it calls onEnable()/onDisable() while attached to an active GameObject
    public var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue, let gameObject, gameObject.isActive else { return }
            if isEnabled {
                onEnable()
            } else {
                onDisable()
            }
        }
    }
    
    /// Quick access to the transform
    public var transform: Transform {
        gameObject!.transform
    }
    
    public required init() {}
    
    // MARK: - Lifecycle Methods (Override in subclasses)
    
    /// Called when the component is first added to a GameObject
    open func awake() {}
    
    /// Called before the first update, after all components are initialized
    open func start() {}
    
    /// Called every frame
    open func update(deltaTime: Float) {}
    
    /// Called every frame after all update() calls
    open func lateUpdate(deltaTime: Float) {}
    
    /// Called at a fixed time interval (for physics)
    open func fixedUpdate(fixedDeltaTime: Float) {}
    
    /// Called when the component is about to be destroyed
    open func onDestroy() {}
    
    /// Called when the component becomes enabled
    open func onEnable() {}
    
    /// Called when the component becomes disabled
    open func onDisable() {}
    
    // MARK: - Internal
    
    /// Called internally to attach this component to a GameObject
    internal func attach(to gameObject: GameObject) {
        self.gameObject = gameObject
    }
    
    /// Called internally to detach this component from its GameObject
    internal func detach() {
        self.gameObject = nil
    }
}

// MARK: - Component Identification

extension Component {
    /// Returns the type name of this component
    public var typeName: String {
        String(describing: type(of: self))
    }
}
