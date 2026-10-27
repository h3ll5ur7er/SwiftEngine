/// Combine builder output into a single view
@MainActor
private func singleView(_ views: [any View]) -> any View {
    views.count == 1 ? views[0] : VStack(children: views)
}

/// A view that shows one of two views, re-checking the condition every time it is
/// measured, rendered or receives input. Each branch is built once and kept, so
/// controls inside keep their state (e.g. a pressed button).
@MainActor
public final class ConditionalView: View {
    
    private let condition: () -> Bool
    private let trueBuilder: () -> [any View]
    private let falseBuilder: () -> [any View]
    private var trueContent: (any View)?
    private var falseContent: (any View)?
    
    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ViewBuilder then trueContent: @escaping () -> [any View],
        @ViewBuilder else falseContent: @escaping () -> [any View]
    ) {
        self.condition = condition
        self.trueBuilder = trueContent
        self.falseBuilder = falseContent
    }
    
    /// The branch selected by the current condition
    private var current: any View {
        if condition() {
            if trueContent == nil { trueContent = singleView(trueBuilder()) }
            return trueContent!
        } else {
            if falseContent == nil { falseContent = singleView(falseBuilder()) }
            return falseContent!
        }
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        current.sizeThatFits(proposal)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        current.render(in: bounds, context: context)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        current.handleMouse(event, in: bounds)
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        current.handleKeyboard(event)
    }
}

/// A view that shows its content only while a condition holds (re-checked every time
/// it is measured, rendered or receives input). The content is built once and kept.
@MainActor
public final class OptionalView: View {
    
    private let condition: () -> Bool
    private let builder: () -> [any View]
    private var content: (any View)?
    
    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ViewBuilder content: @escaping () -> [any View]
    ) {
        self.condition = condition
        self.builder = content
    }
    
    /// The content, or nil while the condition is false
    private var visibleContent: (any View)? {
        guard condition() else { return nil }
        if content == nil { content = singleView(builder()) }
        return content
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        visibleContent?.sizeThatFits(proposal) ?? .zero
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        visibleContent?.render(in: bounds, context: context)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        visibleContent?.handleMouse(event, in: bounds) ?? false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        visibleContent?.handleKeyboard(event) ?? false
    }
}

// MARK: - Convenience Functions

/// Show content only when condition is true
@MainActor
public func If(
    _ condition: @escaping @autoclosure () -> Bool,
    @ViewBuilder then content: @escaping () -> [any View]
) -> OptionalView {
    OptionalView(condition(), content: content)
}

/// Show one of two views based on condition
@MainActor
public func If(
    _ condition: @escaping @autoclosure () -> Bool,
    @ViewBuilder then trueContent: @escaping () -> [any View],
    @ViewBuilder else falseContent: @escaping () -> [any View]
) -> ConditionalView {
    ConditionalView(condition(), then: trueContent, else: falseContent)
}
