# UI Theming

The theme system provides consistent styling across the UI framework.

## ThemeManager

A singleton that manages the current theme:

```swift
// Get current theme
let theme = ThemeManager.shared.current

// Set theme
ThemeManager.shared.setTheme(.dark)
ThemeManager.shared.setTheme(.light)

// Or use a custom theme
ThemeManager.shared.setTheme(myCustomTheme)
```

## Built-in Themes

### Dark Theme (Default)
```swift
ThemeManager.shared.setTheme(.dark)
```

### Light Theme
```swift
ThemeManager.shared.setTheme(.light)
```

### High Contrast Dark
```swift
ThemeManager.shared.setTheme(.highContrastDark)
```

### Cyberpunk
```swift
ThemeManager.shared.setTheme(.cyberpunk)
```

### Forest
```swift
ThemeManager.shared.setTheme(.forest)
```

### Ocean
```swift
ThemeManager.shared.setTheme(.ocean)
```

## Theme Properties

A `Theme` contains these color properties (plus typography, spacing and sizing values such as `fontScale`, `paddingMedium` and `cornerRadiusMedium`):

```swift
public struct Theme {
    // Accent colors
    public var primary: Color              // Primary brand color
    public var secondary: Color            // Secondary accent
    
    // Backgrounds
    public var background: Color           // Main background
    public var surfaceBackground: Color    // Panel/card background
    public var elevatedBackground: Color   // Raised surfaces (e.g. dropdowns)
    
    // Text
    public var textPrimary: Color          // Primary text
    public var textSecondary: Color        // Secondary/muted text
    public var textDisabled: Color         // Disabled text
    public var textOnPrimary: Color        // Text on primary-colored surfaces
    
    // Borders and dividers
    public var border: Color               // Border color
    public var divider: Color              // Divider lines
    
    // Semantic colors
    public var success: Color              // Success/positive
    public var warning: Color              // Warning/caution
    public var error: Color                // Error/negative
    public var info: Color                 // Informational
    
    // Interactive state colors
    public var hoverOverlay: Color
    public var pressedOverlay: Color
    public var focusRing: Color
    
    // Button colors
    public var buttonBackground: Color
    public var buttonBackgroundHover: Color
    public var buttonBackgroundPressed: Color
    public var buttonText: Color
    
    // TextField colors
    public var textFieldBackground: Color
    public var textFieldBorder: Color
    public var textFieldBorderFocused: Color
    public var textFieldPlaceholder: Color
    
    // Slider colors
    public var sliderTrack: Color
    public var sliderFill: Color
    public var sliderThumb: Color
    
    // Toggle, scrollbar and dropdown colors
    public var toggleOffBackground: Color
    public var toggleOnBackground: Color
    public var toggleThumb: Color
    public var scrollbarTrack: Color
    public var scrollbarThumb: Color
    public var scrollbarThumbHover: Color
    public var dropdownBackground: Color
    public var dropdownItemHover: Color
}
```

## Using Theme Colors

Access theme colors in your views:

```swift
func buildUI() -> some View {
    let theme = ThemeManager.shared.current
    
    return VStack {
        Text("Title")
            .foregroundColor(theme.textPrimary)
        
        Text("Subtitle")
            .foregroundColor(theme.textSecondary)
        
        Button("Action") { }
            .backgroundColor(theme.primary)
        
        Divider()
            .color(theme.divider)
    }
    .background(theme.background)
}
```

## Creating Custom Themes

All initializer parameters have defaults (the dark theme's values) and must be given in this order:

```swift
var myTheme = Theme(
    primary: Color(r: 100, g: 150, b: 255),
    secondary: Color(r: 150, g: 100, b: 255),
    
    background: Color(r: 20, g: 20, b: 30),
    surfaceBackground: Color(r: 30, g: 30, b: 40),
    elevatedBackground: Color(r: 40, g: 40, b: 50),
    
    textPrimary: .white,
    textSecondary: Color(r: 180, g: 180, b: 190),
    textDisabled: Color(r: 100, g: 100, b: 110),
    
    border: Color(r: 60, g: 60, b: 70),
    divider: Color(r: 50, g: 50, b: 60),
    
    success: Color(r: 100, g: 220, b: 100),
    warning: Color(r: 255, g: 200, b: 50),
    error: Color(r: 255, g: 100, b: 100)
)

// Component colors are derived from the base colors in init
// (e.g. buttonBackground = primary, textFieldBorder = border).
// They are not init parameters, but can be overridden afterwards:
myTheme.sliderTrack = Color(r: 50, g: 50, b: 60)
myTheme.textFieldBackground = Color(r: 25, g: 25, b: 35)

ThemeManager.shared.setTheme(myTheme)
```

## ThemedButton

Pre-styled buttons that automatically use theme colors:

```swift
// Primary style (theme.primary background)
ThemedButton("Submit", style: .primary) {
    // Action
}

// Secondary style (theme.surfaceBackground background)
ThemedButton("Cancel", style: .secondary) {
    // Action
}
```

## Theme-Aware Components

Build components that respond to theme changes:

```swift
class MyThemedPanel: View {
    func sizeThatFits(_ proposal: ProposedSize) -> Size {
        proposal.replacingUnspecified(width: 100, height: 100)
    }
    
    func render(in bounds: UIRect, context: UIRenderContext) {
        let theme = ThemeManager.shared.current
        
        // Background
        context.fillRect(bounds, color: theme.surfaceBackground)
        
        // Border
        context.strokeRect(bounds, color: theme.border, lineWidth: 1)
    }
}
```

## Dynamic Theme Switching

Rebuild UI when theme changes:

```swift
class SettingsScene: GameObjectScene {
    private var uiRoot: UIRoot!
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        buildUI()
    }
    
    private func buildUI() {
        let theme = ThemeManager.shared.current
        
        uiRoot = UIRoot {
            VStack {
                Text("Settings")
                    .foregroundColor(theme.textPrimary)
                
                HStack {
                    Button("Dark") {
                        ThemeManager.shared.setTheme(.dark)
                        self.buildUI()  // Rebuild with new theme
                    }
                    Button("Light") {
                        ThemeManager.shared.setTheme(.light)
                        self.buildUI()
                    }
                }
            }
            .background(theme.background)
        }
    }
}
```

## Theme Color Reference

### Dark Theme Colors
| Property | Color | RGB |
|----------|-------|-----|
| background | Dark gray | (30, 30, 30) |
| surfaceBackground | Slightly lighter | (40, 40, 40) |
| textPrimary | White | (255, 255, 255) |
| textSecondary | Light gray | (192, 192, 192) |
| primary | Cornflower blue | (100, 149, 237) |
| success | Green | (0, 255, 0) |
| warning | Orange | (255, 128, 0) |
| error | Red | (255, 0, 0) |

### Light Theme Colors
| Property | Color | RGB |
|----------|-------|-----|
| background | Light gray | (242, 242, 247) |
| surfaceBackground | White | (255, 255, 255) |
| textPrimary | Black | (0, 0, 0) |
| textSecondary | Dark gray | (60, 60, 67) |
| primary | Blue | (0, 122, 255) |
| success | Green | (52, 199, 89) |
| warning | Orange | (255, 149, 0) |
| error | Red | (255, 59, 48) |
