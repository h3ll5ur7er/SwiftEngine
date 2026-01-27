# UI Views

Basic views for displaying content and structuring layouts.

## Text

Displays text content.

```swift
Text("Hello, World!")
    .foregroundColor(.white)
    .scale(2)  // Double size
```

### Modifiers

```swift
Text("Styled")
    .foregroundColor(.yellow)  // Text color
    .color(.yellow)            // Alias for foregroundColor
    .scale(1)                  // Font scale (1 = normal)
    .alignment(.center)        // .leading, .center, .trailing
```

### Properties

The `Text` view has mutable properties for dynamic updates:

```swift
let label = Text("Count: 0")

// Update later
label.content = "Count: 42"
label.color = .green
```

## Spacer

Flexible space that expands to fill available space.

```swift
HStack {
    Text("Left")
    Spacer()
    Text("Right")
}
```

### With Minimum Size

```swift
Spacer(minLength: 20)  // At least 20 pixels
```

## Divider

A thin line for separating content.

```swift
VStack {
    Text("Section 1")
    Divider()
    Text("Section 2")
}
```

### Styling

```swift
Divider()
    .color(.gray)      // Line color
    .thickness(2)      // Line thickness in pixels
```

## UIRectangle

A solid colored rectangle.

```swift
UIRectangle()
    .fill(.blue)
    .frame(width: 100, height: 100)
```

### Modifiers

```swift
UIRectangle()
    .fill(.red)           // Fill color
    .stroke(.white, 2)    // Border color and width
    .cornerRadius(8)      // Rounded corners
```

## ForEach

Iterates over a collection to create views.

```swift
let items = ["Apple", "Banana", "Cherry"]

VStack {
    ForEach(items) { item in
        Text(item)
    }
}
```

### With Index

```swift
ForEach(0..<10) { index in
    Text("Item \(index)")
}
```

### With Identifiable Items

```swift
struct Item: Identifiable {
    let id: Int
    let name: String
}

let items = [Item(id: 1, name: "One"), Item(id: 2, name: "Two")]

ForEach(items) { item in
    Text(item.name)
}
```

## ConditionalView

Shows different content based on a condition (used internally by ViewBuilder).

```swift
// In a ViewBuilder context, use if/else directly:
VStack {
    if isLoggedIn {
        Text("Welcome!")
    } else {
        Text("Please log in")
    }
}
```

## EmptyView

A view that renders nothing, useful as a placeholder.

```swift
if showContent {
    Text("Content")
} else {
    EmptyView()
}
```

## Combining Views

Views can be freely combined within containers:

```swift
VStack(spacing: 20) {
    Text("Title")
        .foregroundColor(.white)
        .scale(2)
    
    Divider()
        .color(.gray)
    
    HStack(spacing: 10) {
        UIRectangle()
            .fill(.red)
            .frame(width: 20, height: 20)
        Text("Red")
        
        Spacer()
        
        UIRectangle()
            .fill(.blue)
            .frame(width: 20, height: 20)
        Text("Blue")
    }
    
    ForEach(["A", "B", "C"]) { letter in
        Text("Option \(letter)")
            .padding(5)
            .background(.darkGray)
    }
}
```
