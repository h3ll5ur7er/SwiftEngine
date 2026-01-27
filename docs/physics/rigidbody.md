# RigidBody

The `RigidBody` component enables physics simulation for a GameObject.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             RigidBody                                        │
│                                                                              │
│   Properties                           State                                 │
│   ──────────                           ─────                                 │
│   mass: Float                          velocity: Vec3d                       │
│   isKinematic: Bool                    angularVelocity: Vec3d               │
│   angularDrag: Float                   accumulatedForce: Vec3d              │
│   maxVelocity: Float                   accumulatedTorque: Vec3d             │
│   maxAngularVelocity: Float                                                 │
│                                                                              │
│   Methods                                                                    │
│   ───────                                                                    │
│   addForce(Vec3d)         ──▶  Apply continuous force                       │
│   addTorque(Vec3d)        ──▶  Apply continuous rotation                    │
│   addImpulse(Vec3d)       ──▶  Apply instant velocity change                │
│   addAngularImpulse(Vec3d)──▶  Apply instant rotation change                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Basic Setup

```swift
let ball = createGameObject(name: "Ball")
ball.transform.position = Vec3d(0, 10, 0)

// Visual
ball.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .red))

// Physics shape
ball.addComponent(SphereCollider(radius: 0.5))

// Enable physics
let rb = ball.addComponent(RigidBody.self)
rb.mass = 1.0
```

## Dynamic vs Kinematic

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Dynamic vs Kinematic Bodies                               │
│                                                                              │
│   DYNAMIC (isKinematic = false)        KINEMATIC (isKinematic = true)       │
│   ─────────────────────────────        ──────────────────────────────       │
│                                                                              │
│   ● Affected by gravity                ● NOT affected by gravity            │
│   ● Affected by forces                 ● NOT affected by forces             │
│   ● Responds to collisions             ● Can push dynamic objects           │
│   ● Moves via physics                  ● Moved via transform directly       │
│                                                                              │
│   Use for:                             Use for:                              │
│   • Player characters                  • Floors, walls                       │
│   • Projectiles                        • Moving platforms                    │
│   • Physics objects                    • Animated obstacles                  │
│   • Debris, particles                  • Doors, elevators                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dynamic Body

```swift
// Dynamic body - affected by physics
let crate = createGameObject(name: "Crate")
crate.addComponent(BoxCollider(size: Vec3d(1, 1, 1)))

let rb = crate.addComponent(RigidBody.self)
rb.mass = 10.0
rb.isKinematic = false  // Default - responds to physics
```

### Kinematic Body

```swift
// Kinematic body - not affected by physics, but can affect others
let floor = createGameObject(name: "Floor")
floor.addComponent(PlaneCollider())

let rb = floor.addComponent(RigidBody.self)
rb.mass = 1.0  // Mass doesn't matter for kinematic
rb.isKinematic = true  // Static - moved via transform only
```

## Properties

### Mass

```swift
// Light object (beach ball)
rb.mass = 0.1

// Normal object (soccer ball)
rb.mass = 0.5

// Heavy object (bowling ball)
rb.mass = 7.0

// Very heavy object (anvil)
rb.mass = 100.0
```

**Note:** Mass affects how objects respond to forces and collisions. Heavier objects push lighter ones more.

### Drag

```swift
// Angular drag - resistance to rotation (0 = no drag, 1 = full drag)
rb.angularDrag = 0.05  // Default - slight resistance

// No angular drag (frictionless rotation)
rb.angularDrag = 0.0

// High angular drag (heavy resistance)
rb.angularDrag = 0.5
```

### Velocity Limits

```swift
// Maximum linear velocity (prevents explosion)
rb.maxVelocity = 50.0  // Default

// Maximum angular velocity (radians per second)
rb.maxAngularVelocity = 20.0  // Default

// Slower moving object
rb.maxVelocity = 10.0
rb.maxAngularVelocity = 5.0
```

## Applying Forces

### Force vs Impulse

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Force vs Impulse                                      │
│                                                                              │
│   FORCE                                IMPULSE                               │
│   ─────                                ───────                               │
│   Continuous acceleration              Instant velocity change               │
│   Applied every frame                  Applied once                          │
│   F = ma                               Δv = I/m                              │
│                                                                              │
│   Use for:                             Use for:                              │
│   • Engines, thrusters                 • Jumps                               │
│   • Wind                               • Explosions                          │
│   • Magnetism                          • Bullets                             │
│   • Swimming                           • Bouncing                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Forces (Continuous)

