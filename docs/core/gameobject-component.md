# GameObjects & Components

The entity-component system is the foundation of GameEngine.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          GameObject                                  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ name: "Player"                                                 │  │
│  │ tag: "player"                                                  │  │
│  │ isActive: true                                                 │  │
│  │                                                                │  │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │  │
│  │ │  Transform  │  │   Camera    │  │   Player    │            │  │
│  │ │  (always)   │  │             │  │  Controller │            │  │
│  │ └─────────────┘  └─────────────┘  └─────────────┘            │  │
│  │                                                                │  │
│  │ children: [...]                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Creating GameObjects

### In a Scene

```swift
@MainActor
public final class MyScene: GameObjectScene {
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Create at origin
        let obj1 = createGameObject(name: "Object1")
        
        // Create at specific position
        let obj2 = createGameObject(name: "Object2", at: Vec3d(5, 0, 0))
        
        // Create with parent (becomes child)
        let child = createGameObject(name: "Child", parent: obj1)
    }
}
```

### Programmatically

```swift
// Create standalone (not in scene)
let gameObject = GameObject(name: "MyObject")

// Access transform
gameObject.transform.localPosition = Vec3d(1, 2, 3)
```

## Adding Components

```swift
let player = createGameObject(name: "Player")

// Method 1: Add by type (creates new instance)
let camera = player.addComponent(Camera.self)

// Method 2: Add existing instance
let controller = PlayerController()
controller.moveSpeed = 10.0
player.addComponent(controller)

// Configure component
camera.fieldOfView = 75.0
```

## Finding Components

### On a Single GameObject

```swift
// Get first component of type (nil if not found)
let camera = gameObject.getComponent(Camera.self)

// Get all components of type
let renderers = gameObject.getComponents(MeshRenderer.self)

// Check if has component
let hasCamera = gameObject.hasComponent(Camera.self)
```

### In the Entire Scene

```swift
// Find first component of type in scene
let mainCamera = findComponentOfType(Camera.self)

// Find all components of type in scene
let allRenderers = findComponentsOfType(MeshRenderer.self)
```

### Finding GameObjects

```swift
// Find by name (first match)
let player = findGameObject(named: "Player")

// Find all with name
let enemies = findGameObjects(named: "Enemy")

// Find by tag
let collectibles = findGameObjectsWithTag("collectible")
```

## Removing Components

```swift
// Remove specific component
let camera = gameObject.getComponent(Camera.self)
gameObject.removeComponent(camera)

// Remove all of type
gameObject.removeComponents(ofType: MeshRenderer.self)
```

## Destroying GameObjects

```swift
// Mark for destruction (destroyed at end of frame)
destroyGameObject(enemy)

// Immediate destruction
gameObject.destroy()
```

## Component Lifecycle

```swift
@MainActor
public final class MyComponent: Component {
    
    public required init() {
        super.init()
        // Called during creation
    }
    
    public override func awake() {
        // Called immediately when added to GameObject
        // Good for: initial setup
    }
    
    public override func onEnable() {
        // Called when component becomes enabled
        // Good for: registering with systems
    }
    
    public override func start() {
        // Called before first update
        // Good for: finding other components
    }
    
    public override func update(deltaTime: Float) {
        // Called every frame
        // Good for: game logic
    }
    
    public override func lateUpdate(deltaTime: Float) {
        // Called after all update() calls
        // Good for: camera follow
    }
    
    public override func fixedUpdate(fixedDeltaTime: Float) {
        // Called at fixed interval (physics)
        // Good for: physics simulation
    }
    
    public override func onDisable() {
        // Called when component becomes disabled
        // Good for: unregistering from systems
    }
    
    public override func onDestroy() {
        // Called when component is removed
        // Good for: cleanup
    }
}
```

## Accessing Other Components

```swift
public override func start() {
    // Access transform (always available)
    transform.localPosition = Vec3d(0, 1, 0)
    
    // Access other components on same GameObject
    if let renderer = gameObject?.getComponent(MeshRenderer.self) {
        renderer.material = Material.solid(.red)
    }
    
    // Access parent's components
    if let parent = gameObject?.parent {
        let parentController = parent.getComponent(Controller.self)
    }
}
```

## Parent-Child Hierarchy

```
Scene
├── Player                    ← Root GameObject
│   ├── Transform
│   ├── Camera               ← Moves with Player
│   └── Gun                  ← Child GameObject
│       ├── Transform        ← Relative to Player
│       └── MeshRenderer
│
└── World
    ├── Ground
    └── Trees
        ├── Tree1
        ├── Tree2
        └── Tree3
```

### Working with Hierarchy

```swift
// Create hierarchy
let player = createGameObject(name: "Player")
let gun = createGameObject(name: "Gun", parent: player)

// Gun position is relative to player
gun.transform.localPosition = Vec3d(0.5, 0, -0.3)

// Access hierarchy
let parent = gun.parent           // player
let children = player.children    // [gun]

// Reparent
gun.setParent(nil)               // Becomes root
gun.setParent(player)            // Back to player

// World position (accounts for parent transforms)
let worldPos = gun.transform.worldPosition
```

## Common Patterns

### Component Communication

```swift
// Pattern 1: Direct reference (set in inspector/code)
public final class Gun: Component {
    var ammoDisplay: AmmoUI?
    
    public override func start() {
        // Find required components
        ammoDisplay = findComponentOfType(AmmoUI.self)
    }
    
    func fire() {
        ammo -= 1
        ammoDisplay?.updateCount(ammo)
    }
}

// Pattern 2: Find at runtime
public final class Enemy: Component {
    public override func update(deltaTime: Float) {
        // Find player each frame (or cache it)
        if let player = findGameObject(named: "Player") {
            let direction = player.transform.worldPosition - transform.worldPosition
            // Move toward player...
        }
    }
}
```

### Component Dependencies

```swift
public final class MeshRenderer: Component {
    public override func awake() {
        // Ensure we have a Material
        if material == nil {
            material = Material.solid(.white)
        }
    }
}
```

## Best Practices

1. **Keep components focused** - One responsibility per component
2. **Use `start()` for finding dependencies** - Other components are guaranteed to exist
3. **Cache references** - Don't search every frame
4. **Use weak references for siblings** - Avoid retain cycles
5. **Prefer composition** - Multiple simple components over one complex one

```swift
// ❌ Bad: One giant component
class PlayerController: Component {
    // Handles input, movement, shooting, inventory, health...
}

// ✅ Good: Focused components
class Movement: Component { }      // Handles movement
class Health: Component { }        // Handles damage/healing
class Inventory: Component { }     // Handles items
class WeaponSystem: Component { }  // Handles weapons
```
