

/// Floating-point rectangle for UI layout
/// (Separate from GameEngine's Int32-based Rect for precision during layout)
public struct UIRect: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    
    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public init(origin: (Float, Float), size: Size) {
        self.x = origin.0
        self.y = origin.1
        self.width = size.width
        self.height = size.height
    }
    
    public static let zero = UIRect(x: 0, y: 0, width: 0, height: 0)
    
    // MARK: - Properties
    
    public var origin: (x: Float, y: Float) {
        get { (x, y) }
        set { x = newValue.x; y = newValue.y }
    }
    
    public var size: Size {
        get { Size(width: width, height: height) }
        set { width = newValue.width; height = newValue.height }
    }
    
    public var minX: Float { x }
    public var minY: Float { y }
    public var maxX: Float { x + width }
    public var maxY: Float { y + height }
    
    public var midX: Float { x + width / 2 }
    public var midY: Float { y + height / 2 }
    
    // MARK: - Operations
    
    /// Check if a point is inside the rectangle
    public func contains(x px: Float, y py: Float) -> Bool {
        px >= minX && px < maxX && py >= minY && py < maxY
    }
    
    /// Inset the rectangle by the given insets
    public func inset(by insets: EdgeInsets) -> UIRect {
        UIRect(
            x: x + insets.leading,
            y: y + insets.top,
            width: max(0, width - insets.horizontal),
            height: max(0, height - insets.vertical)
        )
    }
    
    /// Expand the rectangle by the given insets
    public func expanded(by insets: EdgeInsets) -> UIRect {
        UIRect(
            x: x - insets.leading,
            y: y - insets.top,
            width: width + insets.horizontal,
            height: height + insets.vertical
        )
    }
    
    /// Offset the rectangle by the given amount
    public func offsetBy(dx: Float, dy: Float) -> UIRect {
        UIRect(x: x + dx, y: y + dy, width: width, height: height)
    }
    
    /// Calculate the intersection with another rectangle
    public func intersection(with other: UIRect) -> UIRect {
        let newMinX = max(minX, other.minX)
        let newMinY = max(minY, other.minY)
        let newMaxX = min(maxX, other.maxX)
        let newMaxY = min(maxY, other.maxY)
        
        if newMinX >= newMaxX || newMinY >= newMaxY {
            return .zero
        }
        
        return UIRect(
            x: newMinX,
            y: newMinY,
            width: newMaxX - newMinX,
            height: newMaxY - newMinY
        )
    }
    
    /// Check if this rectangle intersects with another
    public func intersects(_ other: UIRect) -> Bool {
        minX < other.maxX && maxX > other.minX &&
        minY < other.maxY && maxY > other.minY
    }
    
    /// Convert to integer Rect for rendering
    public func toRect() -> Rect {
        Rect(
            x: Int32(x.rounded()),
            y: Int32(y.rounded()),
            width: Int32(width.rounded()),
            height: Int32(height.rounded())
        )
    }
}

extension UIRect: CustomStringConvertible {
    public var description: String {
        "UIRect(x: \(x), y: \(y), w: \(width), h: \(height))"
    }
}
