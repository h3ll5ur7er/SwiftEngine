# Built-in Components

GameEngine includes several utility components for common functionality.

## PlayerController

First-person movement controller with keyboard support.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       PlayerController                                   │
│                                                                          │
│               W / ↑                                                      │
│                 ▲                                                        │
│                 │                                                        │
│     A / ← ◀────●────▶ D / →                                             │
│                 │                                                        │
│                 ▼                                                        │
│               S / ↓                                                      │
│                                                                          │
│     Q = Move Down        E = Move Up                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Setup

```swift
let player = createGameObject(name: "Player", at: Vec3d(0, 1, 5))
player.addComponent(Camera.self)

let controller = player.addComponent(PlayerController.self)
controller.moveSpeed = 5.0      // Units per second
controller.lookSpeed = 2.0      // Radians per second
controller.useArrowKeys = true  // Enable arrow keys as alternative
```

### Usage in Scene

```swift
@MainActor
public final class MyScene: GameObjectScene {
    private var playerController: PlayerController?
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        let player = createGameObject(name: "Player", at: Vec3d(0, 1, 5))
        player.addComponent(Camera.self)
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
    }
    
    public override func update(context: FrameContext, input: Input) {
        // IMPORTANT: Provide input to controller
        playerController?.setInput(input)
        
        super.update(context: context, input: input)
    }
}
```

### Properties

```swift
// Movement speed in units per second
controller.moveSpeed = 5.0

// Rotation speed in radians per second
controller.lookSpeed = 2.0

// Primary WASD keys
controller.forwardKey = .w
controller.backwardKey = .s
controller.leftKey = .a
controller.rightKey = .d
controller.upKey = .e
controller.downKey = .q

// Enable arrow key alternatives
controller.useArrowKeys = true

// Mouse look (future feature)
controller.enableMouseLook = false
```

### Custom Key Bindings

```swift
// IJKL layout
controller.forwardKey = .i
controller.backwardKey = .k
controller.leftKey = .j
controller.rightKey = .l

// Disable arrow keys
controller.useArrowKeys = false
```

---

## Rotator

Automatically rotates a GameObject around an axis.

```
           axis
            │
            │   ↻ rotation
            │  /
            │ /
    ────────●────────
           /│
          / │
         ↺  │
            │
```

### Setup

```swift
let cube = createGameObject(name: "SpinningCube")
cube.addComponent(MeshRenderer.self).mesh = CubeMesh.shared

let rotator = cube.addComponent(Rotator.self)
rotator.axis = Vec3d.up    // Rotate around Y axis
rotator.speed = 1.0        // 1 radian per second (~57°/s)
```

### Properties

```swift
// Axis of rotation (normalized automatically)
rotator.axis = Vec3d.up        // Y axis (yaw)
rotator.axis = Vec3d.right     // X axis (pitch)
rotator.axis = Vec3d.forward   // Z axis (roll)
rotator.axis = Vec3d(1, 1, 0)  // Diagonal

// Speed in radians per second
rotator.speed = Float.pi       // 180°/s - half rotation per second
rotator.speed = Float.pi * 2   // 360°/s - full rotation per second
rotator.speed = -1.0           // Negative = opposite direction

// Local vs world space rotation
rotator.useLocalSpace = true   // Rotate around object's own axis
rotator.useLocalSpace = false  // Rotate around world axis
```

### Common Rotations

```swift
// Turntable (showcase rotation)
rotator.axis = .up
rotator.speed = 0.5

// Tumbling
rotator.axis = Vec3d(1, 1, 1).normalized
rotator.speed = 1.0

// Coin flip
rotator.axis = .right
rotator.speed = Float.pi * 4  // 2 rotations per second

// Fan blade
rotator.axis = .forward
rotator.speed = Float.pi * 10  // Fast spin
```

### Local vs World Space

```swift
// Local space (default)
// The object rotates around its own axis
// Good for: spinning tops, wheels
rotator.useLocalSpace = true

// World space
// The object rotates around the world axis
// Good for: orbiting, planetary rotation
rotator.useLocalSpace = false
```

```
Local Space Rotation:              World Space Rotation:

  Object tilted 45°                  Object tilted 45°
        
       ╱                                  ╱
      ╱  ↻ rotates around               ╱
     ╱     own axis                    ╱   ↻ rotates around
    ●────                             ●────   world Y axis
                                      
  Result: Wobbles                    Result: Orbits
```

---

## Creating Custom Components

You can create your own components following the same pattern:

```swift
import GameEngine

@MainActor
public final class Oscillator: Component {
    
    /// Oscillation axis
    public var axis: Vec3d = .up
    
    /// Oscillation amplitude (distance from center)
    public var amplitude: Float = 1.0
    
    /// Oscillation frequency (cycles per second)
    public var frequency: Float = 1.0
    
    /// Starting position
    private var startPosition: Vec3d = .zero
    
    /// Time accumulator
    private var time: Float = 0
    
    public required init() {
        super.init()
    }
    
    public override func start() {
        // Capture initial position
        startPosition = transform.localPosition
    }
    
    public override func update(deltaTime: Float) {
        time += deltaTime
        
        // Sine wave oscillation
        let offset = sin(time * frequency * Float.pi * 2) * amplitude
        transform.localPosition = startPosition + axis * offset
    }
}
```

### Using Your Component

```swift
let platform = createGameObject(name: "MovingPlatform")
platform.addComponent(MeshRenderer.self).mesh = CubeMesh.shared

let oscillator = platform.addComponent(Oscillator.self)
oscillator.axis = .up
oscillator.amplitude = 2.0
oscillator.frequency = 0.5  // Half cycle per second
```

---

## Component Patterns

### Composition

Combine multiple components for complex behavior:

```swift
let enemy = createGameObject(name: "Enemy")

// Visual
let renderer = enemy.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.material = Material.solid(.red)

// Movement
let rotator = enemy.addComponent(Rotator.self)
rotator.axis = .up
rotator.speed = 2.0

// Custom behavior
enemy.addComponent(EnemyAI.self)
enemy.addComponent(Health.self)
```

### Component Communication

```swift
@MainActor
public final class DamageFlash: Component {
    private var renderer: MeshRenderer?
    private var originalColor: Color = .white
    private var flashTimer: Float = 0
    
    public override func start() {
        renderer = gameObject?.getComponent(MeshRenderer.self)
        originalColor = renderer?.color ?? .white
    }
    
    public func flash() {
        renderer?.color = .white
        flashTimer = 0.1
    }
    
    public override func update(deltaTime: Float) {
        if flashTimer > 0 {
            flashTimer -= deltaTime
            if flashTimer <= 0 {
                renderer?.color = originalColor
            }
        }
    }
}

// Usage:
let health = enemy.addComponent(Health.self)
let flash = enemy.addComponent(DamageFlash.self)

// When taking damage:
flash.flash()
```

### State Machine

```swift
@MainActor
public final class EnemyAI: Component {
    enum State {
        case idle
        case patrol
        case chase
        case attack
    }
    
    var state: State = .idle
    var target: Transform?
    
    public override func update(deltaTime: Float) {
        switch state {
        case .idle:
            updateIdle(deltaTime)
        case .patrol:
            updatePatrol(deltaTime)
        case .chase:
            updateChase(deltaTime)
        case .attack:
            updateAttack(deltaTime)
        }
    }
    
    private func updateIdle(_ dt: Float) { /* ... */ }
    private func updatePatrol(_ dt: Float) { /* ... */ }
    private func updateChase(_ dt: Float) { /* ... */ }
    private func updateAttack(_ dt: Float) { /* ... */ }
}
```
