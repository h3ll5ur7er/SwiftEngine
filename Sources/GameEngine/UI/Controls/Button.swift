

/// A clickable button control
@MainActor
public final class Button: View {
    /// The button label
    public var label: any View
    
    /// Action to perform when clicked
    public var action: () -> Void
    
    /// Background color in normal state
    public var backgroundColor: Color
    
    /// Background color when hovered
    public var hoverColor: Color
    
    /// Background color when pressed
    public var pressedColor: Color
    
    /// Text/foreground color
    public var foregroundColor: Color
    
    /// Padding around the label
    public var padding: EdgeInsets
    
    /// Corner radius
    public var cornerRadius: Float
    
    /// Current state
    private var isHovered: Bool = false
    private var isPressed: Bool = false
    
    public init(_ title: String, action: @escaping () -> Void) {
        self.label = Text(title).foregroundColor(.white)
        self.action = action
        self.backgroundColor = Color(r: 60, g: 60, b: 60)
        self.hoverColor = Color(r: 80, g: 80, b: 80)
        self.pressedColor = Color(r: 40, g: 40, b: 40)
        self.foregroundColor = .white
        self.padding = EdgeInsets(horizontal: 16, vertical: 8)
        self.cornerRadius = 4
    }
    
    /// Create button with custom content
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> [any View]) {
        let views = label()
        if views.count == 1 {
            self.label = views[0]
        } else {
            self.label = HStack(children: views)
        }
        self.action = action
        self.backgroundColor = Color(r: 60, g: 60, b: 60)
        self.hoverColor = Color(r: 80, g: 80, b: 80)
        self.pressedColor = Color(r: 40, g: 40, b: 40)
        self.foregroundColor = .white
        self.padding = EdgeInsets(horizontal: 16, vertical: 8)
        self.cornerRadius = 4
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Button size = label size + padding
        let innerProposal = ProposedSize(
            width: proposal.width.map { $0 - padding.horizontal },
            height: proposal.height.map { $0 - padding.vertical }
        )
        let labelSize = label.sizeThatFits(innerProposal)
        
        return Size(
            width: labelSize.width + padding.horizontal,
            height: labelSize.height + padding.vertical
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Determine current background color based on state
        let bgColor: Color
        if isPressed {
            bgColor = pressedColor
        } else if isHovered {
            bgColor = hoverColor
        } else {
            bgColor = backgroundColor
        }
        
        // Draw background
        if cornerRadius > 0 {
            context.fillRoundedRect(bounds, color: bgColor, cornerRadius: cornerRadius)
        } else {
            context.fillRect(bounds, color: bgColor)
        }
        
        // Draw label centered
        let innerBounds = bounds.inset(by: padding)
        let labelSize = label.sizeThatFits(ProposedSize(innerBounds.size))
        
        let labelBounds = UIRect(
            x: innerBounds.x + (innerBounds.width - labelSize.width) / 2,
            y: innerBounds.y + (innerBounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        label.render(in: labelBounds, context: context)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let wasInBounds = bounds.contains(x: event.x, y: event.y)
        
        switch event.type {
        case .moved:
            isHovered = wasInBounds
            return false
            
        case .pressed(.left):
            if wasInBounds {
                isPressed = true
                return true
            }
            return false
            
        case .released(.left):
            if isPressed && wasInBounds {
                action()
            }
            isPressed = false
            return wasInBounds
            
        default:
            return false
        }
    }
}

// MARK: - Fluent Modifiers

extension Button {
    /// Set the background color
    public func backgroundColor(_ color: Color) -> Button {
        self.backgroundColor = color
        self.hoverColor = color.scaled(by: 1.2)
        self.pressedColor = color.scaled(by: 0.8)
        return self
    }
    
    /// Set the foreground (text) color
    public func foregroundColor(_ color: Color) -> Button {
        self.foregroundColor = color
        if let text = label as? Text {
            _ = text.foregroundColor(color)
        }
        return self
    }
    
    /// Set the padding
    public func padding(_ insets: EdgeInsets) -> Button {
        self.padding = insets
        return self
    }
    
    /// Set uniform padding
    public func padding(_ value: Float) -> Button {
        self.padding = EdgeInsets(value)
        return self
    }
    
    /// Set the corner radius
    public func cornerRadius(_ radius: Float) -> Button {
        self.cornerRadius = radius
        return self
    }
}
