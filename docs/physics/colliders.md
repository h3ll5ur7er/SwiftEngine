# Colliders

Colliders define the shape used for collision detection. A GameObject needs a collider to participate in physics interactions. A collider without a `RigidBody` is static: other bodies collide with it, but it never moves.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Collider Types                                      │
│                                                                              │
│   BoxCollider              SphereCollider           PlaneCollider           │
│   ────────────             ──────────────           ─────────────           │
│                                                                              │
│   ┌─────────┐                   ○                  ─────────────            │
│   │         │                 ╱   ╲                ─────────────            │
│   │         │                │     │               ─────────────            │
│   │         │                 ╲   ╱                ─────────────            │
│   └─────────┘                   ○                  (infinite)               │
│                                                                              │
│   AABB collision           Radius-based            Infinite plane           │
│   Good for: crates,        Good for: balls,        Good for: floors,        │
│   walls, characters        projectiles             walls, boundaries        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Base Collider Properties

All colliders share these properties:

```swift
// Whether this is a trigger (detects overlap, no collision response)
collider.isTrigger = false

// Offset from GameObject position (in world axes; the collider follows its body)
collider.center = Vec3d(0, 0.5, 0)  // Shift collider up

// Collision layer (0 collides with everything)
collider.layer = 0

// Physics material (friction, bounciness)
collider.material = PhysicsMaterial.rubber
```

---

## BoxCollider

Axis-aligned bounding box (AABB) collider. The physics simulation ignores the GameObject's rotation: the box always collides as an axis-aligned box of `halfExtents` around its world center.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BoxCollider                                        │
│                                                                              │
│                    size                                                      │
│              ◀────────────▶                                                 │
│              ┌────────────┐  ▲                                              │
│              │            │  │                                              │
│              │     ●──────│──┼── center (offset from transform)            │
│              │    origin  │  │ size.y                                       │
│              │            │  │                                              │
│              └────────────┘  ▼                                              │
│                                                                              │
│              halfExtents = size / 2                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Setup

```swift
let crate = createGameObject(name: "Crate")
crate.addComponent(MeshRenderer(mesh: CubeMesh.shared))

// Method 1: Set size directly
let box = crate.addComponent(BoxCollider.self)
box.size = Vec3d(1, 1, 1)

// Method 2: Initialize with size
let box = crate.addComponent(BoxCollider(size: Vec3d(2, 1, 3)))

// Method 3: Set half extents (size/2)
box.halfExtents = Vec3d(0.5, 0.5, 0.5)
```

### Properties

```swift
// Size of the box (width, height, depth)
box.size = Vec3d(2, 1, 3)

// Half extents (half the size on each axis)
box.halfExtents = Vec3d(1, 0.5, 1.5)

// Volume (used for mass calculation with density)
let volume = box.volume  // width * height * depth

// World-space corners (for debug/visualization)
let corners = box.worldCorners  // [Vec3d] - 8 corners, rotated by the transform

// AABB of the rotated corners in world space
let min = box.worldMin
let max = box.worldMax
// Note: these three include transform rotation, but the physics
// simulation does not - it always uses the unrotated box
```

### Common Sizes

```swift
// Unit cube
box.size = Vec3d(1, 1, 1)

// Tall pillar
box.size = Vec3d(0.5, 3, 0.5)

// Wide platform
box.size = Vec3d(5, 0.5, 5)

// Character capsule approximation
box.size = Vec3d(0.6, 1.8, 0.6)
```

---

## SphereCollider

Spherical collider for round objects.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SphereCollider                                       │
│                                                                              │
│                        radius                                                │
│                    ◀──────────▶                                             │
│                    ╭──────────╮                                             │
│                  ╱              ╲                                           │
│                 │       ●        │  ← center                                │
│                  ╲              ╱                                           │
│                    ╰──────────╯                                             │
│                                                                              │
│   Volume = (4/3) × π × radius³                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Setup

```swift
let ball = createGameObject(name: "Ball")

// Method 1: Default (radius = 0.5)
let sphere = ball.addComponent(SphereCollider.self)
sphere.radius = 1.0

// Method 2: Initialize with radius
let sphere = ball.addComponent(SphereCollider(radius: 0.5))
```

### Properties

```swift
// Radius of the sphere
sphere.radius = 0.5

// Volume (used for mass calculation)
let volume = sphere.volume  // (4/3) * π * r³
```

### Common Uses

```swift
// Ball/projectile
sphere.radius = 0.1

// Character (simple)
sphere.radius = 0.5

// Large boulder
sphere.radius = 2.0

// Trigger zone
sphere.radius = 5.0
sphere.isTrigger = true
```

---

## PlaneCollider

Infinite plane collider for floors, walls, and boundaries.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PlaneCollider                                        │
│                                                                              │
│                    normal ↑                                                  │
│                          │                                                   │
│                          │                                                   │
│     ─────────────────────●─────────────────────                             │
│                        origin                                                │
│                (transform.position)                                          │
│                                                                              │
│     The plane extends infinitely in the directions                          │
│     perpendicular to the normal                                             │
│                                                                              │
│     Efficient for floors, walls, and boundaries                             │
│     (No bounding sphere needed - always checks collision)                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Setup

