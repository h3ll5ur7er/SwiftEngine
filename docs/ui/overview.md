# UI Framework Overview

GameEngine includes a SwiftUI-inspired declarative UI framework for building game interfaces. The framework supports immediate-mode rendering with a retained-mode API.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          UI Framework                                    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                         UIRoot                                    │  │
│  │   Entry point - handles input, layout, and rendering              │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                               │                                         │
│        ┌──────────────────────┼──────────────────────┐                 │
│        ▼                      ▼                      ▼                 │
│  ┌──────────┐          ┌──────────┐          ┌──────────┐             │
│  │ Containers│          │  Views   │          │ Controls │             │
│  │          │          │          │          │          │             │
│  │ VStack   │          │ Text     │          │ Button   │             │
│  │ HStack   │          │ Spacer   │          │ TextField│             │
│  │ ZStack   │          │ Divider  │          │ Slider   │             │
│  │ Grid     │          │ ForEach  │          │ Toggle   │             │
│  │ ScrollView│         │UIRectangle│         │ Checkbox │             │
│  │ TabPanel │          │          │          │ Dropdown │             │
│  └──────────┘          └──────────┘          │ProgressBar│            │
│                                              └──────────┘             │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    Theme System                                   │  │
│  │   ThemeManager  ←→  Theme  ←→  ThemedComponents                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Concepts

### View Protocol

All UI elements conform to the `View` protocol:

```swift
@MainActor
public protocol View {
    func sizeThatFits(_ proposal: ProposedSize) -> Size
    func render(in bounds: UIRect, context: UIRenderContext)
    func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool
    func handleKeyboard(_ event: KeyboardEvent) -> Bool
}
```

`handleMouse(_:in:)` and `handleKeyboard(_:)` have default implementations that return `false`, so a view only needs to implement them if it handles input.

### ViewBuilder

Use `@ViewBuilder` to create declarative UI hierarchies:

```swift
VStack(spacing: 10) {
    Text("Hello, World!")
    Button("Click Me") {
        print("Clicked!")
    }
    HStack(spacing: 5) {
        Text("Name:")
        TextField(text: nameBinding)
    }
}
```

### Modifiers

Chain modifiers to customize views:

```swift
Text("Styled Text")
    .foregroundColor(.white)
    .background(.blue)
    .padding(10)
    .frame(width: 200, height: 50)
    .cornerRadius(8)
```

## Basic Usage

### Creating a UI Root

```swift
class MyScene: GameObjectScene {
    private var uiRoot: UIRoot!
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        uiRoot = UIRoot {
            VStack(spacing: 20) {
                Text("Game Menu")
                    .foregroundColor(.white)
                Button("Start Game") {
                    // Start game logic
                }
                Button("Settings") {
                    // Open settings
                }
            }
            .padding(20)
        }
    }
    
    override func update(context: FrameContext, input: Input) {
        super.update(context: context, input: input)
        
        // Handle UI input (uses the screen size from the last render)
        uiRoot.handleInput(input)
    }
    
    override func render(context: RenderContext) {
        context.renderer.clear(.black)
        
        // Render UI over the whole screen
        uiRoot.render(context)
    }
}
```

`UIRoot` also offers `render(_:in:)` and `handleInput(_:in:)` to draw and route input within a frame (screen coordinates), `handleInput(_:screenWidth:screenHeight:)` for an explicit screen size, and `fittingSize(maxWidth:maxHeight:renderer:)` to measure the content's ideal size plus padding. A click or key tap shorter than one frame is still delivered (as a press followed by a release).

## Documentation

- [Containers](containers.md) - Layout containers (VStack, HStack, Grid, TabPanel, etc.)
- [Views](views.md) - Basic views (Text, Spacer, Divider, etc.)
- [Controls](controls.md) - Interactive controls (Button, TextField, Slider, etc.)
- [Theming](theming.md) - Theme system and customization
- [State Management](state.md) - Bindings and reactive state
- [UIOverlay Component](overlay.md) - Integrating UI with GameObjects
