# Input System

GameEngine provides keyboard and mouse input handling through the `Input` class. Events come from the OS window (Win32 `WM_*` messages on Windows, X11 events on Linux).

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Input System                                       │
│                                                                              │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│   │  Window Events  │───▶│     Input       │───▶│  Your Component │        │
│   │  (Win32 WM_*,   │    │  (state mgmt)   │    │  (queries)      │        │
│   │   Linux X11)    │    │                 │    │                 │        │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│                                                                              │
│   Key States:                          Mouse States:                         │
│   ───────────                          ─────────────                         │
│   isKeyDown(key)     held this frame   isMouseButtonDown(button)            │
│   isKeyPressed(key)  just pressed      isMouseButtonPressed(button)         │
│   isKeyReleased(key) just released     isMouseButtonReleased(button)        │
│                                        getMousePosition() -> (x:, y:)       │
│                                        getMouseDelta()    -> (x:, y:)       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Accessing Input

There is no global input singleton. The engine owns one `Input` instance (`engine.input`) and passes it to your scene's `update(context:input:)`. Components can reach it through their scene's engine:

```swift
@MainActor
public final class MyComponent: Component {
    public override func update(deltaTime: Float) {
        // Reach the engine's input through the scene
        guard let input = gameObject?.scene?.engine?.input else { return }
        
        if input.isKeyPressed(.space) {
            jump()
        }
    }
}
```

In a scene, use the `input` parameter of `update(context:input:)` directly.

---

## Keyboard Input

### Key States

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Key State Timeline                                  │
│                                                                              │
│   Frame:      1      2      3      4      5      6      7                   │
│   Physical:   ───────────────────────────────────┘                          │
│               ↑ pressed                     ↑ released                       │
│                                                                              │
│   isKeyDown:  [true][true][true][true][true][false][false]                  │
│   isPressed:  [true][false][false][false][false][false][false]              │
│   isReleased: [false][false][false][false][false][true][false]              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

`isKeyPressed` / `isKeyReleased` (and the mouse-button equivalents) report transitions that happened during the frame's event processing, so a press and release within the same frame reports both.

### Usage

```swift
// Check if key is currently held
if input.isKeyDown(.w) {
    // Move forward continuously
    moveForward(speed: 5.0, deltaTime: deltaTime)
}

// Check if key was just pressed this frame
if input.isKeyPressed(.space) {
    // Jump (only triggers once per press)
    jump()
}

// Check if key was just released this frame
if input.isKeyReleased(.shift) {
    // Stop sprinting
    stopSprint()
}
```

### Available Keys

```swift
public enum Key {
    // Letters
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    
    // Numbers
    case num0, num1, num2, num3, num4
    case num5, num6, num7, num8, num9
    
    // Function keys
    case f1, f2, f3, f4, f5, f6
    case f7, f8, f9, f10, f11, f12
    
    // Arrow keys
    case up, down, left, right
    
    // Modifiers
    case shift, control, alt
    
    // Special keys
    case space, enter, escape, tab, backspace, delete
}
```

There are no separate left/right modifier keys: on Linux (X11), both left and right Shift/Control/Alt map to `.shift` / `.control` / `.alt`.

> **Note:** The engine stops when Escape is pressed, so don't use `.escape` for in-game actions such as pausing.

### Common Input Patterns

#### Movement

```swift
var moveDirection = Vec3d.zero

if input.isKeyDown(.w) { moveDirection.z -= 1 }
if input.isKeyDown(.s) { moveDirection.z += 1 }
if input.isKeyDown(.a) { moveDirection.x -= 1 }
if input.isKeyDown(.d) { moveDirection.x += 1 }

if moveDirection.squaredLength > 0 {
    moveDirection = moveDirection.normalized
    transform.position += moveDirection * speed * deltaTime
}
```

#### Toggle

```swift
var isFlashlightOn = false

public override func update(deltaTime: Float) {
    guard let input = gameObject?.scene?.engine?.input else { return }
    if input.isKeyPressed(.f) {
        isFlashlightOn.toggle()
    }
}
```

#### Modifier Keys

```swift
// Sprint when holding shift
let speed = input.isKeyDown(.shift) ? sprintSpeed : walkSpeed

// Quick save with Ctrl+S
if input.isKeyDown(.control) && input.isKeyPressed(.s) {
    saveGame()
}
```

---

## Mouse Input

### Mouse Buttons

```swift
public enum MouseButton {
    case left
    case right
    case middle
}
```

### Button States

