

/// The core protocol for all UI elements
/// 
/// Views form a tree structure. Each view can:
/// 1. Report its desired size given a size proposal
/// 2. Render itself to the screen
/// 3. Handle input events
@MainActor
public protocol View {
    /// Calculate the size this view wants to be, given a proposal from the parent
    func sizeThatFits(_ proposal: ProposedSize) -> Size
    
    /// Render this view within the given bounds
    func render(in bounds: UIRect, context: UIRenderContext)
    
    /// Handle a mouse event, returning true if the event was consumed
    func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool
    
    /// Handle a keyboard event, returning true if the event was consumed
    func handleKeyboard(_ event: KeyboardEvent) -> Bool
}

// MARK: - Default Implementations

extension View {
    /// Default: don't handle mouse events
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        false
    }
    
    /// Default: don't handle keyboard events
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        false
    }
}

// MARK: - Events

/// Mouse event types
public enum MouseEventType: Sendable {
    case moved
    case pressed(MouseButton)
    case released(MouseButton)
}

/// A mouse event
public struct MouseEvent: Sendable {
    public let type: MouseEventType
    public let x: Float
    public let y: Float
    
    public init(type: MouseEventType, x: Float, y: Float) {
        self.type = type
        self.x = x
        self.y = y
    }
}

/// Keyboard event types
public enum KeyboardEventType: Sendable {
    case pressed
    case released
    case character(Character)
}

/// A keyboard event
public struct KeyboardEvent: Sendable {
    public let type: KeyboardEventType
    public let key: Key
    
    public init(type: KeyboardEventType, key: Key) {
        self.type = type
        self.key = key
    }
}
