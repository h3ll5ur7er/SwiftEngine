/// Horizontal alignment options
public enum HorizontalAlignment: Sendable {
    case leading
    case center
    case trailing
    
    /// Calculate the X offset for a child of given width within a container of given width
    public func offset(childWidth: Float, in containerWidth: Float) -> Float {
        switch self {
        case .leading:
            return 0
        case .center:
            return (containerWidth - childWidth) / 2
        case .trailing:
            return containerWidth - childWidth
        }
    }
}

/// Vertical alignment options
public enum VerticalAlignment: Sendable {
    case top
    case center
    case bottom
    
    /// Calculate the Y offset for a child of given height within a container of given height
    public func offset(childHeight: Float, in containerHeight: Float) -> Float {
        switch self {
        case .top:
            return 0
        case .center:
            return (containerHeight - childHeight) / 2
        case .bottom:
            return containerHeight - childHeight
        }
    }
}

/// Combined horizontal and vertical alignment
public struct Alignment: Sendable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment
    
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    // MARK: - Common Alignments
    
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
    public static let top = Alignment(horizontal: .center, vertical: .top)
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
    
    public static let leading = Alignment(horizontal: .leading, vertical: .center)
    public static let center = Alignment(horizontal: .center, vertical: .center)
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)
    
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
    
    /// Calculate the offset for a child of given size within a container of given size
    public func offset(childSize: Size, in containerSize: Size) -> (x: Float, y: Float) {
        (
            x: horizontal.offset(childWidth: childSize.width, in: containerSize.width),
            y: vertical.offset(childHeight: childSize.height, in: containerSize.height)
        )
    }
}
