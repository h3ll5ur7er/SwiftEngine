# Physics Materials

Physics materials define the surface properties that affect how objects interact during collisions.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PhysicsMaterial                                      │
│                                                                              │
│   Properties                           Combine Modes                         │
│   ──────────                           ─────────────                         │
│   friction: Float                      .average  (a + b) / 2                │
│   bounciness: Float                    .minimum  min(a, b)                  │
│   density: Float                       .maximum  max(a, b)                  │
│   frictionCombine: CombineMode         .multiply a × b                      │
│   bounceCombine: CombineMode                                                │
│                                                                              │
│   Presets: .default, .rubber, .ice, .metal, .wood, .bouncyBall, .stone     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Properties

### Friction

Controls resistance to sliding (0 = frictionless, 1 = high friction):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Friction                                           │
│                                                                              │
│   friction = 0.0 (ice)              friction = 1.0 (rubber)                 │
│   ──────────────────                ─────────────────────                   │
│                                                                              │
│      ○────────▶                        ○──▶                                 │
│   ════════════════                  ════════════════                        │
│   Object slides freely              Object stops quickly                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
material.friction = 0.0   // Ice - no friction
material.friction = 0.3   // Metal - low friction
material.friction = 0.5   // Wood - moderate friction
material.friction = 0.8   // Rubber - high friction
```

### Bounciness

Controls energy preserved on collision (0 = no bounce, 1 = perfect bounce):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Bounciness                                          │
│                                                                              │
│   bounciness = 0.0                   bounciness = 1.0                       │
│   ────────────────                   ─────────────────                      │
│                                                                              │
│         │                                  ╲    ╱                            │
│         ▼                                   ╲  ╱                             │
│   ──────○──────                              ╲╱                              │
│                                        ──────○──────                        │
│   Ball stops on impact               Ball bounces back to                   │
│                                      same height                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
material.bounciness = 0.0   // Clay - no bounce
material.bounciness = 0.3   // Wood - slight bounce
material.bounciness = 0.8   // Rubber - bouncy
material.bounciness = 0.95  // Super ball - very bouncy
```

### Density

Mass per unit volume (kg/m³), used to calculate mass from collider volume:

```
Mass = Density × Volume

┌─────────────────────────────────────────────────────────────────────────────┐
│                      Common Densities (kg/m³)                                │
│                                                                              │
│   Material          Density    Example                                      │
│   ────────          ───────    ───────                                      │
│   Air               1.2        (reference)                                  │
│   Wood (balsa)      160        Light props                                  │
│   Wood (oak)        600        Furniture                                    │
│   Water             1000       Reference liquid                             │
│   Rubber            1100       Tires, balls                                 │
│   Concrete          2400       Buildings                                    │
│   Aluminum          2700       Light metal                                  │
│   Steel             7800       Heavy metal                                  │
│   Gold              19300      Very heavy                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
material.density = 500.0    // Light (cork, light wood)
material.density = 1000.0   // Water (default)
material.density = 2400.0   // Stone/concrete
material.density = 7800.0   // Steel
```

## Presets

```swift
// Default - moderate friction, no bounce
PhysicsMaterial.default
// friction: 0.4, bounciness: 0.0, density: 1000

// Rubber - high friction, bouncy
PhysicsMaterial.rubber
// friction: 0.8, bounciness: 0.8, density: 1100

// Ice - very low friction, slight bounce
PhysicsMaterial.ice
// friction: 0.05, bounciness: 0.1, density: 917

// Metal - low friction, slight bounce
PhysicsMaterial.metal
// friction: 0.3, bounciness: 0.2, density: 7800

// Wood - moderate friction and bounce
PhysicsMaterial.wood
// friction: 0.5, bounciness: 0.3, density: 600

// Bouncy Ball - high bounce
PhysicsMaterial.bouncyBall
// friction: 0.6, bounciness: 0.95, density: 500

// Stone - moderate friction, low bounce
PhysicsMaterial.stone
// friction: 0.6, bounciness: 0.1, density: 2400
```

## Using Materials

