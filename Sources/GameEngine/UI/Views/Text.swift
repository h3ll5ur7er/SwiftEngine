

/// A view that displays text
@MainActor
public final class Text: View {
    /// The text content
    public var content: String
    
    /// Text color
    public var color: Color
    
    /// Font scale (1 = normal, 2 = double size, etc.)
    public var scale: Int
    
    /// Horizontal alignment within the frame
    public var alignment: HorizontalAlignment
    
    public init(_ content: String) {
        self.content = content
        self.color = .white
        self.scale = 1
        self.alignment = .leading
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Text has an intrinsic size based on its content
        guard let font = UIGlobals.currentContext?.font else {
            // Fallback if no font is set
            return Size(width: Float(content.count * 6 * scale), height: Float(8 * scale))
        }
        let measured = font.measureText(content, scale: scale)
        return Size(width: Float(measured.width), height: Float(measured.height))
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        let size = sizeThatFits(ProposedSize(bounds.size))
        
        // Calculate x position based on alignment
        let x: Float
        switch alignment {
        case .leading:
            x = bounds.x
        case .center:
            x = bounds.x + (bounds.width - size.width) / 2
        case .trailing:
            x = bounds.x + bounds.width - size.width
        }
        
        // Center vertically
        let y = bounds.y + (bounds.height - size.height) / 2
        
        context.drawText(content, at: (x, y), color: color, scale: scale)
    }
}

// MARK: - Fluent Modifiers

extension Text {
    /// Set the text color (alias for foregroundColor)
    public func color(_ color: Color) -> Text {
        self.color = color
        return self
    }
    
    /// Set the text color
    public func foregroundColor(_ color: Color) -> Text {
        self.color = color
        return self
    }
    
    /// Set the font scale
    public func fontSize(_ scale: Int) -> Text {
        self.scale = scale
        return self
    }
    
    /// Set text alignment
    public func multilineTextAlignment(_ alignment: HorizontalAlignment) -> Text {
        self.alignment = alignment
        return self
    }
}
