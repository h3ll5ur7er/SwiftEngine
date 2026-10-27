# Example: Custom Components

Learn how to create your own components to add custom behavior to GameObjects.

## Component Basics

Every component inherits from `Component` and can override lifecycle methods.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Component Lifecycle                            │
│                                                                          │
│  init() ─▶ awake() ─▶ onEnable() ─▶ start() ─▶ update() ─▶ onDestroy()   │
│    │         │          │             │           │            │         │
│    │         │          │             │           │            │         │
│ Construct  When added  When added   Before the  Every frame  Removed or  │
│            (once)      (if active)  first update             destroyed   │
│                        or re-enabled  (once)                             │
│                                                                          │
│  onDisable(): when the GameObject is deactivated (isActive = false)      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

`onEnable()` / `onDisable()` are called when the GameObject's `isActive` changes, when a component's `isEnabled` changes while its GameObject is active, and (`onEnable()` only) when the component is added to an active GameObject. Destroying a GameObject or removing a component calls `onDestroy()`, not `onDisable()`.

## Basic Component Template

```swift
import GameEngine

@MainActor
public final class MyComponent: Component {
    
    // MARK: - Properties
    
    /// Public properties configurable from outside
    public var speed: Float = 1.0
    
    /// Private state
    private var internalTimer: Float = 0
    
    // MARK: - Initialization
    
    /// Required initializer
    public required init() {
        super.init()
    }
    
    // MARK: - Lifecycle
    
    /// Called immediately when added to a GameObject
    public override func awake() {
        // One-time setup
    }
    
    /// Called when added to an active GameObject, or when its GameObject is reactivated
    public override func onEnable() {
        // Setup when component becomes active
    }
    
    /// Called once before first update
    public override func start() {
        // Initialize state
    }
    
    /// Called every frame
    public override func update(deltaTime: Float) {
        // Per-frame logic
    }
    
    /// Called when the GameObject is deactivated
    public override func onDisable() {
        // Cleanup when component becomes inactive
    }
    
    /// Called when the component is removed or its GameObject is destroyed
    public override func onDestroy() {
        // Final cleanup
    }
}
```

---

## Example: Health System

```swift
import GameEngine

/// Protocol for objects that can take damage
public protocol Damageable: AnyObject {
    func takeDamage(_ amount: Float)
    func heal(_ amount: Float)
}

@MainActor
public final class Health: Component, Damageable {
    
    // MARK: - Properties
    
    /// Maximum health points
    public var maxHealth: Float = 100
    
    /// Current health points
    public private(set) var currentHealth: Float = 100
    
    /// Whether the entity is alive
    public var isAlive: Bool { currentHealth > 0 }
    
    /// Health as percentage (0-1)
    public var healthPercent: Float { currentHealth / maxHealth }
    
    // MARK: - Events
    
    /// Called when health changes
    public var onHealthChanged: ((Float, Float) -> Void)?  // (current, max)
    
    /// Called when entity dies
    public var onDeath: (() -> Void)?
    
    /// Called when entity is healed
    public var onHealed: ((Float) -> Void)?
    
    /// Called when entity takes damage
    public var onDamaged: ((Float) -> Void)?
    
    // MARK: - Initialization
    
    public required init() {
        super.init()
    }
    
    public override func start() {
        currentHealth = maxHealth
    }
    
    // MARK: - Damageable
    
    public func takeDamage(_ amount: Float) {
        guard isAlive && amount > 0 else { return }
        
        let previousHealth = currentHealth
        currentHealth = max(0, currentHealth - amount)
        
        onDamaged?(amount)
        onHealthChanged?(currentHealth, maxHealth)
        
        if !isAlive {
            onDeath?()
        }
    }
    
    public func heal(_ amount: Float) {
        guard isAlive && amount > 0 else { return }
        
        let previousHealth = currentHealth
        currentHealth = min(maxHealth, currentHealth + amount)
        
        let actualHeal = currentHealth - previousHealth
        if actualHeal > 0 {
            onHealed?(actualHeal)
            onHealthChanged?(currentHealth, maxHealth)
        }
    }
    
    /// Reset health to full
    public func reset() {
        currentHealth = maxHealth
        onHealthChanged?(currentHealth, maxHealth)
    }
}
```

### Usage

```swift
let enemy = createGameObject(name: "Enemy")
let health = enemy.addComponent(Health.self)
health.maxHealth = 50

health.onDeath = {
    print("Enemy defeated!")
}

health.onDamaged = { damage in
    print("Took \(damage) damage!")
}

// Later...
health.takeDamage(25)  // "Took 25 damage!"
health.takeDamage(30)  // "Took 30 damage!" then "Enemy defeated!"
```

