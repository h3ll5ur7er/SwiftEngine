# Input System

GameEngine provides keyboard and mouse input handling through the `Input` class.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Input System                                       │
│                                                                              │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│   │  Window Events  │───▶│     Input       │───▶│  Your Component │        │
│   │  (WM_KEYDOWN,   │    │  (state mgmt)   │    │  (queries)      │        │
│   │   WM_MOUSEMOVE) │    │                 │    │                 │        │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│                                                                              │
│   Key States:                          Mouse States:                         │
│   ───────────                          ─────────────                         │
│   isKeyDown(key)     held this frame   isMouseButtonDown(button)            │
│   isKeyPressed(key)  just pressed      isMouseButtonPressed(button)         │
│   isKeyReleased(key) just released     isMouseButtonReleased(button)        │
│                                        mousePosition: Vec2                  │
│                                        mouseDelta: Vec2                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Accessing Input

```swift
@MainActor
public final class MyComponent: Component {
    public override func update(deltaTime: Float) {
        // Access global input instance
        let input = Input.shared
        
        if input.isKeyPressed(.space) {
            jump()
        }
    }
}
```

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
    case num0, num1, num2, num3, num4, num5
    case num6, num7, num8, num9
    
    // Function keys
    case f1, f2, f3, f4, f5, f6
    case f7, f8, f9, f10, f11, f12
    
    // Arrow keys
    case up, down, left, right
    
    // Modifiers
    case shift, control, alt
    case leftShift, rightShift
    case leftControl, rightControl
    case leftAlt, rightAlt
    
    // Special keys
    case space, enter, escape, tab, backspace
    case insert, delete, home, end, pageUp, pageDown
    
    // Numpad
    case numpad0, numpad1, numpad2, numpad3, numpad4
    case numpad5, numpad6, numpad7, numpad8, numpad9
    case numpadAdd, numpadSubtract
    case numpadMultiply, numpadDivide
    case numpadEnter, numpadDecimal
}
```

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
    if Input.shared.isKeyPressed(.f) {
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
let position = input.mousePosition  // Vec2

// Position delta since last frame
let delta = input.mouseDelta  // Vec2

// Use delta for camera rotation
let sensitivity: Float = 0.1
camera.yaw += delta.x * sensitivity
camera.pitch -= delta.y * sensitivity
```

### Scroll Wheel

```swift
// Scroll delta (positive = up, negative = down)
let scrollDelta = input.scrollDelta  // Float

// Zoom camera
camera.distance -= scrollDelta * zoomSpeed
```

---

## Mouse Capture

For first-person controls, capture the mouse to hide it and get unlimited movement:

```swift
// Capture mouse (hides cursor, centers mouse each frame)
window.captureMouse()

// Release mouse (shows cursor)
window.releaseMouse()

// Check capture state
if window.isMouseCaptured {
    // Use mouse delta for camera look
    let delta = input.mouseDelta
    rotateCam(yaw: delta.x, pitch: delta.y)
} else {
    // Use mouse position for UI
    let pos = input.mousePosition
    checkUIHover(at: pos)
}
```

### Toggle Pattern

```swift
public override func update(deltaTime: Float) {
    // Toggle mouse capture with Tab
    if Input.shared.isKeyPressed(.tab) {
        if window.isMouseCaptured {
            window.releaseMouse()
        } else {
            window.captureMouse()
        }
    }
}
```

---

## Input in Components

### Component Example

```swift
@MainActor
public final class PlayerController: Component {
    var moveSpeed: Float = 5.0
    var lookSensitivity: Float = 0.1
    
    public override func update(deltaTime: Float) {
        let input = Input.shared
        
        // Movement
        var move = Vec3d.zero
        if input.isKeyDown(.w) { move.z -= 1 }
        if input.isKeyDown(.s) { move.z += 1 }
        if input.isKeyDown(.a) { move.x -= 1 }
        if input.isKeyDown(.d) { move.x += 1 }
        
        if move.squaredLength > 0 {
            move = move.normalized * moveSpeed * deltaTime
            transform.position += transform.rotation.rotate(move)
        }
        
        // Look (when mouse captured)
        if let window = gameObject?.scene?.engine?.window,
           window.isMouseCaptured {
            let delta = input.mouseDelta
            transform.rotation = Quaternion.fromAxisAngle(
                axis: .up,
                angle: -delta.x * lookSensitivity * deltaTime
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
3. **Cache Input.shared** in a local variable for repeated access
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
