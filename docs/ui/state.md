# UI State Management

Managing state and data binding in the UI framework.

## Binding

`Binding` provides two-way data flow between state and controls.

### Creating a Binding

```swift
class MyScene {
    private var value: Float = 0.5
    
    private var valueBinding: Binding<Float> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }
}
```

### Using Bindings with Controls

```swift
// TextField
TextField(text: textBinding, placeholder: "Enter text")

// Slider
Slider(value: sliderBinding, range: 0...1)

// Toggle
Toggle(isOn: toggleBinding)

// Checkbox
Checkbox(isChecked: checkboxBinding)

// Dropdown
Dropdown(options: options, selectedIndex: indexBinding)
```

## Binding with Side Effects

React to value changes in the setter:

```swift
private var volumeBinding: Binding<Float> {
    Binding(
        get: { self.volume },
        set: { newValue in
            self.volume = newValue
            self.audioEngine.setVolume(newValue)
            self.volumeLabel?.content = String(format: "%.0f%%", newValue * 100)
        }
    )
}
```

## Direct Property Updates

For simple reactive updates, store references to Text views and update directly:

```swift
class CounterScene {
    private var count = 0
    private var countLabel: Text?
    
    func buildUI() -> some View {
        let label = Text("Count: 0")
        self.countLabel = label
        
        return VStack {
            label
            
            HStack {
                Button("-") {
                    self.count -= 1
                    self.countLabel?.content = "Count: \(self.count)"
                }
                Button("+") {
                    self.count += 1
                    self.countLabel?.content = "Count: \(self.count)"
                }
            }
        }
    }
}
```

## State Pattern Example

A complete example showing state management:

```swift
class FormScene: GameObjectScene {
    private var uiRoot: UIRoot!
    
    // State
    private var username = ""
    private var password = ""
    private var rememberMe = false
    private var statusMessage = ""
    
    // Display references
    private var statusLabel: Text?
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        buildUI()
    }
    
    private func buildUI() {
        let status = Text("")
            .foregroundColor(.gray)
        self.statusLabel = status
        
        uiRoot = UIRoot {
            VStack(alignment: .leading, spacing: 15) {
                Text("Login")
                    .scale(2)
                
                HStack {
                    Text("Username:")
                        .frame(width: 100)
                    TextField(text: self.usernameBinding)
                        .frame(width: 200)
                }
                
                HStack {
                    Text("Password:")
                        .frame(width: 100)
                    TextField(text: self.passwordBinding)
                        .frame(width: 200)
                }
                
                HStack {
                    Checkbox(isChecked: self.rememberMeBinding)
                    Text("Remember me")
                }
                
                status
                
                Button("Login") {
                    self.login()
                }
                .padding(10)
                .background(.blue)
            }
            .padding(30)
        }
    }
    
    // Bindings
    private var usernameBinding: Binding<String> {
        Binding(
            get: { self.username },
            set: { self.username = $0 }
        )
    }
    
    private var passwordBinding: Binding<String> {
        Binding(
            get: { self.password },
            set: { self.password = $0 }
        )
    }
    
    private var rememberMeBinding: Binding<Bool> {
        Binding(
            get: { self.rememberMe },
            set: { self.rememberMe = $0 }
        )
    }
    
    // Actions
    private func login() {
        if username.isEmpty {
            statusLabel?.content = "Please enter username"
            statusLabel?.color = .red
        } else if password.isEmpty {
            statusLabel?.content = "Please enter password"
            statusLabel?.color = .red
        } else {
            statusLabel?.content = "Logging in..."
            statusLabel?.color = .green
            // Perform actual login
        }
    }
}
```

## UIState and StateObject

For more complex state management, use `UIState` and `StateObject`:

### UIState

Wraps a value with change observation:

```swift
let counter = UIState(initialValue: 0)

// Get value
let current = counter.value

// Set value
counter.value = 10

// Observe changes
counter.onChange { newValue in
    print("Counter changed to \(newValue)")
}
```

### StateObject

Container for observable state:

```swift
class GameState: StateObject {
    @Published var score = 0
    @Published var lives = 3
    @Published var level = 1
}

let state = GameState()
state.score = 100
```

## Best Practices

1. **Create bindings as computed properties** - This ensures they always reference current state.

2. **Store view references before ViewBuilder** - ViewBuilder doesn't support non-View expressions.

3. **Update displays in binding setters** - Keep UI in sync with state changes.

4. **Rebuild UI for major changes** - For theme changes or structural updates, rebuild the entire UI.

```swift
// Good: Binding as computed property
private var binding: Binding<String> {
    Binding(get: { self.value }, set: { self.value = $0 })
}

// Good: Create views before ViewBuilder
func buildUI() -> some View {
    let display = Text("Value: \(value)")
    self.displayRef = display
    
    return VStack {
        display
        // ...
    }
}

// Good: Update in setter
private var binding: Binding<Float> {
    Binding(
        get: { self.value },
        set: {
            self.value = $0
            self.displayRef?.content = "Value: \($0)"
        }
    )
}
```
