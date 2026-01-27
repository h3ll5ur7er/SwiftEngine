import Foundation


/// A slider control for selecting a value in a range
@MainActor
public final class Slider: View {
    /// Current value
    public var value: Float {
        didSet {
            value = clampValue(value)
            if value != oldValue {
                onChanged?(value)
                valueBinding?.wrappedValue = value
            }
        }
    }
    
    /// Minimum value
    public var minValue: Float
    
    /// Maximum value
    public var maxValue: Float
    
    /// Step size (0 = continuous)
    public var step: Float
    
    /// Track color
    public var trackColor: Color
    
    /// Filled track color (from min to current value)
    public var fillColor: Color
    
    /// Thumb color
    public var thumbColor: Color
    
    /// Thumb color when dragging
    public var activeThumbColor: Color
    
    /// Track height
    public var trackHeight: Float = 6
    
    /// Thumb radius
    public var thumbRadius: Float = 10
    
    /// Total width
    public var width: Float = 200
    
    /// Whether currently dragging
    private var isDragging: Bool = false
    
    /// Hover state
    private var isHovered: Bool = false
    
    /// Callback when value changes
    public var onChanged: ((Float) -> Void)?
    
    /// Callback when dragging ends
    public var onEditingChanged: ((Bool) -> Void)?
    
    /// Optional binding for two-way value synchronization
    private var valueBinding: Binding<Float>?
    
    public init(value: Float = 0, in range: ClosedRange<Float> = 0...1, step: Float = 0) {
        self.minValue = range.lowerBound
        self.maxValue = range.upperBound
        self.step = step
        self.value = value
        self.trackColor = Color(r: 60, g: 60, b: 60)
        self.fillColor = .cornflowerBlue
        self.thumbColor = .white
        self.activeThumbColor = Color(r: 220, g: 220, b: 220)
    }
    
    /// Initialize with a binding for two-way value synchronization
    public init(value: Binding<Float>, range: ClosedRange<Float> = 0...1, step: Float = 0) {
        self.minValue = range.lowerBound
        self.maxValue = range.upperBound
        self.step = step
        self.valueBinding = value
        self.value = value.wrappedValue
        self.trackColor = Color(r: 60, g: 60, b: 60)
        self.fillColor = .cornflowerBlue
        self.thumbColor = .white
        self.activeThumbColor = Color(r: 220, g: 220, b: 220)
    }
    
    private func clampValue(_ v: Float) -> Float {
        var clamped = max(minValue, min(maxValue, v))
        if step > 0 {
            clamped = (clamped / step).rounded() * step
        }
        return clamped
    }
    
    private func normalizedValue() -> Float {
        guard maxValue > minValue else { return 0 }
        return (value - minValue) / (maxValue - minValue)
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        let height = max(trackHeight, thumbRadius * 2)
        return Size(width: proposal.width ?? width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        let effectiveWidth = bounds.width
        let centerY = bounds.y + bounds.height / 2
        
        // Draw track background
        let trackY = centerY - trackHeight / 2
        let trackBounds = UIRect(x: bounds.x, y: trackY, width: effectiveWidth, height: trackHeight)
        context.fillRoundedRect(trackBounds, color: trackColor, cornerRadius: trackHeight / 2)
        
        // Draw filled portion
        let fillWidth = effectiveWidth * normalizedValue()
        if fillWidth > 0 {
            let fillBounds = UIRect(x: bounds.x, y: trackY, width: fillWidth, height: trackHeight)
            context.fillRoundedRect(fillBounds, color: fillColor, cornerRadius: trackHeight / 2)
        }
        
        // Calculate thumb position
        let thumbX = bounds.x + (effectiveWidth - thumbRadius * 2) * normalizedValue() + thumbRadius
        
        // Draw thumb
        let thumbCol: Color
        if isDragging {
            thumbCol = activeThumbColor
        } else if isHovered {
            thumbCol = thumbColor.scaled(by: 0.95)
        } else {
            thumbCol = thumbColor
        }
        
        context.fillCircle(center: (thumbX, centerY), radius: thumbRadius, color: thumbCol)
        
        // Draw thumb border
        // (simplified - would need stroke circle for proper border)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let effectiveWidth = bounds.width
        let centerY = bounds.y + bounds.height / 2
        let thumbX = bounds.x + (effectiveWidth - thumbRadius * 2) * normalizedValue() + thumbRadius
        
        // Check if mouse is over thumb
        let dx = event.x - thumbX
        let dy = event.y - centerY
        let distanceToThumb = sqrt(dx * dx + dy * dy)
        let overThumb = distanceToThumb <= thumbRadius + 4  // Small hit area padding
        
        // Check if mouse is over track
        let overTrack = bounds.contains(x: event.x, y: event.y)
        
        switch event.type {
        case .moved:
            isHovered = overThumb || overTrack
            if isDragging {
                updateValueFromMouse(event.x, in: bounds)
                return true
            }
            return false
            
        case .pressed(.left):
            if overThumb || overTrack {
                isDragging = true
                onEditingChanged?(true)
                updateValueFromMouse(event.x, in: bounds)
                return true
            }
            
        case .released(.left):
            if isDragging {
                isDragging = false
                onEditingChanged?(false)
                return true
            }
            
        default:
            break
        }
        
        return false
    }
    
    private func updateValueFromMouse(_ mouseX: Float, in bounds: UIRect) {
        let effectiveWidth = bounds.width - thumbRadius * 2
        guard effectiveWidth > 0 else { return }
        
        let relativeX = mouseX - bounds.x - thumbRadius
        let normalized = max(0, min(1, relativeX / effectiveWidth))
        value = minValue + normalized * (maxValue - minValue)
    }
}

// MARK: - Fluent Modifiers

extension Slider {
    /// Set the value range
    public func range(_ range: ClosedRange<Float>) -> Slider {
        self.minValue = range.lowerBound
        self.maxValue = range.upperBound
        return self
    }
    
    /// Set the step size
    public func step(_ step: Float) -> Slider {
        self.step = step
        return self
    }
    
    /// Set the track color
    public func trackColor(_ color: Color) -> Slider {
        self.trackColor = color
        return self
    }
    
    /// Set the fill color
    public func fillColor(_ color: Color) -> Slider {
        self.fillColor = color
        return self
    }
    
    /// Set the thumb color
    public func thumbColor(_ color: Color) -> Slider {
        self.thumbColor = color
        return self
    }
    
    /// Set the width
    public func width(_ width: Float) -> Slider {
        self.width = width
        return self
    }
    
    /// Set value change callback
    public func onChange(_ action: @escaping (Float) -> Void) -> Slider {
        self.onChanged = action
        return self
    }
    
    /// Set editing changed callback
    public func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Slider {
        self.onEditingChanged = action
        return self
    }
}
