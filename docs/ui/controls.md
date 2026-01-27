# UI Controls

Interactive controls for user input.

## Button

A clickable button that triggers an action.

```swift
Button("Click Me") {
    print("Button clicked!")
}
```

### Styling

```swift
Button("Styled", action: { })
    .foregroundColor(.white)
    .background(.blue)
    .padding(10)
    .cornerRadius(4)
```

### Button States

Buttons automatically show hover states. The background color lightens slightly when hovered.

### Disabled State

```swift
Button("Disabled", action: { })
    .disabled(true)
```

## TextField

Single-line text input field.

```swift
@State private var name = ""

TextField(text: $name, placeholder: "Enter name...")
    .frame(width: 200, height: 28)
```

### With Binding

```swift
class MyScene {
    private var text = "Hello"
    
    private var textBinding: Binding<String> {
        Binding(
            get: { self.text },
            set: { self.text = $0 }
        )
    }
    
    func buildUI() -> some View {
        TextField(text: textBinding, placeholder: "Type here...")
    }
}
```

### Styling

```swift
TextField(text: binding)
    .frame(width: 250, height: 32)
    .background(Color(r: 40, g: 40, b: 40))
    .foregroundColor(.white)
    .borderColor(.gray)
```

### Features
- Cursor with blinking animation
- Text selection (click and drag)
- Backspace to delete
- Character input

## Slider

A draggable slider for numeric values.

```swift
@State private var volume: Float = 0.5

Slider(value: $volume, range: 0...1)
    .frame(width: 200, height: 20)
```

### With Binding

```swift
private var sliderBinding: Binding<Float> {
    Binding(
        get: { self.volume },
        set: { self.volume = $0 }
    )
}

Slider(value: sliderBinding, range: 0...100)
```

### Styling

```swift
Slider(value: binding, range: 0...1)
    .trackColor(Color(r: 60, g: 60, b: 60))  // Background track
    .fillColor(.blue)                         // Filled portion
    .thumbColor(.white)                       // Thumb/handle
    .frame(width: 200, height: 20)
```

## Toggle

An on/off switch control.

```swift
@State private var enabled = true

Toggle(isOn: $enabled)
```

### With Label

```swift
HStack {
    Text("Enable Sound")
    Toggle(isOn: $soundEnabled)
}
```

### Styling

```swift
Toggle(isOn: binding)
    .onColor(.green)      // Color when on
    .offColor(.gray)      // Color when off
```

## Checkbox

A checkable box control.

```swift
@State private var accepted = false

HStack {
    Checkbox(isChecked: $accepted)
    Text("I accept the terms")
}
```

### With Label

```swift
Checkbox(isChecked: binding, label: "Remember me")
```

### Styling

```swift
Checkbox(isChecked: binding)
    .checkColor(.green)      // Checkmark color
    .boxColor(.darkGray)     // Box background
```

## Dropdown

A dropdown selection menu.

```swift
let options = ["Easy", "Medium", "Hard"]
@State private var selectedIndex = 0

Dropdown(options: options, selectedIndex: $selectedIndex)
    .frame(width: 150, height: 28)
```

### With Binding

```swift
private var dropdownBinding: Binding<Int> {
    Binding(
        get: { self.selectedIndex },
        set: { self.selectedIndex = $0 }
    )
}

Dropdown(
    options: ["Option A", "Option B", "Option C"],
    selectedIndex: dropdownBinding
)
```

### Features
- Click to open/close dropdown
- Hover highlighting on options
- Click outside to close
- Keyboard navigation (coming soon)

## ProgressBar

A progress indicator bar.

```swift
ProgressBar(progress: 0.75)
    .frame(width: 200, height: 16)
```

### Dynamic Progress

```swift
let progressBar = ProgressBar(progress: 0.0)

// Update later
progressBar.progress = 0.5
```

### Styling

```swift
ProgressBar(progress: 0.6)
    .trackColor(Color(r: 50, g: 50, b: 50))  // Background
    .fillColor(.green)                        // Progress fill
    .cornerRadius(4)                          // Rounded ends
    .height(12)
    .width(200)
```

## Binding Pattern

Most controls support bindings for two-way data flow:

```swift
class MyScene {
    // State variables
    private var text = ""
    private var value: Float = 0.5
    private var enabled = true
    
    // Create bindings
    private var textBinding: Binding<String> {
        Binding(
            get: { self.text },
            set: { newValue in
                self.text = newValue
                // React to changes
                self.onTextChanged(newValue)
            }
        )
    }
    
    private var valueBinding: Binding<Float> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }
    
    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { self.enabled },
            set: { self.enabled = $0 }
        )
    }
    
    func buildUI() -> some View {
        VStack(spacing: 15) {
            TextField(text: textBinding)
            Slider(value: valueBinding, range: 0...1)
            Toggle(isOn: enabledBinding)
        }
    }
}
```

## Complete Form Example

```swift
class SettingsForm {
    private var playerName = "Player1"
    private var volume: Float = 0.8
    private var musicEnabled = true
    private var difficulty = 1
    
    func buildForm() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Text input
            HStack {
                Text("Name:")
                    .frame(width: 80)
                TextField(text: nameBinding, placeholder: "Enter name")
                    .frame(width: 200)
            }
            
            // Slider
            HStack {
                Text("Volume:")
                    .frame(width: 80)
                Slider(value: volumeBinding, range: 0...1)
                    .frame(width: 200)
                Text(String(format: "%.0f%%", volume * 100))
            }
            
            // Toggle
            HStack {
                Text("Music:")
                    .frame(width: 80)
                Toggle(isOn: musicBinding)
            }
            
            // Dropdown
            HStack {
                Text("Difficulty:")
                    .frame(width: 80)
                Dropdown(
                    options: ["Easy", "Normal", "Hard"],
                    selectedIndex: difficultyBinding
                )
            }
            
            // Progress display
            HStack {
                Text("Loading:")
                    .frame(width: 80)
                ProgressBar(progress: 0.65)
                    .frame(width: 200)
            }
            
            // Submit button
            Button("Save Settings") {
                self.saveSettings()
            }
            .padding(10)
            .background(.blue)
        }
        .padding(20)
    }
}
```