---

## Example: Floating Animation

```swift
import GameEngine

@MainActor
public final class FloatingAnimation: Component {
    
    // MARK: - Configuration
    
    /// Height of the float
    public var amplitude: Float = 0.5
    
    /// Speed of oscillation
    public var frequency: Float = 1.0
    
    /// Axis of movement
    public var axis: Vec3d = .up
    
    /// Random phase offset
    public var randomizePhase: Bool = true
    
    // MARK: - State
    
    private var startPosition: Vec3d = .zero
    private var time: Float = 0
    private var phase: Float = 0
    
    // MARK: - Lifecycle
    
    public required init() {
        super.init()
    }
    
    public override func start() {
        startPosition = transform.localPosition
        
        if randomizePhase {
            phase = Float.random(in: 0...(Float.pi * 2))
        }
    }
    
    public override func update(deltaTime: Float) {
        time += deltaTime
        
        let offset = sin(time * frequency * Float.pi * 2 + phase) * amplitude
        transform.localPosition = startPosition + axis.normalized * offset
    }
}
```

### Usage

```swift
// Create floating platforms
for i in 0..<5 {
    let platform = createGameObject(name: "Platform_\(i)")
    let renderer = platform.addComponent(MeshRenderer.self)
    renderer.mesh = CubeMesh.shared
    renderer.color = .cyan
    
    let floater = platform.addComponent(FloatingAnimation.self)
    floater.amplitude = 0.3 + Float(i) * 0.1
    floater.frequency = 0.5 + Float(i) * 0.1
}
```

---

## Example: Follow Target

```swift
import GameEngine

@MainActor
public final class FollowTarget: Component {
    
    // MARK: - Configuration
    
    /// Target to follow
    public weak var target: Transform?
    
    /// Movement speed
    public var speed: Float = 5.0
    
    /// Distance to maintain from target
    public var stoppingDistance: Float = 1.0
    
    /// Smoothing factor (0 = instant, 1 = no movement)
    public var smoothing: Float = 0.1
    
    /// Only follow on XZ plane (ignore Y)
    public var lockY: Bool = false
    
    // MARK: - State
    
    private var velocity: Vec3d = .zero
    
    // MARK: - Lifecycle
    
    public required init() {
        super.init()
    }
    
    public override func update(deltaTime: Float) {
        guard let target = target else { return }
        
        var targetPosition = target.position
        let currentPosition = transform.position
        
        if lockY {
            targetPosition.y = currentPosition.y
        }
        
        let direction = targetPosition - currentPosition
        let distance = direction.length
        
        guard distance > stoppingDistance else {
            velocity = .zero
            return
        }
        
        let desiredVelocity = direction.normalized * speed
        velocity = velocity.lerp(to: desiredVelocity, t: 1.0 - smoothing)
        
        transform.position = currentPosition + velocity * deltaTime
        
        // Face the target
        if distance > 0.01 {
            let lookDirection = direction.normalized
            transform.rotation = Quaternion.lookRotation(
                forward: lookDirection,
                up: .up
            )
        }
    }
}
```

### Usage

```swift
let player = createGameObject(name: "Player")
// ... setup player ...

let follower = createGameObject(name: "Follower")
follower.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .red))

let follow = follower.addComponent(FollowTarget.self)
follow.target = player.transform
follow.speed = 3.0
follow.stoppingDistance = 2.0
```

---

## Example: Trigger Zone

```swift
import GameEngine

@MainActor
public final class TriggerZone: Component {
    
    // MARK: - Configuration
    
    /// Size of the trigger area
    public var size: Vec3d = Vec3d(2, 2, 2)
    
    /// Tags that can trigger this zone
    public var triggerTags: Set<String> = ["Player"]
    
    // MARK: - Events
    
    public var onEnter: ((GameObject) -> Void)?
    public var onExit: ((GameObject) -> Void)?
    public var onStay: ((GameObject) -> Void)?
    
    // MARK: - State
    
    private var objectsInZone: Set<ObjectIdentifier> = []
    private weak var scene: GameObjectScene?
    
    // MARK: - Lifecycle
    
    public required init() {
        super.init()
    }
    
    public override func start() {
        scene = gameObject?.scene
    }
    
    public override func update(deltaTime: Float) {
        guard let scene = scene else { return }
        
        var currentObjects: Set<ObjectIdentifier> = []
        
        // Check all objects with matching tags
        for obj in triggerTags.flatMap({ scene.findWithTag($0) }) {
            if isInside(obj.transform.position) {
                let id = ObjectIdentifier(obj)
                currentObjects.insert(id)
                
                if !objectsInZone.contains(id) {
                    onEnter?(obj)
                } else {
                    onStay?(obj)
                }
            }
        }
        
        // Check for exits
        for id in objectsInZone {
            if !currentObjects.contains(id) {
                // Object exited - we'd need to track the object reference
                // to call onExit properly
            }
        }
        
        objectsInZone = currentObjects
    }
    
    private func isInside(_ position: Vec3d) -> Bool {
        let center = transform.position
        let halfSize = size * 0.5
        
        return position.x >= center.x - halfSize.x &&
               position.x <= center.x + halfSize.x &&
               position.y >= center.y - halfSize.y &&
               position.y <= center.y + halfSize.y &&
               position.z >= center.z - halfSize.z &&
               position.z <= center.z + halfSize.z
    }
}
```

