

/// A view that displays a rectangle
@MainActor
public final class UIRectangle: View {
    /// Fill color (nil = no fill)
    public var fillColor: Color?
    
    /// Stroke color (nil = no stroke)
    public var strokeColor: Color?
    
    /// Stroke width
    public var strokeWidth: Float
    
    /// Corner radius (0 = sharp corners)
    public var cornerRadius: Float
    
    public init() {
        self.fillColor = .white
        self.strokeColor = nil
        self.strokeWidth = 1
        self.cornerRadius = 0
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Rectangle expands to fill available space
        proposal.replacingUnspecified(width: 50, height: 50)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        if let fill = fillColor {
            if cornerRadius > 0 {
                context.fillRoundedRect(bounds, color: fill, cornerRadius: cornerRadius)
            } else {
                context.fillRect(bounds, color: fill)
            }
        }
        
        if let stroke = strokeColor {
            context.strokeRect(bounds, color: stroke, lineWidth: strokeWidth)
        }
    }
}

// MARK: - Fluent Modifiers

extension UIRectangle {
    /// Set the fill color
    public func fill(_ color: Color) -> UIRectangle {
        self.fillColor = color
        return self
    }
    
    /// Set the stroke color and width
    public func stroke(_ color: Color, lineWidth: Float = 1) -> UIRectangle {
        self.strokeColor = color
        self.strokeWidth = lineWidth
        return self
    }
    
    /// Set the corner radius
    public func cornerRadius(_ radius: Float) -> UIRectangle {
        self.cornerRadius = radius
        return self
    }
}
