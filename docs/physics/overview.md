# Physics System

GameEngine includes a built-in physics simulation with rigid body dynamics, colliders, and collision detection.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Physics System                                     │
│                                                                              │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │  PhysicsSystem  │───▶│  RigidBody      │───▶│  Collider       │         │
│  │  (Coordinator)  │    │  (Component)    │    │  (Component)    │         │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘         │
│           │                      │                      │                   │
│           │              ┌───────┴───────┐      ┌───────┴───────┐          │
│           │              │   Velocity    │      │  BoxCollider  │          │
│           │              │   Forces      │      │SphereCollider │          │
│           │              │   Mass        │      │ PlaneCollider │          │
│           ▼              └───────────────┘      └───────────────┘          │
│  ┌─────────────────┐                                                        │
│  │CollisionManager │    ┌─────────────────┐                                │
│  │ (Detection)     │───▶│ CollisionInfo   │                                │
│  └─────────────────┘    │ • contactPoint  │                                │
│                         │ • normal        │                                │
│                         │ • penetration   │                                │
│                         └─────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```swift
// Create a falling cube with physics
let cube = createGameObject(name: "PhysicsCube")
cube.transform.position = Vec3d(0, 5, 0)

// Add visual mesh
let renderer = cube.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.color = .red

// Add collider (defines the collision shape)
let collider = cube.addComponent(BoxCollider.self)
collider.size = Vec3d(1, 1, 1)

// Add rigid body (enables physics simulation)
let rigidBody = cube.addComponent(RigidBody.self)
rigidBody.mass = 1.0

// Create a floor (static/kinematic)
let floor = createGameObject(name: "Floor")
floor.addComponent(MeshRenderer(mesh: PlaneMesh(width: 20, depth: 20), color: .gray))
floor.addComponent(PlaneCollider())
floor.addComponent(RigidBody(mass: 1.0, isKinematic: true))  // Static floor
```

## Physics Pipeline

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         Physics Frame Update                                │
│                                                                             │
│  1. Accumulate    2. Integrate     3. Detect      4. Resolve    5. Apply   │
│     Forces           Velocity        Collisions     Collisions     Results │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  ┌────────┐ │
│  │ Gravity  │───▶│ v += a*dt│───▶│ Broad    │───▶│ Position │─▶│Transform│ │
│  │ User     │    │ p += v*dt│    │ Phase    │    │ Correct  │  │Velocity │ │
│  │ Forces   │    │          │    │ Narrow   │    │ Impulse  │  │         │ │
│  │ Torques  │    │ ω, θ     │    │ Phase    │    │ Response │  │         │ │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  └────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

## Fixed Timestep

Physics uses a fixed timestep (60Hz by default) for deterministic simulation:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Fixed Timestep Simulation                             │
│                                                                              │
│  Frame 1          Frame 2          Frame 3                                  │
│  dt=16ms          dt=20ms          dt=14ms                                  │
│  ┌─────┐          ┌──────┐         ┌────┐                                   │
│  │     │          │      │         │    │                                   │
│  │     │          │      │         │    │                                   │
│  └─────┘          └──────┘         └────┘                                   │
│     │                │                │                                      │
│     ▼                ▼                ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐               │
│  │              Accumulator-based stepping                   │               │
│  │  accumulator += dt                                        │               │
│  │  while accumulator >= fixedDt:                           │               │
│  │      simulate(fixedDt)    // Always 16.67ms (60Hz)       │               │
│  │      accumulator -= fixedDt                              │               │
│  └──────────────────────────────────────────────────────────┘               │
│                                                                              │
│  Result: Consistent physics regardless of frame rate                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components Overview

| Component | Purpose |
|-----------|---------|
| `RigidBody` | Enables physics simulation (mass, velocity, forces) |
| `BoxCollider` | Axis-aligned box collision shape |
| `SphereCollider` | Spherical collision shape |
| `PlaneCollider` | Infinite plane (floors, walls) |
| `PhysicsMaterial` | Surface properties (friction, bounciness) |

## Collision Detection

### Supported Collision Pairs

| Collider A | Collider B | Supported |
|------------|------------|-----------|
| Box | Box | ✅ |
| Box | Sphere | ✅ |
| Box | Plane | ✅ |
| Sphere | Sphere | ✅ |
| Sphere | Plane | ✅ |
| Plane | Plane | ❌ (infinite planes) |

### Collision Layers

```swift
// Objects only collide if on same layer (or layer 0)
cubeCollider.layer = 1
sphereCollider.layer = 2   // Won't collide with cube
floorCollider.layer = 0    // Layer 0 collides with everything
```

### Triggers

```swift
// Triggers detect overlap without physical collision
let trigger = cube.addComponent(BoxCollider.self)
trigger.isTrigger = true  // No collision response, just detection
```

## PhysicsSystem API

```swift
@MainActor
public final class PhysicsSystem {
    /// Shared instance
    public static let shared: PhysicsSystem
    
    /// Enable/disable physics globally
    public var isEnabled: Bool
    
    /// Gravity vector (default: 0, -9.81, 0)
    public var gravity: Vec3d
    
    /// Statistics
    public var collisionsThisFrame: Int { get }
    public var stepsThisFrame: Int { get }
    public var bodyCount: Int { get }
    
    /// Manual registration (usually automatic via RigidBody component)
    public func register(_ rigidBody: RigidBody)
    public func unregister(_ rigidBody: RigidBody)
    
    /// Clear all physics state
    public func clear()
}
```

### Changing Gravity

```swift
// Normal gravity
PhysicsSystem.shared.gravity = Vec3d(0, -9.81, 0)

// Low gravity (moon-like)
PhysicsSystem.shared.gravity = Vec3d(0, -1.62, 0)

// Zero gravity (space)
PhysicsSystem.shared.gravity = .zero

// Inverted gravity (ceiling walker)
PhysicsSystem.shared.gravity = Vec3d(0, 9.81, 0)

// Sideways gravity (wall runner)
PhysicsSystem.shared.gravity = Vec3d(-9.81, 0, 0)
```

## Collision Callbacks

```swift
// Set up collision callback
CollisionManager.shared.onCollision = { colliderA, colliderB, info in
    print("Collision between \(colliderA.gameObject?.name) and \(colliderB.gameObject?.name)")
    print("Contact point: \(info.contactPoint)")
    print("Normal: \(info.normal)")
    print("Penetration: \(info.penetrationDepth)")
}
```

## Best Practices

1. **Always add a RigidBody** for dynamic objects that should be affected by physics
2. **Use `isKinematic = true`** for static objects like floors and walls
3. **Match collider size to visual mesh** for accurate collisions
4. **Use `PlaneCollider`** for infinite surfaces (more efficient than large boxes)
5. **Keep mass realistic** - extreme mass ratios can cause instability
6. **Use PhysicsMaterial presets** for common surface types

## Documentation

- [RigidBody](rigidbody.md) - Dynamic physics bodies
- [Colliders](colliders.md) - Collision shapes
- [Physics Materials](materials.md) - Surface properties
