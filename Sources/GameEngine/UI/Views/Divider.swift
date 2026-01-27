

/// A visual divider line
@MainActor
public final class Divider: View {
    /// Divider color
    public var color: Color
    
    /// Thickness
    public var thickness: Float
    
    /// Orientation
    public var isVertical: Bool
    
    public init(vertical: Bool = false) {
        self.color = Color(r: 60, g: 60, b: 60)
        self.thickness = 1
        self.isVertical = vertical
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        if isVertical {
            return Size(width: thickness, height: proposal.height ?? 20)
        } else {
            return Size(width: proposal.width ?? 100, height: thickness)
        }
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        context.fillRect(bounds, color: color)
    }
}

// MARK: - Fluent Modifiers

extension Divider {
    /// Set the color
    public func color(_ color: Color) -> Divider {
        self.color = color
        return self
    }
    
    /// Set the thickness
    public func thickness(_ thickness: Float) -> Divider {
        self.thickness = thickness
        return self
    }
}
