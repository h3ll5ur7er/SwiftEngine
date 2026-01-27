

/// A container that wraps an array of views as a single view
/// This allows ViewBuilder closures to be used where a single View is expected
@MainActor
public final class ViewGroup: View {
    
    private var children: [any View]
    
    public init(_ children: [any View]) {
        self.children = children
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        guard !children.isEmpty else { return .zero }
        
        // Stack vertically by default
        var totalHeight: Float = 0
        var maxWidth: Float = 0
        
        for child in children {
            let size = child.sizeThatFits(proposal)
            totalHeight += size.height
            maxWidth = max(maxWidth, size.width)
        }
        
        return Size(
            width: proposal.width ?? maxWidth,
            height: totalHeight
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !children.isEmpty else { return }
        
        // Stack children vertically
        var y = bounds.y
        for child in children {
            let size = child.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let childBounds = UIRect(
                x: bounds.x,
                y: y,
                width: bounds.width,
                height: size.height
            )
            child.render(in: childBounds, context: context)
            y += size.height
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !children.isEmpty else { return false }
        
        var y = bounds.y
        for child in children {
            let size = child.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let childBounds = UIRect(
                x: bounds.x,
                y: y,
                width: bounds.width,
                height: size.height
            )
            
            if event.y >= childBounds.y && event.y < childBounds.y + childBounds.height {
                if child.handleMouse(event, in: childBounds) {
                    return true
                }
            }
            y += size.height
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
}

// MARK: - SingleViewBuilder

/// A result builder that produces a single View from a closure
/// Use this when a single View is needed (e.g., ScrollView content)
@resultBuilder
@MainActor
public struct SingleViewBuilder {
    /// Build from multiple view arrays
    public static func buildBlock(_ components: [any View]...) -> any View {
        let flat = components.flatMap { $0 }
        if flat.count == 1 {
            return flat[0]
        }
        return ViewGroup(flat)
    }
    
    /// Build an optional view
    public static func buildOptional(_ component: [any View]?) -> [any View] {
        component ?? []
    }
    
    /// Build first branch of an if-else
    public static func buildEither(first component: [any View]) -> [any View] {
        component
    }
    
    /// Build second branch of an if-else
    public static func buildEither(second component: [any View]) -> [any View] {
        component
    }
    
    /// Build an array (for loops)
    public static func buildArray(_ components: [[any View]]) -> [any View] {
        components.flatMap { $0 }
    }
    
    /// Build expression (single view to array)
    public static func buildExpression(_ expression: any View) -> [any View] {
        [expression]
    }
    
    /// Build expression (array passthrough)
    public static func buildExpression(_ expression: [any View]) -> [any View] {
        expression
    }
}
