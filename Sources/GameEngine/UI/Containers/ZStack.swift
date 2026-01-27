

/// A view that overlays its children on top of each other
@MainActor
public final class ZStack: View {
    /// Child views (first = bottom, last = top)
    public var children: [any View]
    
    /// Alignment for positioning children
    public var alignment: Alignment
    
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> [any View]
    ) {
        self.alignment = alignment
        self.children = content()
    }
    
    /// Convenience initializer with array of views
    public init(
        alignment: Alignment = .center,
        children: [any View]
    ) {
        self.alignment = alignment
        self.children = children
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        guard !children.isEmpty else { return .zero }
        
        // ZStack size is the union of all child sizes
        var maxWidth: Float = 0
        var maxHeight: Float = 0
        
        for child in children {
            let size = child.sizeThatFits(proposal)
            maxWidth = max(maxWidth, size.width)
            maxHeight = max(maxHeight, size.height)
        }
        
        return Size(
            width: proposal.width ?? maxWidth,
            height: proposal.height ?? maxHeight
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        let proposal = ProposedSize(bounds.size)
        
        // Render children from bottom to top
        for child in children {
            let childSize = child.sizeThatFits(proposal)
            let offset = alignment.offset(childSize: childSize, in: bounds.size)
            
            let childBounds = UIRect(
                x: bounds.x + offset.x,
                y: bounds.y + offset.y,
                width: childSize.width,
                height: childSize.height
            )
            
            child.render(in: childBounds, context: context)
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let proposal = ProposedSize(bounds.size)
        
        // Handle events from top to bottom (reverse order)
        for child in children.reversed() {
            let childSize = child.sizeThatFits(proposal)
            let offset = alignment.offset(childSize: childSize, in: bounds.size)
            
            let childBounds = UIRect(
                x: bounds.x + offset.x,
                y: bounds.y + offset.y,
                width: childSize.width,
                height: childSize.height
            )
            
            if childBounds.contains(x: event.x, y: event.y) {
                if child.handleMouse(event, in: childBounds) {
                    return true
                }
            }
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        // Forward to children (top to bottom)
        for child in children.reversed() {
            if child.handleKeyboard(event) {
                return true
            }
        }
        return false
    }
}
