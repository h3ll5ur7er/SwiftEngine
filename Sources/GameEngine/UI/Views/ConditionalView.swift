

/// A view that conditionally shows one of two views
@MainActor
public final class ConditionalView<TrueContent: View, FalseContent: View>: View {
    
    private let condition: () -> Bool
    private let trueContent: () -> TrueContent
    private let falseContent: () -> FalseContent
    
    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ViewBuilder then trueContent: @escaping () -> TrueContent,
        @ViewBuilder else falseContent: @escaping () -> FalseContent
    ) {
        self.condition = condition
        self.trueContent = trueContent
        self.falseContent = falseContent
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        if condition() {
            return trueContent().sizeThatFits(proposal)
        } else {
            return falseContent().sizeThatFits(proposal)
        }
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        if condition() {
            trueContent().render(in: bounds, context: context)
        } else {
            falseContent().render(in: bounds, context: context)
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        if condition() {
            return trueContent().handleMouse(event, in: bounds)
        } else {
            return falseContent().handleMouse(event, in: bounds)
        }
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        if condition() {
            return trueContent().handleKeyboard(event)
        } else {
            return falseContent().handleKeyboard(event)
        }
    }
}

/// A view that optionally shows content
@MainActor
public final class OptionalView<Content: View>: View {
    
    private let condition: () -> Bool
    private let content: () -> Content
    
    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.condition = condition
        self.content = content
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        if condition() {
            return content().sizeThatFits(proposal)
        }
        return .zero
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        if condition() {
            content().render(in: bounds, context: context)
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        if condition() {
            return content().handleMouse(event, in: bounds)
        }
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        if condition() {
            return content().handleKeyboard(event)
        }
        return false
    }
}

// MARK: - Convenience Functions

/// Show content only when condition is true
@MainActor
public func If<Content: View>(
    _ condition: @escaping @autoclosure () -> Bool,
    @ViewBuilder then content: @escaping () -> Content
) -> OptionalView<Content> {
    OptionalView(condition(), content: content)
}

/// Show one of two views based on condition
@MainActor
public func If<TrueContent: View, FalseContent: View>(
    _ condition: @escaping @autoclosure () -> Bool,
    @ViewBuilder then trueContent: @escaping () -> TrueContent,
    @ViewBuilder else falseContent: @escaping () -> FalseContent
) -> ConditionalView<TrueContent, FalseContent> {
    ConditionalView(condition(), then: trueContent, else: falseContent)
}
