

/// A simple progress bar
@MainActor
public final class ProgressBar: View {
    /// Current progress (0-1)
    public var progress: Float {
        didSet {
            progress = max(0, min(1, progress))
        }
    }
    
    /// Track color
    public var trackColor: Color
    
    /// Fill color
    public var fillColor: Color
    
    /// Height of the bar
    public var height: Float = 8
    
    /// Width of the bar
    public var width: Float = 200
    
    /// Corner radius
    public var cornerRadius: Float = 0
    
    public init(progress: Float = 0) {
        self.progress = max(0, min(1, progress))
        self.trackColor = Color(r: 50, g: 50, b: 50)
        self.fillColor = .cornflowerBlue
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        Size(width: proposal.width ?? width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Draw track
        context.fillRoundedRect(bounds, color: trackColor, cornerRadius: cornerRadius)
        
        // Draw fill
        if progress > 0 {
            let fillWidth = bounds.width * progress
            let fillBounds = UIRect(x: bounds.x, y: bounds.y, width: fillWidth, height: bounds.height)
            context.fillRoundedRect(fillBounds, color: fillColor, cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Fluent Modifiers

extension ProgressBar {
    /// Set the track color
    public func trackColor(_ color: Color) -> ProgressBar {
        self.trackColor = color
        return self
    }
    
    /// Set the fill color
    public func fillColor(_ color: Color) -> ProgressBar {
        self.fillColor = color
        return self
    }
    
    /// Set the bar height
    public func height(_ height: Float) -> ProgressBar {
        self.height = height
        return self
    }
    
    /// Set the bar width
    public func width(_ width: Float) -> ProgressBar {
        self.width = width
        return self
    }
    
    /// Set the corner radius
    public func cornerRadius(_ radius: Float) -> ProgressBar {
        self.cornerRadius = radius
        return self
    }
}