```swift
// Check if button is held
if input.isMouseButtonDown(.left) {
    // Continuous firing
    fire()
}

// Check if button was just pressed
if input.isMouseButtonPressed(.right) {
    // Aim down sights
    aimDownSights()
}

// Check if button was just released
if input.isMouseButtonReleased(.left) {
    // Release charged attack
    releaseChargedAttack()
}
```

### Mouse Position

```swift
// Absolute position in window (pixels)
let position = input.getMousePosition()  // (x: Int32, y: Int32)

// Position delta since last frame
let delta = input.getMouseDelta()  // (x: Int32, y: Int32)

// Use delta for camera rotation
let sensitivity: Float = 0.002  // radians per pixel
yaw -= Float(delta.x) * sensitivity
pitch -= Float(delta.y) * sensitivity
```

The scroll wheel is not exposed by `Input`.

---

## Mouse Capture

For first-person controls, capture the mouse to hide it and get unlimited movement:

The window is internal to the engine; use the `Engine` methods (from a `GameObjectScene`, via its `engine` property):

```swift
// Capture mouse (hides cursor, centers mouse each frame)
engine.captureMouse()

// Release mouse (shows cursor)
engine.releaseMouse()

// Toggle capture
engine.toggleMouseCapture()

// Check capture state (engine.isMouseCaptured or input.isMouseCaptured)
if input.isMouseCaptured {
    // Use mouse delta for camera look
    let delta = input.getMouseDelta()
    rotateCam(yaw: Float(delta.x), pitch: Float(delta.y))
} else {
    // Use mouse position for UI
    let pos = input.getMousePosition()
    checkUIHover(x: pos.x, y: pos.y)
}
```

### Toggle Pattern

```swift
// In your GameObjectScene
public override func update(context: FrameContext, input: Input) {
    // Toggle mouse capture with Tab
    if input.isKeyPressed(.tab) {
        engine?.toggleMouseCapture()
    }
    super.update(context: context, input: input)
}
```

---

## Input in Components

### Component Example

The engine ships a built-in `PlayerController` (see [Built-in Components](../components/built-in.md)); this example uses a different name to avoid clashing with it.

```swift
@MainActor
public final class SimpleMover: Component {
    var moveSpeed: Float = 5.0
    var lookSensitivity: Float = 0.002  // radians per pixel
    
    public override func update(deltaTime: Float) {
        guard let input = gameObject?.scene?.engine?.input else { return }
        
        // Movement
        var move = Vec3d.zero
        if input.isKeyDown(.w) { move.z -= 1 }
        if input.isKeyDown(.s) { move.z += 1 }
        if input.isKeyDown(.a) { move.x -= 1 }
        if input.isKeyDown(.d) { move.x += 1 }
        
        if move.squaredLength > 0 {
            move = move.normalized * moveSpeed * deltaTime
            transform.position += transform.rotation * move
        }
        
        // Look (when mouse captured)
        if input.isMouseCaptured {
            let delta = input.getMouseDelta()
            transform.rotation = Quaternion.fromAxisAngle(
                axis: .up,
                angle: -Float(delta.x) * lookSensitivity
            ) * transform.rotation
        }
        
        // Jump
        if input.isKeyPressed(.space) {
            if let rb = gameObject?.getComponent(RigidBody.self) {
                rb.addImpulse(Vec3d(0, 10, 0))
            }
        }
    }
}
```

---

## Input Frame Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Input Frame Lifecycle                               │
│                                                                              │
│   1. input.beginFrame()        Clear previous frame's pressed/released      │
│            │                                                                 │
│   2. window.pollEvents()       Process OS events, update key/mouse state    │
│            │                                                                 │
│   3. component.update()        Your code reads input state                  │
│            │                                                                 │
│   4. Render                    Input state preserved during render          │
│            │                                                                 │
│   5. End of frame              (Loop back to step 1)                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Best Practices

1. **Use `isKeyPressed` for single actions** (jump, shoot, toggle)
2. **Use `isKeyDown` for continuous actions** (move, sprint)
3. **Pass input down from the scene** (or use `engine.input`); there is no global `Input.shared`
4. **Use mouse delta, not position** for camera rotation
5. **Capture mouse** for first-person controls
6. **Handle edge cases** - check for nil game objects, etc.

```swift
// Good - single action uses isKeyPressed
if input.isKeyPressed(.e) {
    interact()  // Only triggers once per press
}

// Good - continuous action uses isKeyDown
if input.isKeyDown(.w) {
    moveForward()  // Triggers every frame while held
}

// Bad - isKeyDown for single action
if input.isKeyDown(.e) {
    interact()  // Triggers every frame - not what you want!
}
```
