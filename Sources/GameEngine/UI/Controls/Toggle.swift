

/// A toggle switch control
@MainActor
public final class Toggle: View {
    /// Current on/off state
    public var isOn: Bool {
        didSet {
            if isOn != oldValue {
                onChanged?(isOn)
                isOnBinding?.wrappedValue = isOn
            }
        }
    }
    
    /// Optional binding for two-way state synchronization
    private var isOnBinding: Binding<Bool>?
    
    /// Optional label
    public var label: String?
    
    /// Track color when off
    public var offColor: Color
    
    /// Track color when on
    public var onColor: Color
    
    /// Thumb (knob) color
    public var thumbColor: Color
    
    /// Label color
    public var labelColor: Color
    
    /// Size of the toggle track
    public var trackWidth: Float = 44
    public var trackHeight: Float = 24
    
    /// Animation progress (0 = off, 1 = on)
    private var animationProgress: Float = 0
    
    /// Callback when value changes
    public var onChanged: ((Bool) -> Void)?
    
    /// Hover state
    private var isHovered: Bool = false
    
    public init(_ label: String? = nil, isOn: Bool = false) {
        self.label = label
        self.isOn = isOn
        self.animationProgress = isOn ? 1 : 0
        self.offColor = Color(r: 60, g: 60, b: 60)
        self.onColor = .cornflowerBlue
        self.thumbColor = .white
        self.labelColor = .white
    }
    
    /// Initialize with a binding for two-way state synchronization
    public init(_ label: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.isOnBinding = isOn
        self.isOn = isOn.wrappedValue
        self.animationProgress = self.isOn ? 1 : 0
        self.offColor = Color(r: 60, g: 60, b: 60)
        self.onColor = .cornflowerBlue
        self.thumbColor = .white
        self.labelColor = .white
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        var width = trackWidth
        let height = trackHeight
        
        // Add label width if present
        if let label = label, let context = UIGlobals.currentContext {
            let labelSize = context.measureText(label)
            width += 8 + labelSize.width  // 8px spacing
        }
        
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Animate towards target state
        let target: Float = isOn ? 1 : 0
        let speed: Float = 0.15
        if animationProgress < target {
            animationProgress = min(target, animationProgress + speed)
        } else if animationProgress > target {
            animationProgress = max(target, animationProgress - speed)
        }
        
        // Calculate track position
        var trackX = bounds.x
        
        // Draw label first (on the left)
        if let label = label {
            let labelSize = context.measureText(label)
            let labelY = bounds.y + (bounds.height - labelSize.height) / 2
            context.drawText(label, at: (bounds.x, labelY), color: labelColor)
            trackX = bounds.x + labelSize.width + 8
        }
        
        // Draw track background
        let trackBounds = UIRect(x: trackX, y: bounds.y, width: trackWidth, height: trackHeight)
        let trackColor = Color.lerp(offColor, onColor, t: animationProgress)
        
        // Draw rounded track (simplified as rectangle for now)
        context.fillRoundedRect(trackBounds, color: trackColor, cornerRadius: trackHeight / 2)
        
        // Calculate thumb position
        let thumbDiameter = trackHeight - 4
        let thumbTravel = trackWidth - thumbDiameter - 4
        let thumbX = trackX + 2 + thumbTravel * animationProgress
        let thumbY = bounds.y + 2
        
        // Draw thumb with hover effect
        let thumbCol = isHovered ? thumbColor.scaled(by: 0.9) : thumbColor
        context.fillCircle(
            center: (thumbX + thumbDiameter / 2, thumbY + thumbDiameter / 2),
            radius: thumbDiameter / 2,
            color: thumbCol
        )
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        // Calculate track bounds for hit testing
        var trackX = bounds.x
        if let label = label, let context = UIGlobals.currentContext {
            let labelSize = context.measureText(label)
            trackX = bounds.x + labelSize.width + 8
        }
        let trackBounds = UIRect(x: trackX, y: bounds.y, width: trackWidth, height: trackHeight)
        
        let inTrack = trackBounds.contains(x: event.x, y: event.y)
        
        switch event.type {
        case .moved:
            isHovered = inTrack
            return false
            
        case .pressed(.left):
            if inTrack {
                isOn.toggle()
                return true
            }
            
        case .released(.left):
            return inTrack
            
        default:
            break
        }
        
        return false
    }
}

// MARK: - Fluent Modifiers

extension Toggle {
    /// Set the label
    public func label(_ text: String) -> Toggle {
        self.label = text
        return self
    }
    
    /// Set the on color
    public func onColor(_ color: Color) -> Toggle {
        self.onColor = color
        return self
    }
    
    /// Set the off color
    public func offColor(_ color: Color) -> Toggle {
        self.offColor = color
        return self
    }
    
    /// Set the thumb color
    public func thumbColor(_ color: Color) -> Toggle {
        self.thumbColor = color
        return self
    }
    
    /// Set the label color
    public func labelColor(_ color: Color) -> Toggle {
        self.labelColor = color
        return self
    }
    
    /// Set value change callback
    public func onChange(_ action: @escaping (Bool) -> Void) -> Toggle {
        self.onChanged = action
        return self
    }
    
    /// Set custom size
    public func size(width: Float, height: Float) -> Toggle {
        self.trackWidth = width
        self.trackHeight = height
        return self
    }
}
