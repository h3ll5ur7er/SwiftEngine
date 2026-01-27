

/// Defines the visual appearance of UI elements
@MainActor
public struct Theme: Sendable {
    
    // MARK: - Colors
    
    /// Primary brand color
    public var primary: Color
    
    /// Secondary/accent color
    public var secondary: Color
    
    /// Background colors
    public var background: Color
    public var surfaceBackground: Color
    public var elevatedBackground: Color
    
    /// Text colors
    public var textPrimary: Color
    public var textSecondary: Color
    public var textDisabled: Color
    public var textOnPrimary: Color
    
    /// Border/divider colors
    public var border: Color
    public var divider: Color
    
    /// State colors
    public var success: Color
    public var warning: Color
    public var error: Color
    public var info: Color
    
    /// Interactive state colors
    public var hoverOverlay: Color
    public var pressedOverlay: Color
    public var focusRing: Color
    
    // MARK: - Typography
    
    /// Default font scale
    public var fontScale: Int
    
    /// Title font scale
    public var titleFontScale: Int
    
    // MARK: - Spacing
    
    /// Base spacing unit
    public var spacingUnit: Float
    
    /// Standard padding
    public var paddingSmall: Float
    public var paddingMedium: Float
    public var paddingLarge: Float
    
    // MARK: - Sizing
    
    /// Corner radius
    public var cornerRadiusSmall: Float
    public var cornerRadiusMedium: Float
    public var cornerRadiusLarge: Float
    
    /// Border width
    public var borderWidth: Float
    
    /// Control heights
    public var controlHeightSmall: Float
    public var controlHeightMedium: Float
    public var controlHeightLarge: Float
    
    // MARK: - Component-Specific
    
    /// Button
    public var buttonBackground: Color
    public var buttonBackgroundHover: Color
    public var buttonBackgroundPressed: Color
    public var buttonText: Color
    
    /// TextField
    public var textFieldBackground: Color
    public var textFieldBorder: Color
    public var textFieldBorderFocused: Color
    public var textFieldPlaceholder: Color
    
    /// Toggle
    public var toggleOffBackground: Color
    public var toggleOnBackground: Color
    public var toggleThumb: Color
    
    /// Slider
    public var sliderTrack: Color
    public var sliderFill: Color
    public var sliderThumb: Color
    
    /// Scrollbar
    public var scrollbarTrack: Color
    public var scrollbarThumb: Color
    public var scrollbarThumbHover: Color
    
    /// Dropdown
    public var dropdownBackground: Color
    public var dropdownItemHover: Color
    
    // MARK: - Initialization
    
    public init(
        primary: Color = .cornflowerBlue,
        secondary: Color = .cyan,
        background: Color = Color(r: 30, g: 30, b: 30),
        surfaceBackground: Color = Color(r: 40, g: 40, b: 40),
        elevatedBackground: Color = Color(r: 50, g: 50, b: 50),
        textPrimary: Color = .white,
        textSecondary: Color = .lightGray,
        textDisabled: Color = .gray,
        textOnPrimary: Color = .white,
        border: Color = Color(r: 70, g: 70, b: 70),
        divider: Color = Color(r: 50, g: 50, b: 50),
        success: Color = .green,
        warning: Color = .orange,
        error: Color = .red,
        info: Color = .cornflowerBlue,
        hoverOverlay: Color = Color(r: 255, g: 255, b: 255, a: 20),
        pressedOverlay: Color = Color(r: 0, g: 0, b: 0, a: 40),
        focusRing: Color = .cornflowerBlue,
        fontScale: Int = 1,
        titleFontScale: Int = 2,
        spacingUnit: Float = 4,
        paddingSmall: Float = 4,
        paddingMedium: Float = 8,
        paddingLarge: Float = 16,
        cornerRadiusSmall: Float = 2,
        cornerRadiusMedium: Float = 4,
        cornerRadiusLarge: Float = 8,
        borderWidth: Float = 1,
        controlHeightSmall: Float = 24,
        controlHeightMedium: Float = 32,
        controlHeightLarge: Float = 40
    ) {
        self.primary = primary
        self.secondary = secondary
        self.background = background
        self.surfaceBackground = surfaceBackground
        self.elevatedBackground = elevatedBackground
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textDisabled = textDisabled
        self.textOnPrimary = textOnPrimary
        self.border = border
        self.divider = divider
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.hoverOverlay = hoverOverlay
        self.pressedOverlay = pressedOverlay
        self.focusRing = focusRing
        self.fontScale = fontScale
        self.titleFontScale = titleFontScale
        self.spacingUnit = spacingUnit
        self.paddingSmall = paddingSmall
        self.paddingMedium = paddingMedium
        self.paddingLarge = paddingLarge
        self.cornerRadiusSmall = cornerRadiusSmall
        self.cornerRadiusMedium = cornerRadiusMedium
        self.cornerRadiusLarge = cornerRadiusLarge
        self.borderWidth = borderWidth
        self.controlHeightSmall = controlHeightSmall
        self.controlHeightMedium = controlHeightMedium
        self.controlHeightLarge = controlHeightLarge
        
        // Derive component colors from base colors
        self.buttonBackground = primary
        self.buttonBackgroundHover = primary.lighter(by: 0.1)
        self.buttonBackgroundPressed = primary.darker(by: 0.1)
        self.buttonText = textOnPrimary
        
        self.textFieldBackground = surfaceBackground
        self.textFieldBorder = border
        self.textFieldBorderFocused = primary
        self.textFieldPlaceholder = textDisabled
        
        self.toggleOffBackground = Color(r: 80, g: 80, b: 80)
        self.toggleOnBackground = success
        self.toggleThumb = .white
        
        self.sliderTrack = Color(r: 60, g: 60, b: 60)
        self.sliderFill = primary
        self.sliderThumb = .white
        
        self.scrollbarTrack = Color(r: 40, g: 40, b: 40)
        self.scrollbarThumb = Color(r: 80, g: 80, b: 80)
        self.scrollbarThumbHover = Color(r: 100, g: 100, b: 100)
        
        self.dropdownBackground = elevatedBackground
        self.dropdownItemHover = primary
    }
}

