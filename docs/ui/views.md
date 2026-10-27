# UI Views

Basic views for displaying content and structuring layouts.

## Text

Displays text content.

```swift
Text("Hello, World!")
    .foregroundColor(.white)
    .fontSize(2)  // Double size
```

### Modifiers

```swift
Text("Styled")
    .foregroundColor(.yellow)  // Text color
    .color(.yellow)            // Alias for foregroundColor
    .fontSize(1)               // Font scale (1 = normal)
    .multilineTextAlignment(.center)  // .leading, .center, .trailing
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
    .stroke(.white, lineWidth: 2)  // Border color and width
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

Shows one of two views based on a condition that is re-checked whenever it is measured, rendered or receives input (it is what the `If(_:then:else:)` helper returns). Inside a `@ViewBuilder` closure you can simply write `if`/`else`, but that condition is evaluated once, when the closure runs.

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

## Optional Content

There is no `EmptyView`. To show content only when a condition holds, use an `if` without an `else` inside a `@ViewBuilder` closure; nothing is added when the condition is false.

```swift
VStack {
    if showContent {
        Text("Content")
    }
}
```

## Combining Views

Views can be freely combined within containers:

```swift
VStack(spacing: 20) {
    Text("Title")
        .foregroundColor(.white)
        .fontSize(2)
    
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