```swift
let floor = createGameObject(name: "Floor")

// Default: horizontal plane (normal = up)
let plane = floor.addComponent(PlaneCollider.self)

// With custom normal
let wall = floor.addComponent(PlaneCollider(normal: Vec3d(1, 0, 0)))  // Facing +X
```

### Properties

```swift
// Normal direction in local space
// (only init(normal:distance:) normalizes it; normalize it yourself when assigning)
plane.normal = Vec3d(0, 1, 0)  // Points up

// Distance along normal from transform origin (offsets the plane along its normal)
plane.distance = 0

// World-space normal (accounts for transform rotation)
let worldNormal = plane.worldNormal

// A point on the plane in world space
let pointOnPlane = plane.worldPlanePoint
```

### Common Orientations

```swift
// Horizontal floor (default)
plane.normal = Vec3d(0, 1, 0)

// Ceiling
plane.normal = Vec3d(0, -1, 0)

// Wall facing +X
plane.normal = Vec3d(1, 0, 0)

// Wall facing -Z
plane.normal = Vec3d(0, 0, -1)

// 45-degree ramp
plane.normal = Vec3d(0, 1, 1).normalized
```

### Using Transform Rotation

```swift
// Instead of setting normal directly, you can rotate the GameObject
let wall = createGameObject(name: "Wall")
wall.transform.rotation = Quaternion.fromAxisAngle(axis: .forward, angle: Float.pi / 2)

let plane = wall.addComponent(PlaneCollider.self)
// worldNormal will be rotated by the transform
```

---

## Collision Layers

Layers control which objects can collide:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Collision Layer Matrix                               │
│                                                                              │
│   Layer 0 = "Default" - collides with EVERYTHING                            │
│                                                                              │
│                    Layer 0    Layer 1    Layer 2    Layer 3                 │
│                   ─────────  ─────────  ─────────  ─────────                │
│   Layer 0 (any)      ✅         ✅         ✅         ✅                    │
│   Layer 1            ✅         ✅         ❌         ❌                    │
│   Layer 2            ✅         ❌         ✅         ❌                    │
│   Layer 3            ✅         ❌         ❌         ✅                    │
│                                                                              │
│   Objects only collide if:                                                  │
│   1. Either has layer = 0, OR                                               │
│   2. Both have the same layer                                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Setup

```swift
// Player - collides with environment (layer 0) and enemies (layer 1)
playerCollider.layer = 1

// Enemy - collides with environment (layer 0) and players (layer 1)
enemyCollider.layer = 1

// Projectile - collides with environment (layer 0) and other layer-2 colliders only.
// A collider has a single layer, so it won't hit the layer-1 enemies above.
projectileCollider.layer = 2

// Environment - collides with everything (layer 0)
floorCollider.layer = 0
wallCollider.layer = 0
```

---

## Triggers

Triggers detect overlap without physical collision response:

```swift
// Create a trigger zone
let triggerZone = createGameObject(name: "TriggerZone")
let collider = triggerZone.addComponent(SphereCollider(radius: 5.0))
collider.isTrigger = true

// No RigidBody needed - overlaps are reported through onCollision
// (once per overlapping pair per frame), but never resolved
CollisionManager.shared.onCollision = { a, b, info in
    if a === collider || b === collider {
        print("Something entered the trigger zone")
    }
}
```

### Use Cases

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Trigger Use Cases                                  │
│                                                                              │
│   ● Pickup items         Player enters trigger → collect item               │
│   ● Damage zones         Player in zone → take damage                       │
│   ● Checkpoints          Player crosses → save progress                     │
│   ● Loading zones        Player enters → load new area                      │
│   ● Sound triggers       Player enters → play ambient sound                 │
│   ● AI awareness         Enemy in range → player detected                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Center Offset

Offset the collider from the GameObject's pivot:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Center Offset                                        │
│                                                                              │
│   center = (0, 0, 0)              center = (0, 1, 0)                        │
│   ─────────────────               ─────────────────                         │
│                                                                              │
│        ┌───────┐                       ┌───────┐                            │
│        │       │                       │       │                            │
│        │   ●   │ ← pivot               │       │                            │
│        │       │   at center           │       │                            │
│        └───────┘                       └───────┘                            │
│                                            ●  ← pivot below collider        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
// Character with pivot at feet
let character = createGameObject(name: "Character")
character.addComponent(MeshRenderer(mesh: CubeMesh.shared))

let collider = character.addComponent(BoxCollider.self)
collider.size = Vec3d(0.6, 1.8, 0.6)
collider.center = Vec3d(0, 0.9, 0)  // Shift up by half height
```

---

## Best Practices

1. **Choose the simplest shape** that approximates your object
2. **Use `PlaneCollider`** for infinite surfaces (more efficient)
3. **Use `SphereCollider`** for balls and simple round objects
4. **Use `BoxCollider`** for crates, walls, and blocky objects
5. **Set `isTrigger = true`** for non-physical detection zones
6. **Use layers** to control what collides with what
7. **Offset `center`** when pivot point isn't at object center
