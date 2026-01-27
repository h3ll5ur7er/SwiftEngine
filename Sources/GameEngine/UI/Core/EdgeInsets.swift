/// Insets for padding, margins, etc.
public struct EdgeInsets: Equatable, Sendable {
    public var top: Float
    public var leading: Float
    public var bottom: Float
    public var trailing: Float
    
    public init(top: Float, leading: Float, bottom: Float, trailing: Float) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
    
    /// Create uniform insets on all sides
    public init(_ all: Float) {
        self.top = all
        self.leading = all
        self.bottom = all
        self.trailing = all
    }
    
    /// Create symmetric horizontal and vertical insets
    public init(horizontal: Float, vertical: Float) {
        self.top = vertical
        self.leading = horizontal
        self.bottom = vertical
        self.trailing = horizontal
    }
    
    public static let zero = EdgeInsets(0)
    
    /// Total horizontal inset (leading + trailing)
    public var horizontal: Float {
        leading + trailing
    }
    
    /// Total vertical inset (top + bottom)
    public var vertical: Float {
        top + bottom
    }
    
    /// Combined size of all insets
    public var size: Size {
        Size(width: horizontal, height: vertical)
    }
}
