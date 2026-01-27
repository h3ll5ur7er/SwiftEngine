

/// Manages the current theme and provides theme access throughout the UI
@MainActor
public final class ThemeManager {
    
    /// Shared instance
    public static let shared = ThemeManager()
    
    /// The current active theme
    public var current: Theme {
        didSet {
            notifyThemeChanged()
        }
    }
    
    /// Theme change observers
    private var observers: [() -> Void] = []
    
    private init() {
        self.current = .dark
    }
    
    /// Set the current theme
    public func setTheme(_ theme: Theme) {
        current = theme
    }
    
    /// Add an observer for theme changes
    public func onThemeChanged(_ observer: @escaping () -> Void) {
        observers.append(observer)
    }
    
    /// Remove all observers
    public func removeAllObservers() {
        observers.removeAll()
    }
    
    private func notifyThemeChanged() {
        for observer in observers {
            observer()
        }
    }
}

// MARK: - Theme Environment

/// Provides access to the current theme in views
@MainActor
public struct ThemeEnvironment {
    
    /// Get the current theme
    public static var current: Theme {
        ThemeManager.shared.current
    }
    
    /// Convenience accessors for common theme values
    public static var primary: Color { current.primary }
    public static var secondary: Color { current.secondary }
    public static var background: Color { current.background }
    public static var surface: Color { current.surfaceBackground }
    public static var text: Color { current.textPrimary }
    public static var textSecondary: Color { current.textSecondary }
    public static var border: Color { current.border }
    public static var divider: Color { current.divider }
    public static var success: Color { current.success }
    public static var warning: Color { current.warning }
    public static var error: Color { current.error }
}