```swift
// Apply preset to collider
let ball = createGameObject(name: "Ball")
let collider = ball.addComponent(SphereCollider(radius: 0.5))
collider.material = .rubber

// Create custom material
let customMaterial = PhysicsMaterial(
    friction: 0.3,
    bounciness: 0.7,
    density: 800.0
)
collider.material = customMaterial
```

## Combine Modes

When two objects collide, their material properties are combined:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Combine Modes                                        │
│                                                                              │
│   Object A               Object B               Result                       │
│   friction: 0.8          friction: 0.2                                      │
│                                                                              │
│   .average    (0.8 + 0.2) / 2  = 0.5                                       │
│   .minimum    min(0.8, 0.2)    = 0.2                                       │
│   .maximum    max(0.8, 0.2)    = 0.8                                       │
│   .multiply   0.8 × 0.2        = 0.16                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
var material = PhysicsMaterial.default

// How friction is combined between two colliding objects
material.frictionCombine = .average   // Default
material.frictionCombine = .minimum   // Use lower friction (slippery wins)
material.frictionCombine = .maximum   // Use higher friction (sticky wins)
material.frictionCombine = .multiply  // Both affect result

// How bounciness is combined
material.bounceCombine = .average     // Default
material.bounceCombine = .maximum     // More bouncy result
```

## Mass Calculation

When a RigidBody is attached, mass can be calculated from the collider's volume and material's density:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Mass Calculation                                        │
│                                                                              │
│   Box:     mass = density × (width × height × depth)                        │
│   Sphere:  mass = density × (4/3 × π × radius³)                             │
│                                                                              │
│   Example: Rubber ball (radius 0.5m)                                        │
│   ─────────────────────────────────                                         │
│   Volume = (4/3) × π × 0.5³ = 0.524 m³                                     │
│   Density = 1100 kg/m³ (rubber)                                             │
│   Mass = 0.524 × 1100 = 576 kg                                              │
│                                                                              │
│   Note: For game purposes, you typically set mass                           │
│   directly rather than relying on realistic density                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
// Get calculated mass from collider
let calculatedMass = collider.calculatedMass

// Or set mass directly on RigidBody
rigidBody.mass = 1.0  // Override calculated mass
```

## Common Scenarios

### Bouncy Ball

```swift
let ball = createGameObject(name: "BouncyBall")
let collider = ball.addComponent(SphereCollider(radius: 0.2))
collider.material = .bouncyBall

let rb = ball.addComponent(RigidBody.self)
rb.mass = 0.1
```

### Ice Surface

```swift
let iceFloor = createGameObject(name: "IceRink")
let collider = iceFloor.addComponent(PlaneCollider())
collider.material = .ice

iceFloor.addComponent(RigidBody(mass: 1.0, isKinematic: true))
```

### Heavy Metal Crate

```swift
let crate = createGameObject(name: "MetalCrate")
let collider = crate.addComponent(BoxCollider(size: Vec3d(1, 1, 1)))
collider.material = .metal

let rb = crate.addComponent(RigidBody.self)
rb.mass = 100.0  // Heavy!
```

### Trampoline

```swift
let trampoline = createGameObject(name: "Trampoline")
let collider = trampoline.addComponent(BoxCollider(size: Vec3d(3, 0.2, 3)))

// Custom super bouncy material
var bouncyMaterial = PhysicsMaterial(
    friction: 0.8,
    bounciness: 1.2,  // > 1.0 adds energy!
    density: 500.0
)
bouncyMaterial.bounceCombine = .maximum  // Always bouncy
collider.material = bouncyMaterial

trampoline.addComponent(RigidBody(mass: 1.0, isKinematic: true))
```

## Best Practices

1. **Use presets** for common surfaces (rubber, ice, metal)
2. **Keep bounciness ≤ 1.0** for realistic physics (> 1.0 adds energy)
3. **Set mass directly** on RigidBody rather than relying on density
4. **Use `.minimum` friction combine** for "slippery always wins" behavior
5. **Use `.maximum` bounce combine** for "bouncy always wins" behavior
6. **Test your materials** - small changes can have big effects
