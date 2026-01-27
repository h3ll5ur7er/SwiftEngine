

/// A property wrapper that creates and stores an observable object
@MainActor
@propertyWrapper
public final class StateObject<ObjectType: ViewModel> {
    
    private var object: ObjectType?
    private let factory: () -> ObjectType
    
    public var wrappedValue: ObjectType {
        if object == nil {
            object = factory()
        }
        return object!
    }
    
    public var projectedValue: ObjectType {
        wrappedValue
    }
    
    public init(wrappedValue: @autoclosure @escaping () -> ObjectType) {
        self.factory = wrappedValue
    }
}

/// A property wrapper for observing an external ViewModel
@MainActor
@propertyWrapper
public final class ObservedObject<ObjectType: ViewModel> {
    
    public var wrappedValue: ObjectType
    
    public var projectedValue: ObjectType {
        wrappedValue
    }
    
    public init(wrappedValue: ObjectType) {
        self.wrappedValue = wrappedValue
    }
}