---

## Example: Timer Component

```swift
import GameEngine

@MainActor
public final class Timer: Component {
    
    // MARK: - Configuration
    
    /// Duration in seconds
    public var duration: Float = 1.0
    
    /// Whether timer repeats
    public var repeating: Bool = false
    
    /// Whether timer starts automatically
    public var autoStart: Bool = false
    
    // MARK: - Events
    
    public var onComplete: (() -> Void)?
    public var onTick: ((Float) -> Void)?  // Progress 0-1
    
    // MARK: - State
    
    private var elapsed: Float = 0
    private var isRunning: Bool = false
    
    public var progress: Float { elapsed / duration }
    public var remaining: Float { max(0, duration - elapsed) }
    
    // MARK: - Lifecycle
    
    public required init() {
        super.init()
    }
    
    public override func start() {
        if autoStart {
            startTimer()
        }
    }
    
    public override func update(deltaTime: Float) {
        guard isRunning else { return }
        
        elapsed += deltaTime
        onTick?(min(1.0, progress))
        
        if elapsed >= duration {
            onComplete?()
            
            if repeating {
                elapsed = 0
            } else {
                isRunning = false
            }
        }
    }
    
    // MARK: - Control
    
    public func startTimer() {
        elapsed = 0
        isRunning = true
    }
    
    public func stop() {
        isRunning = false
    }
    
    public func pause() {
        isRunning = false
    }
    
    public func resume() {
        isRunning = true
    }
    
    public func reset() {
        elapsed = 0
    }
}
```

### Usage

```swift
let spawner = createGameObject(name: "Spawner")
let timer = spawner.addComponent(Timer.self)
timer.duration = 3.0
timer.repeating = true
timer.autoStart = true

timer.onComplete = { [weak self] in
    self?.spawnEnemy()
}
```

---

## Component Best Practices

### 1. Use Required Initializer

```swift
// ✅ Correct - addComponent(MyComponent.self) calls this
public required init() {
    super.init()
}

// ✅ Also fine - convenience initializers alongside the required one
public convenience init(speed: Float) {
    self.init()
    self.speed = speed
}

// ❌ Wrong - a designated init without `required init()` won't compile
public init(speed: Float) {
    self.speed = speed
    super.init()
}
```

### 2. Configure After Adding

```swift
// ✅ Add by type, then configure
let comp = obj.addComponent(MyComponent.self)
comp.speed = 5.0

// ✅ Or pass an already configured instance
obj.addComponent(MyComponent(speed: 5.0))
obj.addComponent(RigidBody(mass: 2))

// ❌ addComponent has no extra configuration parameters
obj.addComponent(MyComponent.self, speed: 5.0)
```

### 3. Handle Optional References

```swift
// ✅ Safe
public override func update(deltaTime: Float) {
    guard let target = target else { return }
    // Use target...
}

// ❌ Crashes if target is nil
public override func update(deltaTime: Float) {
    let pos = target!.position
}
```

### 4. Use Weak References for Cross-References

```swift
// ✅ Prevents retain cycles
public weak var target: Transform?
public weak var other: Component?

// ❌ May cause memory leaks
public var target: Transform?
```

### 5. Clean Up in onDisable and onDestroy

```swift
public override func onDisable() {
    // GameObject deactivated: cancel any ongoing operations
    velocity = .zero
    target = nil
}

public override func onDestroy() {
    // Removed or destroyed (onDisable is not called in this case)
    target = nil
}
```

### 6. Cache Component Lookups

```swift
// ✅ Cache in start()
private var renderer: MeshRenderer?

public override func start() {
    renderer = gameObject?.getComponent(MeshRenderer.self)
}

// ❌ Look up every frame
public override func update(deltaTime: Float) {
    let renderer = gameObject?.getComponent(MeshRenderer.self)
    renderer?.color = .red
}
```
