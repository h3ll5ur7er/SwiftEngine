

/// Result builder for creating arrays of views in a SwiftUI-like syntax
@resultBuilder
@MainActor
public struct ViewBuilder {
    /// Build from multiple view arrays (main workhorse)
    public static func buildBlock(_ components: [any View]...) -> [any View] {
        components.flatMap { $0 }
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
