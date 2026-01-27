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

A `Theme` contains these color properties:

```swift
public struct Theme {
    // Backgrounds
    public var background: Color           // Main background
    public var surfaceBackground: Color    // Panel/card background
    public var surfaceBackgroundAlt: Color // Alternate surface
    
    // Text
    public var textPrimary: Color          // Primary text
    public var textSecondary: Color        // Secondary/muted text
    public var textDisabled: Color         // Disabled text
    
    // Accent colors
    public var primary: Color              // Primary accent
    public var secondary: Color            // Secondary accent
    
    // Semantic colors
    public var success: Color              // Success/positive
    public var warning: Color              // Warning/caution
    public var error: Color                // Error/negative
    
    // Borders and dividers
    public var border: Color               // Border color
    public var divider: Color              // Divider lines
    
    // Button colors
    public var buttonBackground: Color
    public var buttonBackgroundHover: Color
    public var buttonBackgroundPressed: Color
    
    // Input colors
    public var inputBackground: Color
    public var inputBorder: Color
    public var inputBorderFocused: Color
    
    // Slider colors
    public var sliderTrack: Color
    public var sliderFill: Color
    public var sliderThumb: Color
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
            .background(theme.primary)
        
        Divider()
            .color(theme.divider)
    }
    .background(theme.background)
}
```

## Creating Custom Themes

```swift
let myTheme = Theme(
    background: Color(r: 20, g: 20, b: 30),
    surfaceBackground: Color(r: 30, g: 30, b: 40),
    surfaceBackgroundAlt: Color(r: 40, g: 40, b: 50),
    
    textPrimary: .white,
    textSecondary: Color(r: 180, g: 180, b: 190),
    textDisabled: Color(r: 100, g: 100, b: 110),
    
    primary: Color(r: 100, g: 150, b: 255),
    secondary: Color(r: 150, g: 100, b: 255),
    
    success: Color(r: 100, g: 220, b: 100),
    warning: Color(r: 255, g: 200, b: 50),
    error: Color(r: 255, g: 100, b: 100),
    
    border: Color(r: 60, g: 60, b: 70),
    divider: Color(r: 50, g: 50, b: 60),
    
    buttonBackground: Color(r: 60, g: 60, b: 70),
    buttonBackgroundHover: Color(r: 70, g: 70, b: 80),
    buttonBackgroundPressed: Color(r: 50, g: 50, b: 60),
    
    inputBackground: Color(r: 25, g: 25, b: 35),
    inputBorder: Color(r: 60, g: 60, b: 70),
    inputBorderFocused: Color(r: 100, g: 150, b: 255),
    
    sliderTrack: Color(r: 50, g: 50, b: 60),
    sliderFill: Color(r: 100, g: 150, b: 255),
    sliderThumb: .white
)

ThemeManager.shared.setTheme(myTheme)
```

## ThemedButton

Pre-styled buttons that automatically use theme colors:

```swift
// Primary style (theme.primary background)
ThemedButton("Submit", style: .primary) {
    // Action
}

// Secondary style (theme.secondary background)
ThemedButton("Cancel", style: .secondary) {
    // Action
}
```

## Theme-Aware Components

Build components that respond to theme changes:

```swift
class ThemedPanel: View {
    func render(in bounds: UIRect, context: UIRenderContext) {
        let theme = ThemeManager.shared.current
        
        // Background
        context.fillRect(bounds, color: theme.surfaceBackground)
        
        // Border
        context.strokeRect(bounds, color: theme.border, width: 1)
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
| textSecondary | Light gray | (180, 180, 180) |
| primary | Cornflower blue | (100, 149, 237) |
| success | Green | (76, 175, 80) |
| warning | Amber | (255, 193, 7) |
| error | Red | (244, 67, 54) |

### Light Theme Colors
| Property | Color | RGB |
|----------|-------|-----|
| background | Light gray | (245, 245, 245) |
| surfaceBackground | White | (255, 255, 255) |
| textPrimary | Dark gray | (33, 33, 33) |
| textSecondary | Medium gray | (117, 117, 117) |
| primary | Blue | (33, 150, 243) |
| success | Green | (76, 175, 80) |
| warning | Orange | (255, 152, 0) |
| error | Red | (244, 67, 54) |
