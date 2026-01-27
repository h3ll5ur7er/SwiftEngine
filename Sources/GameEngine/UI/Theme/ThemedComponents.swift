

/// A view modifier that applies theme-based styling
@MainActor
public struct ThemedModifier: View {
    
    private let content: any View
    private let styleApplicator: (Theme) -> Void
    
    public init(content: any View, style: @escaping (Theme) -> Void) {
        self.content = content
        self.styleApplicator = style
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        return content.sizeThatFits(proposal)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        styleApplicator(ThemeManager.shared.current)
        content.render(in: bounds, context: context)
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        return content.handleMouse(event, in: bounds)
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        return content.handleKeyboard(event)
    }
}

// MARK: - Theme-Aware View Extensions

extension View {
    
    /// Apply a theme-based style to this view
    public func themed(_ style: @escaping (Theme) -> Void) -> ThemedModifier {
        ThemedModifier(content: self, style: style)
    }
}

// MARK: - Themed Component Builders

/// Helper for creating themed buttons
@MainActor
public func ThemedButton(
    _ title: String,
    style: ButtonStyle = .primary,
    action: @escaping () -> Void
) -> Button {
    let theme = ThemeManager.shared.current
    
    let button = Button(title, action: action)
    
    switch style {
    case .primary:
        return button
            .backgroundColor(theme.buttonBackground)
            .foregroundColor(theme.buttonText)
            .padding(theme.paddingMedium)
    case .secondary:
        return button
            .backgroundColor(theme.surfaceBackground)
            .foregroundColor(theme.textPrimary)
            .padding(theme.paddingMedium)
    case .destructive:
        return button
            .backgroundColor(theme.error)
            .foregroundColor(.white)
            .padding(theme.paddingMedium)
    case .ghost:
        return button
            .backgroundColor(.transparent)
            .foregroundColor(theme.primary)
            .padding(theme.paddingMedium)
    }
}

/// Button style variants
public enum ButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
}

/// Helper for creating themed text
@MainActor
public func ThemedText(
    _ content: String,
    style: TextStyle = .body
) -> Text {
    let theme = ThemeManager.shared.current
    
    let text = Text(content)
    
    switch style {
    case .title:
        return text
            .foregroundColor(theme.textPrimary)
            .fontSize(theme.titleFontScale)
    case .headline:
        return text
            .foregroundColor(theme.textPrimary)
            .fontSize(theme.fontScale + 1)
    case .body:
        return text
            .foregroundColor(theme.textPrimary)
            .fontSize(theme.fontScale)
    case .caption:
        return text
            .foregroundColor(theme.textSecondary)
            .fontSize(theme.fontScale)
    case .label:
        return text
            .foregroundColor(theme.textSecondary)
            .fontSize(theme.fontScale)
    }
}

/// Text style variants
public enum TextStyle {
    case title
    case headline
    case body
    case caption
    case label
}

/// Helper for creating themed dividers
@MainActor
public func ThemedDivider() -> Divider {
    let theme = ThemeManager.shared.current
    return Divider().color(theme.divider)
}

/// Helper for creating themed panels/cards
@MainActor
public func ThemedPanel(children: [any View]) -> ModifiedView {
    let theme = ThemeManager.shared.current
    return VStack(alignment: .leading, spacing: theme.spacingUnit * 2, children: children)
        .padding(theme.paddingMedium)
        .background(theme.surfaceBackground)
}
