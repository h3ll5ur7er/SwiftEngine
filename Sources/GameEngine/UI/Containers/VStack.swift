

/// A view that divides space among its children vertically
@MainActor
public final class VStack: View {
    /// Child views
    public var children: [any View]
    
    /// Horizontal alignment of children
    public var alignment: HorizontalAlignment
    
    /// Spacing between children
    public var spacing: Float
    
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Float = 8,
        @ViewBuilder content: () -> [any View]
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = content()
    }
    
    /// Convenience initializer with array of views
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Float = 8,
        children: [any View]
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = children
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        guard !children.isEmpty else { return .zero }
        
        // Calculate sizes of all children
        let childSizes = layoutChildren(in: proposal)
        
        // Total height is sum of child heights plus spacing
        let totalHeight = childSizes.reduce(Float(0)) { $0 + $1.height }
            + Float(children.count - 1) * spacing
        
        // Width is the max child width
        let maxWidth = childSizes.reduce(Float(0)) { max($0, $1.width) }
        
        return Size(
            width: proposal.width ?? maxWidth,
            height: totalHeight
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !children.isEmpty else { return }
        
        // Calculate child sizes and positions
        let proposal = ProposedSize(bounds.size)
        let childSizes = layoutChildren(in: proposal)
        
        // Calculate total content height
        var totalHeight = childSizes.reduce(Float(0)) { $0 + $1.height }
        totalHeight += Float(children.count - 1) * spacing
        
        // Start position
        var y = bounds.y
        
        for (index, child) in children.enumerated() {
            let size = childSizes[index]
            
            // Calculate x position based on alignment
            let x = bounds.x + alignment.offset(childWidth: size.width, in: bounds.width)
            
            // Render child
            let childBounds = UIRect(x: x, y: y, width: size.width, height: size.height)
            child.render(in: childBounds, context: context)
            
            y += size.height + spacing
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !children.isEmpty else { return false }
        
        let proposal = ProposedSize(bounds.size)
        let childSizes = layoutChildren(in: proposal)
        
        var y = bounds.y
        
        for (index, child) in children.enumerated() {
            let size = childSizes[index]
            let x = bounds.x + alignment.offset(childWidth: size.width, in: bounds.width)
            let childBounds = UIRect(x: x, y: y, width: size.width, height: size.height)
            
            if childBounds.contains(x: event.x, y: event.y) {
                if child.handleMouse(event, in: childBounds) {
                    return true
                }
            }
            
            y += size.height + spacing
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        // Forward to all children (focused child handling will come later)
        for child in children {
            if child.handleKeyboard(event) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Private Helpers
    
    private func layoutChildren(in proposal: ProposedSize) -> [Size] {
        // First pass: measure non-spacer children
        var flexibleCount = 0
        var fixedHeight: Float = 0
        var sizes: [Size?] = Array(repeating: nil, count: children.count)
        
        for (index, child) in children.enumerated() {
            if child is Spacer {
                flexibleCount += 1
            } else {
                // Propose full width, unspecified height
                let childProposal = ProposedSize(width: proposal.width, height: nil)
                let size = child.sizeThatFits(childProposal)
                sizes[index] = size
                fixedHeight += size.height
            }
        }
        
        // Calculate remaining space for spacers
        let totalSpacing = Float(children.count - 1) * spacing
        let availableHeight = (proposal.height ?? .infinity) - fixedHeight - totalSpacing
        let spacerHeight = flexibleCount > 0 ? max(0, availableHeight / Float(flexibleCount)) : 0
        
        // Second pass: fill in spacer sizes
        for (index, child) in children.enumerated() {
            if child is Spacer {
                let spacer = child as! Spacer
                let height = max(spacer.minLength ?? 0, spacerHeight)
                sizes[index] = Size(width: proposal.width ?? 0, height: height)
            }
        }
        
        return sizes.compactMap { $0 }
    }
}