```swift
// Apply force each frame (e.g., in update)
public override func update(deltaTime: Float) {
    guard let rb = gameObject?.getComponent(RigidBody.self) else { return }
    
    // Thrust upward
    if isThrusting {
        rb.addForce(Vec3d(0, 500, 0))  // Continuous thrust
    }
    
    // Wind from the right
    rb.addForce(Vec3d(-10, 0, 0))
}
```

### Impulses (Instant)

```swift
// Jump - apply once when button pressed
func jump() {
    guard let rb = gameObject?.getComponent(RigidBody.self) else { return }
    rb.addImpulse(Vec3d(0, 10, 0))  // Instant upward velocity
}

// Explosion - push away from point
func applyExplosion(center: Vec3d, force: Float) {
    let direction = (transform.position - center).normalized
    rigidBody.addImpulse(direction * force)
}
```

### Torques (Rotation)

```swift
// Apply rotation force
rb.addTorque(Vec3d(0, 10, 0))  // Spin around Y axis

// Apply instant angular velocity change
rb.addAngularImpulse(Vec3d(0, 5, 0))  // Instant spin
```

## Reading State

```swift
// Get current velocity
let velocity = rb.velocity
let speed = velocity.length

// Get angular velocity
let angularVel = rb.angularVelocity
let spinSpeed = angularVel.length

// Check if moving
let isMoving = velocity.squaredLength > 0.01
```

## Setting Velocity Directly

```swift
// Set velocity directly (bypasses physics accumulation)
rb.setVelocity(Vec3d(10, 0, 0))

// Set angular velocity directly
rb.setAngularVelocity(Vec3d(0, 5, 0))

// Stop all movement
rb.setVelocity(.zero)
rb.setAngularVelocity(.zero)
```

## Common Patterns

### Jump with Ground Check

```swift
@MainActor
public final class Jumper: Component {
    var jumpForce: Float = 10.0
    var isGrounded: Bool = false
    private var rigidBody: RigidBody?
    
    public override func start() {
        rigidBody = gameObject?.getComponent(RigidBody.self)
    }
    
    func jump() {
        guard isGrounded, let rb = rigidBody else { return }
        rb.addImpulse(Vec3d(0, jumpForce, 0))
        isGrounded = false
    }
    
    // Called from collision detection
    func onGroundContact() {
        isGrounded = true
    }
}
```

### Knockback on Hit

```swift
func applyKnockback(from attacker: Vec3d, force: Float) {
    guard let rb = gameObject?.getComponent(RigidBody.self) else { return }
    
    let direction = (transform.position - attacker).normalized
    rb.addImpulse(direction * force)
    
    // Also add some upward lift
    rb.addImpulse(Vec3d(0, force * 0.3, 0))
}
```

### Constant Thrust (Rocket)

```swift
@MainActor
public final class Rocket: Component {
    var thrustForce: Float = 100.0
    var isThrusting: Bool = false
    private var rigidBody: RigidBody?
    
    public override func start() {
        rigidBody = gameObject?.getComponent(RigidBody.self)
    }
    
    public override func update(deltaTime: Float) {
        guard isThrusting, let rb = rigidBody else { return }
        
        // Apply thrust in the rocket's forward direction
        let thrustDirection = transform.forward
        rb.addForce(thrustDirection * thrustForce)
    }
}
```

### Floating Object

```swift
@MainActor
public final class Floater: Component {
    var floatHeight: Float = 2.0
    var floatForce: Float = 15.0
    private var rigidBody: RigidBody?
    
    public override func start() {
        rigidBody = gameObject?.getComponent(RigidBody.self)
    }
    
    public override func update(deltaTime: Float) {
        guard let rb = rigidBody else { return }
        
        let currentHeight = transform.position.y
        let heightDiff = floatHeight - currentHeight
        
        // Apply upward force proportional to how far below float height
        if heightDiff > 0 {
            rb.addForce(Vec3d(0, heightDiff * floatForce, 0))
        }
    }
}
```

## Best Practices

1. **Use appropriate mass** - Keep mass ratios reasonable (< 100:1)
2. **Use impulses for instant effects** - Jumps, explosions, knockback
3. **Use forces for continuous effects** - Thrust, wind, magnetism
4. **Don't modify transform directly** for dynamic bodies - Let physics move it
5. **Use kinematic for moved-by-code objects** - Platforms, elevators
6. **Set velocity limits** to prevent physics explosion
7. **Match collider to visual** for expected behavior
