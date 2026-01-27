/// A size proposal from parent to child during layout
/// 
/// In SwiftUI-style layout, the parent proposes a size to the child,
/// and the child responds with its desired size. A `nil` dimension
/// means the child can be whatever size it wants in that dimension.
public struct ProposedSize: Equatable, Sendable {
    /// Proposed width (nil means "be whatever width you want")
    public var width: Float?
    
    /// Proposed height (nil means "be whatever height you want")
    public var height: Float?
    
    public init(width: Float?, height: Float?) {
        self.width = width
        self.height = height
    }
    
    public init(_ size: Size) {
        self.width = size.width
        self.height = size.height
    }
    
    // MARK: - Common Proposals
    
    /// Completely unconstrained
    public static let unspecified = ProposedSize(width: nil, height: nil)
    
    /// Zero size proposal
    public static let zero = ProposedSize(width: 0, height: 0)
    
    // MARK: - Resolving
    
    /// Replace nil dimensions with the given defaults
    public func replacingUnspecified(width: Float = 0, height: Float = 0) -> Size {
        Size(
            width: self.width ?? width,
            height: self.height ?? height
        )
    }
    
    /// Replace nil dimensions with values from another size
    public func replacingUnspecified(with size: Size) -> Size {
        Size(
            width: self.width ?? size.width,
            height: self.height ?? size.height
        )
    }
    
    /// Convert to concrete size, treating nil as zero
    public var orZero: Size {
        Size(width: width ?? 0, height: height ?? 0)
    }
    
    /// Convert to concrete size, treating nil as infinity
    public var orInfinity: Size {
        Size(width: width ?? .infinity, height: height ?? .infinity)
    }
}

extension ProposedSize: CustomStringConvertible {
    public var description: String {
        let w = width.map { String(format: "%.1f", $0) } ?? "nil"
        let h = height.map { String(format: "%.1f", $0) } ?? "nil"
        return "ProposedSize(\(w), \(h))"
    }
}
