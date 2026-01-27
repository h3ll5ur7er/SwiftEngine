

/// A checkbox control
@MainActor
public final class Checkbox: View {
    /// Current checked state
    public var isChecked: Bool {
        didSet {
            if isChecked != oldValue {
                onChanged?(isChecked)
                isCheckedBinding?.wrappedValue = isChecked
            }
        }
    }
    
    /// Optional binding for two-way state synchronization
    private var isCheckedBinding: Binding<Bool>?
    
    /// Optional label text
    public var label: String?
    
    /// Box size
    public var size: Float = 18
    
    /// Box background color
    public var backgroundColor: Color
    
    /// Box border color
    public var borderColor: Color
    
    /// Checkmark color
    public var checkColor: Color
    
    /// Label color
    public var labelColor: Color
    
    /// Hover state
    private var isHovered: Bool = false
    
    /// Callback when value changes
    public var onChanged: ((Bool) -> Void)?
    
    public init(_ label: String? = nil, isChecked: Bool = false) {
        self.label = label
        self.isChecked = isChecked
        self.backgroundColor = Color(r: 40, g: 40, b: 40)
        self.borderColor = Color(r: 80, g: 80, b: 80)
        self.checkColor = .cornflowerBlue
        self.labelColor = .white
    }
    
    /// Initialize with a binding for two-way state synchronization
    public init(_ label: String? = nil, isChecked: Binding<Bool>) {
        self.label = label
        self.isCheckedBinding = isChecked
        self.isChecked = isChecked.wrappedValue
        self.backgroundColor = Color(r: 40, g: 40, b: 40)
        self.borderColor = Color(r: 80, g: 80, b: 80)
        self.checkColor = .cornflowerBlue
        self.labelColor = .white
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        var width = size
        let height = size
        
        // Add label width if present
        if let label = label, let context = UIGlobals.currentContext {
            let labelSize = context.measureText(label)
            width += 8 + labelSize.width
        }
        
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Draw checkbox box
        let boxBounds = UIRect(x: bounds.x, y: bounds.y, width: size, height: size)
        
        // Background
        let bgColor = isHovered ? backgroundColor.scaled(by: 1.2) : backgroundColor
        context.fillRect(boxBounds, color: bgColor)
        
        // Border
        context.strokeRect(boxBounds, color: borderColor, lineWidth: 1)
        
        // Checkmark if checked
        if isChecked {
            // Draw a simple checkmark using lines
            let padding: Float = 4
            let x1 = bounds.x + padding
            let y1 = bounds.y + size / 2
            let x2 = bounds.x + size / 3
            let y2 = bounds.y + size - padding
            let x3 = bounds.x + size - padding
            let y3 = bounds.y + padding
            
            context.drawLine(from: (x1, y1), to: (x2, y2), color: checkColor)
            context.drawLine(from: (x2, y2), to: (x3, y3), color: checkColor)
        }
        
        // Draw label
        if let label = label {
            let labelX = bounds.x + size + 8
            let labelSize = context.measureText(label)
            let labelY = bounds.y + (size - labelSize.height) / 2
            context.drawText(label, at: (labelX, labelY), color: labelColor)
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let boxBounds = UIRect(x: bounds.x, y: bounds.y, width: size, height: size)
        let inBox = boxBounds.contains(x: event.x, y: event.y)
        
        // Also allow clicking on label
        let inBounds = bounds.contains(x: event.x, y: event.y)
        
        switch event.type {
        case .moved:
            isHovered = inBox
            return false
            
        case .pressed(.left):
            if inBounds {
                isChecked.toggle()
                return true
            }
            
        case .released(.left):
            return inBounds
            
        default:
            break
        }
        
        return false
    }
}

// MARK: - Fluent Modifiers

extension Checkbox {
    /// Set the label
    public func label(_ text: String) -> Checkbox {
        self.label = text
        return self
    }
    
    /// Set the checkbox size
    public func size(_ size: Float) -> Checkbox {
        self.size = size
        return self
    }
    
    /// Set the check color
    public func checkColor(_ color: Color) -> Checkbox {
        self.checkColor = color
        return self
    }
    
    /// Set the background color
    public func backgroundColor(_ color: Color) -> Checkbox {
        self.backgroundColor = color
        return self
    }
    
    /// Set the label color
    public func labelColor(_ color: Color) -> Checkbox {
        self.labelColor = color
        return self
    }
    
    /// Set value change callback
    public func onChange(_ action: @escaping (Bool) -> Void) -> Checkbox {
        self.onChanged = action
        return self
    }
}