// MARK: - Built-in Themes

extension Theme {
    
    /// Default dark theme
    public static let dark = Theme()
    
    /// Light theme
    public static let light = Theme(
        primary: Color(r: 0, g: 122, b: 255),
        secondary: Color(r: 88, g: 86, b: 214),
        background: Color(r: 242, g: 242, b: 247),
        surfaceBackground: .white,
        elevatedBackground: .white,
        textPrimary: .black,
        textSecondary: Color(r: 60, g: 60, b: 67),
        textDisabled: Color(r: 142, g: 142, b: 147),
        textOnPrimary: .white,
        border: Color(r: 209, g: 209, b: 214),
        divider: Color(r: 229, g: 229, b: 234),
        success: Color(r: 52, g: 199, b: 89),
        warning: Color(r: 255, g: 149, b: 0),
        error: Color(r: 255, g: 59, b: 48),
        info: Color(r: 0, g: 122, b: 255)
    )
    
    /// High contrast dark theme
    public static let highContrastDark = Theme(
        primary: Color(r: 64, g: 156, b: 255),
        secondary: .cyan,
        background: .black,
        surfaceBackground: Color(r: 20, g: 20, b: 20),
        elevatedBackground: Color(r: 30, g: 30, b: 30),
        textPrimary: .white,
        textSecondary: Color(r: 220, g: 220, b: 220),
        textDisabled: Color(r: 150, g: 150, b: 150),
        border: Color(r: 100, g: 100, b: 100),
        divider: Color(r: 80, g: 80, b: 80)
    )
    
    /// Cyberpunk/neon theme
    public static let cyberpunk = Theme(
        primary: Color(r: 255, g: 0, b: 128),
        secondary: .cyan,
        background: Color(r: 10, g: 10, b: 20),
        surfaceBackground: Color(r: 20, g: 20, b: 35),
        elevatedBackground: Color(r: 30, g: 30, b: 50),
        textPrimary: .white,
        textSecondary: .cyan,
        textDisabled: Color(r: 100, g: 100, b: 120),
        border: Color(r: 255, g: 0, b: 128, a: 128),
        divider: Color(r: 255, g: 0, b: 128, a: 64),
        success: .cyan,
        warning: .yellow,
        error: Color(r: 255, g: 50, b: 50),
        info: Color(r: 0, g: 200, b: 255),
        focusRing: .cyan
    )
    
    /// Forest/nature theme
    public static let forest = Theme(
        primary: Color(r: 76, g: 175, b: 80),
        secondary: Color(r: 139, g: 195, b: 74),
        background: Color(r: 27, g: 38, b: 29),
        surfaceBackground: Color(r: 35, g: 50, b: 38),
        elevatedBackground: Color(r: 45, g: 62, b: 48),
        textPrimary: Color(r: 230, g: 245, b: 230),
        textSecondary: Color(r: 180, g: 210, b: 180),
        textDisabled: Color(r: 120, g: 140, b: 120),
        border: Color(r: 76, g: 100, b: 76),
        divider: Color(r: 60, g: 80, b: 60),
        success: Color(r: 139, g: 195, b: 74),
        warning: Color(r: 255, g: 193, b: 7),
        error: Color(r: 244, g: 67, b: 54)
    )
    
    /// Ocean/blue theme
    public static let ocean = Theme(
        primary: Color(r: 33, g: 150, b: 243),
        secondary: Color(r: 0, g: 188, b: 212),
        background: Color(r: 15, g: 25, b: 35),
        surfaceBackground: Color(r: 20, g: 35, b: 50),
        elevatedBackground: Color(r: 30, g: 50, b: 70),
        textPrimary: .white,
        textSecondary: Color(r: 144, g: 202, b: 249),
        textDisabled: Color(r: 100, g: 130, b: 160),
        border: Color(r: 33, g: 100, b: 150),
        divider: Color(r: 30, g: 80, b: 120)
    )
}
