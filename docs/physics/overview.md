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
│  │ (onCollision)   │───▶│ CollisionInfo   │                                │
│  └─────────────────┘    │ • contactPoint  │                                │
│                         │ • normal        │                                │
│                         │ • penetration   │                                │
│                         └─────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

`PhysicsSystem.shared` gathers snapshots of every `RigidBody` and enabled collider, runs the fixed-timestep `PhysicsSimulation` (which does detection and response), writes positions and velocities back, and reports each colliding pair through `CollisionManager.shared.onCollision`. `CollisionManager` itself is only the collider registry plus that callback.

The engine steps physics every frame via `ActorCoordinator.shared.update`, after the scene update and before rendering. It runs inline on the main actor by default; set `ActorCoordinator.shared.asyncPhysicsEnabled = true` to run the same simulation on `PhysicsActor` (see [Actors](../architecture/actors.md)).

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

// Create a floor (static: a collider without a RigidBody never moves)
let floor = createGameObject(name: "Floor")
floor.addComponent(MeshRenderer(mesh: PlaneMesh(width: 20, depth: 20), color: .gray))
floor.addComponent(PlaneCollider())
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
│  │  accumulator += min(dt, maxDeltaTime)   // cap: 33ms     │               │
│  │  while accumulator >= fixedDt                            │               │
│  │        && steps < maxStepsPerFrame:      // max 4        │               │
│  │      simulate(fixedDt)    // Always 16.67ms (60Hz)       │               │
│  │      accumulator -= fixedDt                              │               │
│  │  if accumulator > fixedDt * maxStepsPerFrame:            │               │
│  │      accumulator = 0      // drop time we can't catch up │               │
│  └──────────────────────────────────────────────────────────┘               │
│                                                                              │
│  Result: Consistent physics regardless of frame rate                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

These values live in `PhysicsSettings` (`fixedDeltaTime` 1/60, `maxDeltaTime` 1/30, `maxStepsPerFrame` 4, `gravity`, `contactAngularResponse` 0), exposed as `PhysicsSystem.shared.settings`. A 50ms frame is clamped to 33ms and runs 2 steps.

## Components Overview

| Component | Purpose |
|-----------|---------|
| `RigidBody` | Enables physics simulation (mass, velocity, forces) |
| `BoxCollider` | Axis-aligned box collision shape (rotation ignored) |
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

Trigger overlaps are reported through `CollisionManager.shared.onCollision` like any other pair, but are never resolved. Two triggers don't report against each other.

## PhysicsSystem API

```swift
@MainActor
public final class PhysicsSystem {
    /// Shared instance
    public static let shared: PhysicsSystem
    
    /// Enable/disable physics globally
    public var isEnabled: Bool
    
    /// Simulation parameters (timestep, step cap, gravity, contactAngularResponse)
    public var settings: PhysicsSettings
    
    /// Gravity vector (default: 0, -9.81, 0) - shorthand for settings.gravity
    public var gravity: Vec3d
    
    /// Statistics
    public var collisionsThisFrame: Int { get }
    public var stepsThisFrame: Int { get }
    public var waitTimeMs: Double { get }
    public var bodyCount: Int { get }
    public var activeBodyCount: Int { get }   // non-kinematic bodies
    
    /// Step the simulation (called by the engine via ActorCoordinator)
    public func update(deltaTime: Float)              // inline on the main actor
    public func updateAsync(deltaTime: Float) async   // on PhysicsActor, using these settings
    
    /// Manual registration (usually automatic via RigidBody component)
    public func register(_ rigidBody: RigidBody)
    public func unregister(_ rigidBody: RigidBody)
    
    /// Clear all registered bodies and the accumulator
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

The callback fires once per colliding pair per frame (triggers included), after results are applied. `info.normal` points from `colliderA` toward `colliderB`, and `info.other` is `colliderB`.

## Best Practices

1. **Always add a RigidBody** for dynamic objects that should be affected by physics
2. **Leave the RigidBody off static objects** like floors and walls - a collider alone is static. Use `isKinematic = true` only for bodies you move from code (e.g. moving platforms)
3. **Match collider size to visual mesh** for accurate collisions
4. **Use `PlaneCollider`** for infinite surfaces (more efficient than large boxes)
5. **Keep mass realistic** - extreme mass ratios can cause instability
6. **Use PhysicsMaterial presets** for common surface types

## Documentation

- [RigidBody](rigidbody.md) - Dynamic physics bodies
- [Colliders](colliders.md) - Collision shapes
- [Physics Materials](materials.md) - Surface properties
