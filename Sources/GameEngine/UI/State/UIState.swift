

/// A property wrapper that provides reactive state management for UI
/// When the value changes, it notifies observers to trigger UI updates
@MainActor
@propertyWrapper
public final class UIState<Value> {
    
    private var value: Value
    private var observers: [() -> Void] = []
    
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            notifyObservers()
        }
    }
    
    /// Provides access to the UIState itself for binding
    public var projectedValue: UIState<Value> {
        self
    }
    
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    /// Add an observer that will be called when the value changes
    public func observe(_ observer: @escaping () -> Void) {
        observers.append(observer)
    }
    
    /// Remove all observers
    public func removeAllObservers() {
        observers.removeAll()
    }
    
    private func notifyObservers() {
        for observer in observers {
            observer()
        }
    }
}

// MARK: - Binding

/// A two-way binding to a value
@MainActor
public final class Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    
    public var wrappedValue: Value {
        get { getter() }
        set { setter(newValue) }
    }
    
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }
    
    /// Create a binding from a UIState
    public convenience init(_ state: UIState<Value>) {
        self.init(
            get: { state.wrappedValue },
            set: { state.wrappedValue = $0 }
        )
    }
    
    /// Create a constant binding (read-only)
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

// MARK: - Observable Object

/// Protocol for objects that can notify observers of changes
@MainActor
public protocol ObservableObject: AnyObject {
    /// Called to notify that the object has changed
    func objectWillChange()
}

/// A base class for observable view models
@MainActor
open class ViewModel: ObservableObject {
    private var changeObservers: [() -> Void] = []
    
    public init() {}
    
    /// Add an observer for changes
    public func onChanged(_ observer: @escaping () -> Void) {
        changeObservers.append(observer)
    }
    
    /// Notify observers that the object will change
    public func objectWillChange() {
        for observer in changeObservers {
            observer()
        }
    }
    
    /// Call this after modifying published properties
    public func notifyChange() {
        objectWillChange()
    }
}

// MARK: - Published Property Wrapper

/// A property wrapper for properties in a ViewModel that should trigger updates
@MainActor
@propertyWrapper
public final class Published<Value> {
    
    private var value: Value
    private weak var owner: ViewModel?
    
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            owner?.notifyChange()
        }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.value },
            set: { self.wrappedValue = $0 }
        )
    }
    
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    /// Set the owner ViewModel (called during initialization)
    public func setOwner(_ owner: ViewModel) {
        self.owner = owner
    }
}
