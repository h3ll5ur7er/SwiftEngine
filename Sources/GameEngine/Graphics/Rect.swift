/// Integer rectangle
public struct Rect: Equatable, Hashable, Sendable {
    public var x: Int32
    public var y: Int32
    public var width: Int32
    public var height: Int32
    
    public init(x: Int32, y: Int32, width: Int32, height: Int32) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public init(origin: Vec2, size: Vec2) {
        self.x = origin.x
        self.y = origin.y
        self.width = size.x
        self.height = size.y
    }
    
    // MARK: - Static Constructors
    
    public static let zero = Rect(x: 0, y: 0, width: 0, height: 0)
    
    // MARK: - Properties
    
    public var origin: Vec2 {
        get { Vec2(x, y) }
        set { x = newValue.x; y = newValue.y }
    }
    
    public var size: Vec2 {
        get { Vec2(width, height) }
        set { width = newValue.x; height = newValue.y }
    }
    
    public var left: Int32 { x }
    public var top: Int32 { y }
    public var right: Int32 { x + width }
    public var bottom: Int32 { y + height }
    
    public var center: Vec2 {
        Vec2(x + width / 2, y + height / 2)
    }
    
    public var topLeft: Vec2 { Vec2(left, top) }
    public var topRight: Vec2 { Vec2(right, top) }
    public var bottomLeft: Vec2 { Vec2(left, bottom) }
    public var bottomRight: Vec2 { Vec2(right, bottom) }
    
    public var isEmpty: Bool {
        width <= 0 || height <= 0
    }
    
    public var area: Int32 {
        width * height
    }
    
    // MARK: - Queries
    
    /// Check if a point is inside the rectangle
    public func contains(_ point: Vec2) -> Bool {
        point.x >= left && point.x < right && point.y >= top && point.y < bottom
    }
    
    /// Check if another rectangle intersects with this one
    public func intersects(_ other: Rect) -> Bool {
        left < other.right && right > other.left && top < other.bottom && bottom > other.top
    }
    
    /// Get the intersection of two rectangles
    public func intersection(with other: Rect) -> Rect? {
        let newLeft = max(left, other.left)
        let newTop = max(top, other.top)
        let newRight = min(right, other.right)
        let newBottom = min(bottom, other.bottom)
        
        if newLeft < newRight && newTop < newBottom {
            return Rect(x: newLeft, y: newTop, width: newRight - newLeft, height: newBottom - newTop)
        }
        return nil
    }
    
    /// Get the bounding box containing both rectangles
    public func union(with other: Rect) -> Rect {
        let newLeft = min(left, other.left)
        let newTop = min(top, other.top)
        let newRight = max(right, other.right)
        let newBottom = max(bottom, other.bottom)
        return Rect(x: newLeft, y: newTop, width: newRight - newLeft, height: newBottom - newTop)
    }
    
    // MARK: - Transformations
    
    /// Expand or shrink the rectangle by the given amount on all sides
    public func inset(by amount: Int32) -> Rect {
        Rect(x: x + amount, y: y + amount, width: width - 2 * amount, height: height - 2 * amount)
    }
    
    /// Move the rectangle by the given offset
    public func offset(by delta: Vec2) -> Rect {
        Rect(x: x + delta.x, y: y + delta.y, width: width, height: height)
    }
}

extension Rect: CustomStringConvertible {
    public var description: String {
        "Rect(x: \(x), y: \(y), w: \(width), h: \(height))"
    }
}
