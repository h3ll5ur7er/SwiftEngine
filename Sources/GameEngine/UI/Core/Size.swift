/// Represents a 2D size with floating-point dimensions
public struct Size: Equatable, Sendable {
    public var width: Float
    public var height: Float
    
    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }
    
    public init(_ width: Float, _ height: Float) {
        self.width = width
        self.height = height
    }
    
    public init(square: Float) {
        self.width = square
        self.height = square
    }
    
    public static let zero = Size(width: 0, height: 0)
    public static let infinity = Size(width: .infinity, height: .infinity)
    
    /// Clamp size to minimum and maximum bounds
    public func clamped(min: Size, max: Size) -> Size {
        Size(
            width: Swift.max(min.width, Swift.min(self.width, max.width)),
            height: Swift.max(min.height, Swift.min(self.height, max.height))
        )
    }
    
    /// Returns a size that fits within the given bounds while maintaining aspect ratio
    public func aspectFit(in bounds: Size) -> Size {
        guard width > 0 && height > 0 else { return .zero }
        let scaleX = bounds.width / width
        let scaleY = bounds.height / height
        let scale = Swift.min(scaleX, scaleY)
        return Size(width: width * scale, height: height * scale)
    }
    
    /// Returns a size that fills the given bounds while maintaining aspect ratio
    public func aspectFill(in bounds: Size) -> Size {
        guard width > 0 && height > 0 else { return bounds }
        let scaleX = bounds.width / width
        let scaleY = bounds.height / height
        let scale = Swift.max(scaleX, scaleY)
        return Size(width: width * scale, height: height * scale)
    }
}

extension Size: CustomStringConvertible {
    public var description: String {
        "Size(\(width), \(height))"
    }
}
