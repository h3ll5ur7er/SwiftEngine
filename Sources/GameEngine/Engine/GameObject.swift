import Foundation

/// A GameObject is a container for components in the scene hierarchy
@MainActor
public final class GameObject {
    /// Unique identifier
    public let id: UUID
    
    /// Name of this GameObject
    public var name: String
    
    /// Whether this GameObject is active
    public var isActive: Bool = true {
        didSet {
            if isActive != oldValue {
                if isActive {
                    for component in components {
                        if component.isEnabled {
                            component.onEnable()
                        }
                    }
                } else {
                    for component in components {
                        if component.isEnabled {
                            component.onDisable()
                        }
                    }
                }
            }
        }
    }
    
    /// Transform component (every GameObject has one)
    public let transform: Transform
    
    /// Tag for categorization
    public var tag: String = "Untagged"
    
    /// Layer for rendering and physics
    public var layer: Int = 0
    
    /// All components attached to this GameObject
    public private(set) var components: [Component] = []
    
    /// The scene this GameObject belongs to
    public internal(set) weak var scene: GameObjectScene?
    
    /// Whether start() has been called on components
    private var hasStarted: Bool = false
    
    // MARK: - Initialization
    
    public init(name: String = "GameObject") {
        self.id = UUID()
        self.name = name
        self.transform = Transform()
    }
    
    public init(name: String, position: Vec3d) {
        self.id = UUID()
        self.name = name
        self.transform = Transform(position: position)
    }
    
    public init(name: String, position: Vec3d, rotation: Quaternion) {
        self.id = UUID()
        self.name = name
        self.transform = Transform(position: position, rotation: rotation)
    }
    
    // MARK: - Component Management
    
    /// Add a component to this GameObject
    @discardableResult
    public func addComponent<T: Component>(_ component: T) -> T {
        component.attach(to: self)
        components.append(component)
        component.awake()
        
        // Always call onEnable when component is added and enabled
        // This ensures static registries (like DirectionalLight.all) are populated
        if isActive && component.isEnabled {
            component.onEnable()
        }
        
        // Only call start() if the GameObject has already started
        if hasStarted && isActive && component.isEnabled {
            component.start()
        }
        
        return component
    }
    
    /// Create and add a component of the given type
    @discardableResult
    public func addComponent<T: Component>(_ type: T.Type) -> T {
        let component = T()
        return addComponent(component)
    }
    
    /// Get the first component of the given type
    public func getComponent<T: Component>(_ type: T.Type) -> T? {
        components.first { $0 is T } as? T
    }
    
    /// Get all components of the given type
    public func getComponents<T: Component>(_ type: T.Type) -> [T] {
        components.compactMap { $0 as? T }
    }
    
    /// Check if this GameObject has a component of the given type
    public func hasComponent<T: Component>(_ type: T.Type) -> Bool {
        components.contains { $0 is T }
    }
    
    /// Remove a specific component
    public func removeComponent(_ component: Component) {
        guard let index = components.firstIndex(where: { $0 === component }) else { return }
        
        component.onDestroy()
        component.detach()
        components.remove(at: index)
    }
    
    /// Remove all components of a given type
    public func removeComponents<T: Component>(_ type: T.Type) {
        let toRemove = components.filter { $0 is T }
        for component in toRemove {
            removeComponent(component)
        }
    }
    
    // MARK: - Hierarchy
    
    /// Parent GameObject (derived from transform hierarchy)
    public var parent: GameObject? {
        // Note: This requires the scene to track transform-to-gameobject mapping
        // For now, we use transform hierarchy directly
        nil // Will be implemented with scene tracking
    }
    
    /// Set the parent of this GameObject
    public func setParent(_ newParent: GameObject?, worldPositionStays: Bool = true) {
        if worldPositionStays {
            let worldPos = transform.position
            let worldRot = transform.rotation
            
            if let parent = newParent {
                transform.parent?.removeChild(transform)
                parent.transform.addChild(transform)
            } else {
                transform.removeFromParent()
            }
            
            transform.position = worldPos
            transform.rotation = worldRot
        } else {
            if let parent = newParent {
                transform.parent?.removeChild(transform)
                parent.transform.addChild(transform)
            } else {
                transform.removeFromParent()
            }
        }
    }
    
    // MARK: - Lifecycle (called by Scene)
    
    internal func internalStart() {
        guard !hasStarted && isActive else { return }
        hasStarted = true
        
        // Only call start() here - onEnable was already called when component was added
        for component in components where component.isEnabled {
            component.start()
        }
    }
    
    internal func internalUpdate(deltaTime: Float) {
        guard isActive else { return }
        
        for component in components where component.isEnabled {
            component.update(deltaTime: deltaTime)
        }
    }
    
    internal func internalLateUpdate(deltaTime: Float) {
        guard isActive else { return }
        
        for component in components where component.isEnabled {
            component.lateUpdate(deltaTime: deltaTime)
        }
    }
    
    internal func internalFixedUpdate(fixedDeltaTime: Float) {
        guard isActive else { return }
        
        for component in components where component.isEnabled {
            component.fixedUpdate(fixedDeltaTime: fixedDeltaTime)
        }
    }
    
    internal func internalDestroy() {
        for component in components {
            component.onDestroy()
            component.detach()
        }
        components.removeAll()
    }
}

// MARK: - Equatable & Hashable

extension GameObject: Equatable {
    nonisolated public static func == (lhs: GameObject, rhs: GameObject) -> Bool {
        lhs.id == rhs.id
    }
}

extension GameObject: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CustomStringConvertible

extension GameObject: @MainActor CustomStringConvertible {
    public var description: String {
        "GameObject(\"\(name)\", components: \(components.count))"
    }
}
