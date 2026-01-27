

/// A view that divides space among its children horizontally
@MainActor
public final class HStack: View {
    /// Child views
    public var children: [any View]
    
    /// Vertical alignment of children
    public var alignment: VerticalAlignment
    
    /// Spacing between children
    public var spacing: Float
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: Float = 8,
        @ViewBuilder content: () -> [any View]
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.children = content()
    }
    
    /// Convenience initializer with array of views
    public init(
        alignment: VerticalAlignment = .center,
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
        
        // Total width is sum of child widths plus spacing
        let totalWidth = childSizes.reduce(Float(0)) { $0 + $1.width }
            + Float(children.count - 1) * spacing
        
        // Height is the max child height
        let maxHeight = childSizes.reduce(Float(0)) { max($0, $1.height) }
        
        return Size(
            width: totalWidth,
            height: proposal.height ?? maxHeight
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !children.isEmpty else { return }
        
        // Calculate child sizes and positions
        let proposal = ProposedSize(bounds.size)
        let childSizes = layoutChildren(in: proposal)
        
        // Start position
        var x = bounds.x
        
        for (index, child) in children.enumerated() {
            let size = childSizes[index]
            
            // Calculate y position based on alignment
            let y = bounds.y + alignment.offset(childHeight: size.height, in: bounds.height)
            
            // Render child
            let childBounds = UIRect(x: x, y: y, width: size.width, height: size.height)
            child.render(in: childBounds, context: context)
            
            x += size.width + spacing
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !children.isEmpty else { return false }
        
        let proposal = ProposedSize(bounds.size)
        let childSizes = layoutChildren(in: proposal)
        
        var x = bounds.x
        
        for (index, child) in children.enumerated() {
            let size = childSizes[index]
            let y = bounds.y + alignment.offset(childHeight: size.height, in: bounds.height)
            let childBounds = UIRect(x: x, y: y, width: size.width, height: size.height)
            
            if childBounds.contains(x: event.x, y: event.y) {
                if child.handleMouse(event, in: childBounds) {
                    return true
                }
            }
            
            x += size.width + spacing
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
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
        var fixedWidth: Float = 0
        var sizes: [Size?] = Array(repeating: nil, count: children.count)
        
        for (index, child) in children.enumerated() {
            if child is Spacer {
                flexibleCount += 1
            } else {
                // Propose unspecified width, full height
                let childProposal = ProposedSize(width: nil, height: proposal.height)
                let size = child.sizeThatFits(childProposal)
                sizes[index] = size
                fixedWidth += size.width
            }
        }
        
        // Calculate remaining space for spacers
        let totalSpacing = Float(children.count - 1) * spacing
        let availableWidth = (proposal.width ?? .infinity) - fixedWidth - totalSpacing
        let spacerWidth = flexibleCount > 0 ? max(0, availableWidth / Float(flexibleCount)) : 0
        
        // Second pass: fill in spacer sizes
        for (index, child) in children.enumerated() {
            if child is Spacer {
                let spacer = child as! Spacer
                let width = max(spacer.minLength ?? 0, spacerWidth)
                sizes[index] = Size(width: width, height: proposal.height ?? 0)
            }
        }
        
        return sizes.compactMap { $0 }
    }
}
