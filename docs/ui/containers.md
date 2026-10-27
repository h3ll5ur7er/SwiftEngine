# UI Containers

Containers organize and layout child views within the UI hierarchy.

## VStack

Vertical stack - arranges children vertically.

```swift
VStack(alignment: .leading, spacing: 10) {
    Text("First")
    Text("Second")
    Text("Third")
}
```

### Parameters
- `alignment`: `.leading`, `.center`, `.trailing` (default: `.center`)
- `spacing`: Space between children in pixels (default: `8`)

### Modifiers
```swift
VStack { ... }
    .padding(10)
    .background(.gray)
    .frame(width: 200)
```

## HStack

Horizontal stack - arranges children horizontally.

```swift
HStack(alignment: .center, spacing: 10) {
    Text("Left")
    Spacer()
    Text("Right")
}
```

### Parameters
- `alignment`: `.top`, `.center`, `.bottom` (default: `.center`)
- `spacing`: Space between children in pixels (default: `8`)

## ZStack

Layered stack - stacks children on top of each other.

```swift
ZStack {
    UIRectangle()
        .fill(.blue)
        .frame(width: 100, height: 100)
    Text("Overlay")
        .foregroundColor(.white)
}
```

### Parameters
- `alignment`: Controls how children align within the stack

## Grid

Arranges children in a grid with fixed columns.

```swift
Grid(columns: 3, horizontalSpacing: 10, verticalSpacing: 10) {
    ForEach(items) { item in
        Text(item.name)
    }
}
```

### Parameters
- `columns`: Number of columns (default: `2`)
- `horizontalSpacing`: Space between columns (default: `8`)
- `verticalSpacing`: Space between rows (default: `8`)
- `horizontalAlignment` / `verticalAlignment`: Alignment of each child within its cell (default: `.center`)

### LazyVGrid

For per-column sizing, `LazyVGrid` takes an array of column definitions (`.fixed(width)`, `.flexible(minimum:maximum:)`, `.adaptive(minimum:)`):

```swift
LazyVGrid(columns: [.fixed(80), .flexible()], spacing: 8, verticalSpacing: 8) {
    Text("Name")
    Text("Value")
}
```

## ScrollView

Scrollable container for content larger than the viewport.

```swift
ScrollView {
    VStack(spacing: 5) {
        ForEach(0..<100) { i in
            Text("Item \(i)")
        }
    }
}
.frame(height: 300)
```

### Features
- Scrolling by dragging the scroll bar (there is no mouse wheel or content-drag scrolling)
- Automatic content size detection
- Programmatic scrolling

### Modifiers
```swift
ScrollView { ... }
    .showsIndicators(vertical: true, horizontal: false)  // Which scroll bars to show
    .indicatorStyle(color: .gray, width: 6)              // Scroll bar look
```

### Programmatic Scrolling
```swift
let scrollView = ScrollView { ... }

scrollView.scrollTo(y: 120)    // Scroll to an offset (x and/or y)
scrollView.scrollToTop()
scrollView.scrollToBottom()
```

## TabPanel

Tabbed container showing one content view at a time based on selected tab.

```
┌─────────────────────────────────────────────────────────────┐
│ ┌──────┐ ┌──────┐ ┌──────┐                                 │
│ │ Tab1 │ │ Tab2 │ │ Tab3 │     ← Tab Bar                   │
│ └──────┘ └──────┘ └──────┘                                 │
│ ════════                       ← Selection Indicator       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    Tab Content Area                         │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Basic Usage

```swift
TabPanel {
    TabPanel.Tab("General") {
        VStack {
            Text("General Settings")
            // ... content
        }
    }
    TabPanel.Tab("Audio") {
        VStack {
            Text("Audio Settings")
            Slider(value: volumeBinding, range: 0...1)
        }
    }
    TabPanel.Tab("Video") {
        VStack {
            Text("Video Settings")
            // ... content
        }
    }
}
```

### With Initial Selection

```swift
TabPanel(selectedIndex: 1) {
    TabPanel.Tab("First") { Text("Content 1") }
    TabPanel.Tab("Second") { Text("Content 2") }  // Initially selected
    TabPanel.Tab("Third") { Text("Content 3") }
}
```

### Tab Change Handler

```swift
TabPanel {
    TabPanel.Tab("Tab A") { ... }
    TabPanel.Tab("Tab B") { ... }
}
.onTabChanged { index in
    print("Switched to tab \(index)")
}
```

### Styling

```swift
TabPanel { ... }
    .tabHeight(32)
    .tabStyle(
        background: Color(r: 40, g: 40, b: 40),
        backgroundHover: Color(r: 50, g: 50, b: 50),
        backgroundSelected: Color(r: 60, g: 60, b: 60),
        textColor: Color(r: 180, g: 180, b: 180),
        textColorSelected: .white,
        indicatorColor: .cornflowerBlue
    )
    .contentBackground(Color(r: 30, g: 30, b: 30))
    .borderColor(Color(r: 60, g: 60, b: 60))
```

### Programmatic Selection

```swift
let tabPanel = TabPanel { ... }

// Later...
tabPanel.selectTab(2)  // Switch to third tab
```

### Tab Struct

Each tab has a title and content:

```swift
TabPanel.Tab("Title") {
    // Content view(s)
}

// Or with explicit content
TabPanel.Tab("Title", content: myView)
```

### TabBuilder

The `@TabBuilder` result builder allows declarative tab definitions. It only supports a plain list of tabs (no `if` statements):

```swift
@TabBuilder
func buildTabs() -> [TabPanel.Tab] {
    TabPanel.Tab("Home") { HomeView() }
    TabPanel.Tab("Settings") { SettingsView() }
}
```

To add tabs conditionally, build a `[TabPanel.Tab]` array yourself and pass it to `TabPanel(selectedIndex:tabs:)`.

### Complete Example

```swift
class SettingsScene: GameObjectScene {
    private var uiRoot: UIRoot!
    @UIState private var volume: Float = 0.8
    @UIState private var musicEnabled = true
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        uiRoot = UIRoot {
            VStack(spacing: 0) {
                // Header
                Text("Settings")
                    .foregroundColor(.white)
                    .padding(20)
                
                // Tabbed content
                TabPanel {
                    TabPanel.Tab("Audio") {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Volume:")
                                Slider(value: Binding(self.$volume), range: 0...1)
                                    .frame(width: 200)
                            }
                            HStack {
                                Text("Music:")
                                Toggle(isOn: Binding(self.$musicEnabled))
                            }
                        }
                        .padding(20)
                    }
                    
                    TabPanel.Tab("Display") {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Display settings here...")
                        }
                        .padding(20)
                    }
                    
                    TabPanel.Tab("Controls") {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Control bindings here...")
                        }
                        .padding(20)
                    }
                }
                .onTabChanged { index in
                    print("Tab changed to: \(index)")
                }
                .frame(width: 600, height: 400)
            }
        }
    }
}
```

## Common Modifiers

All containers support these modifiers:

```swift
container
    .padding(10)                    // All sides
    .padding(horizontal: 20)        // Left and right
    .frame(width: 300, height: 200) // Fixed size
    .background(.darkGray)          // Background color
    .cornerRadius(8)                // Rounded corners
```

Chained modifiers configure a single wrapper view, so a later `padding` call replaces an earlier one rather than adding to it. Use `padding(horizontal:vertical:)` or `padding(_: EdgeInsets)` to set different insets per side.
