

/// A view that wraps another view and applies modifications
@MainActor
public final class ModifiedView: View {
    /// The wrapped view
    public let content: any View
    
    /// Background color
    public var backgroundColor: Color?
    
    /// Foreground color (for text)
    public var foregroundColor: Color?
    
    /// Border color
    public var borderColor: Color?
    
    /// Border width
    public var borderWidth: Float = 1
    
    /// Corner radius
    public var cornerRadius: Float = 0
    
    /// Padding around the content
    public var padding: EdgeInsets = .zero
    
    /// Fixed frame size (nil = use content size)
    public var frameWidth: Float?
    public var frameHeight: Float?
    
    /// Minimum size constraints
    public var minWidth: Float?
    public var minHeight: Float?
    
    /// Maximum size constraints
    public var maxWidth: Float?
    public var maxHeight: Float?
    
    /// Opacity (0-1)
    public var opacity: Float = 1.0
    
    public init(_ content: any View) {
        self.content = content
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Calculate content size within padding
        let innerProposal = ProposedSize(
            width: proposal.width.map { $0 - padding.horizontal },
            height: proposal.height.map { $0 - padding.vertical }
        )
        
        var contentSize = content.sizeThatFits(innerProposal)
        
        // Add padding
        contentSize.width += padding.horizontal
        contentSize.height += padding.vertical
        
        // Apply frame constraints
        if let fw = frameWidth { contentSize.width = fw }
        if let fh = frameHeight { contentSize.height = fh }
        
        // Apply min/max constraints
        if let minW = minWidth { contentSize.width = max(minW, contentSize.width) }
        if let minH = minHeight { contentSize.height = max(minH, contentSize.height) }
        if let maxW = maxWidth { contentSize.width = min(maxW, contentSize.width) }
        if let maxH = maxHeight { contentSize.height = min(maxH, contentSize.height) }
        
        return contentSize
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Draw background
        if let bg = backgroundColor {
            let color = bg.withAlpha(UInt8(Float(bg.a) * opacity))
            if cornerRadius > 0 {
                context.fillRoundedRect(bounds, color: color, cornerRadius: cornerRadius)
            } else {
                context.fillRect(bounds, color: color)
            }
        }
        
        // Draw border
        if let border = borderColor {
            let color = border.withAlpha(UInt8(Float(border.a) * opacity))
            context.strokeRect(bounds, color: color, lineWidth: borderWidth)
        }
        
        // Calculate inner bounds for content
        let innerBounds = bounds.inset(by: padding)
        
        // Render content
        content.render(in: innerBounds, context: context)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let innerBounds = bounds.inset(by: padding)
        return content.handleMouse(event, in: innerBounds)
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        content.handleKeyboard(event)
    }
}

// MARK: - View Extension for Modifiers

extension View {
    /// Add a background color
    public func background(_ color: Color) -> ModifiedView {
        let modified = wrap()
        modified.backgroundColor = color
        return modified
    }
    
    /// Add padding on all sides
    public func padding(_ value: Float) -> ModifiedView {
        let modified = wrap()
        modified.padding = EdgeInsets(value)
        return modified
    }
    
    /// Add padding with specific insets
    public func padding(_ insets: EdgeInsets) -> ModifiedView {
        let modified = wrap()
        modified.padding = insets
        return modified
    }
    
    /// Add horizontal and vertical padding
    public func padding(horizontal: Float = 0, vertical: Float = 0) -> ModifiedView {
        let modified = wrap()
        modified.padding = EdgeInsets(horizontal: horizontal, vertical: vertical)
        return modified
    }
    
    /// Add a border
    public func border(_ color: Color, width: Float = 1) -> ModifiedView {
        let modified = wrap()
        modified.borderColor = color
        modified.borderWidth = width
        return modified
    }
    
    /// Set corner radius
    public func cornerRadius(_ radius: Float) -> ModifiedView {
        let modified = wrap()
        modified.cornerRadius = radius
        return modified
    }
    
    /// Set a fixed frame size
    public func frame(width: Float? = nil, height: Float? = nil) -> ModifiedView {
        let modified = wrap()
        modified.frameWidth = width
        modified.frameHeight = height
        return modified
    }
    
    /// Set minimum size constraints
    public func frame(minWidth: Float? = nil, minHeight: Float? = nil) -> ModifiedView {
        let modified = wrap()
        modified.minWidth = minWidth
        modified.minHeight = minHeight
        return modified
    }
    
    /// Set maximum size constraints
    public func frame(maxWidth: Float? = nil, maxHeight: Float? = nil) -> ModifiedView {
        let modified = wrap()
        modified.maxWidth = maxWidth
        modified.maxHeight = maxHeight
        return modified
    }
    
    /// Set opacity
    public func opacity(_ value: Float) -> ModifiedView {
        let modified = wrap()
        modified.opacity = value
        return modified
    }
    
    /// Helper to wrap self in a ModifiedView
    private func wrap() -> ModifiedView {
        if let already = self as? ModifiedView {
            return already
        }
        return ModifiedView(self)
    }
}

// MARK: - ModifiedView chaining

extension ModifiedView {
    /// Add a background color
    public func background(_ color: Color) -> ModifiedView {
        self.backgroundColor = color
        return self
    }
    
    /// Add padding on all sides
    public func padding(_ value: Float) -> ModifiedView {
        self.padding = EdgeInsets(value)
        return self
    }
    
    /// Add padding with specific insets
    public func padding(_ insets: EdgeInsets) -> ModifiedView {
        self.padding = insets
        return self
    }
    
    /// Add horizontal and vertical padding
    public func padding(horizontal: Float = 0, vertical: Float = 0) -> ModifiedView {
        self.padding = EdgeInsets(horizontal: horizontal, vertical: vertical)
        return self
    }
    
    /// Add a border
    public func border(_ color: Color, width: Float = 1) -> ModifiedView {
        self.borderColor = color
        self.borderWidth = width
        return self
    }
    
    /// Set corner radius
    public func cornerRadius(_ radius: Float) -> ModifiedView {
        self.cornerRadius = radius
        return self
    }
    
    /// Set a fixed frame size
    public func frame(width: Float? = nil, height: Float? = nil) -> ModifiedView {
        if let w = width { self.frameWidth = w }
        if let h = height { self.frameHeight = h }
        return self
    }
    
    /// Set minimum size constraints
    public func frame(minWidth: Float? = nil, minHeight: Float? = nil) -> ModifiedView {
        if let w = minWidth { self.minWidth = w }
        if let h = minHeight { self.minHeight = h }
        return self
    }
    
    /// Set maximum size constraints  
    public func frame(maxWidth: Float? = nil, maxHeight: Float? = nil) -> ModifiedView {
        if let w = maxWidth { self.maxWidth = w }
        if let h = maxHeight { self.maxHeight = h }
        return self
    }
    
    /// Set opacity
    public func opacity(_ value: Float) -> ModifiedView {
        self.opacity = value
        return self
    }
}
