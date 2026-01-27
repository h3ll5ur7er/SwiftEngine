

/// Global state for UI rendering
@MainActor
public enum UIGlobals {
    /// Current render context (set during render pass)
    public static var currentContext: UIRenderContext?
}
