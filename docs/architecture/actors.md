# Actor System

GameEngine uses Swift Actors to run CPU-intensive operations off the main thread, keeping the game loop responsive.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Actor Architecture                                   │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │                        MainActor (Game Loop)                          │  │
│   │                                                                        │  │
│   │   • Window/Input handling        • Scene updates                      │  │
│   │   • Rendering                    • UI updates                         │  │
│   │   • Component lifecycle          • Physics coordination               │  │
│   └───────────────────────────────────┬──────────────────────────────────┘  │
│                                       │                                      │
│                                       │ async/await                         │
│                           ┌───────────┴───────────┐                         │
│                           ▼                       ▼                         │
│   ┌────────────────────────────┐   ┌────────────────────────────┐          │
│   │      PhysicsActor          │   │   AssetLoadingActor        │          │
│   │                            │   │                            │          │
│   │  • Collision detection     │   │  • Mesh loading            │          │
│   │  • Rigid body simulation   │   │  • Texture loading         │          │
│   │  • Fixed timestep          │   │  • Async file I/O          │          │
│   │  • 60Hz physics            │   │  • Progress tracking       │          │
│   └────────────────────────────┘   └────────────────────────────┘          │
│                                                                              │
│   ┌────────────────────────────┐   ┌────────────────────────────┐          │
│   │    GameLogicActor          │   │    ActorCoordinator        │          │
│   │                            │   │                            │          │
│   │  • AI calculations         │   │  • Orchestrates updates    │          │
│   │  • Pathfinding             │   │  • Data flow management    │          │
│   │  • Heavy computations      │   │  • Sync point              │          │
│   └────────────────────────────┘   └────────────────────────────┘          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Why Actors?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Single-Threaded vs Actor Model                            │
│                                                                              │
│   SINGLE-THREADED                      ACTOR MODEL                          │
│   ───────────────                      ───────────                          │
│                                                                              │
│   Frame 1:                             Frame 1:                             │
│   ┌────────────────────────────┐       ┌─────────────┐ ┌───────────┐       │
│   │ Input │Physics│ AI │Render │       │ Main Thread │ │  Physics  │       │
│   └────────────────────────────┘       │ Input+Render│ │  (async)  │       │
│                                        └─────────────┘ └───────────┘       │
│   Total: 16ms                          Total: 10ms (parallelized)          │
│                                                                              │
│   Heavy physics blocks rendering       Physics runs in parallel             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## PhysicsActor

Runs physics simulation on a dedicated actor with fixed timestep.

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Physics Actor Data Flow                                 │
│                                                                              │
│   MainActor                              PhysicsActor                        │
│   ─────────                              ────────────                        │
│                                                                              │
│   1. Create snapshot                                                        │
│      PhysicsFrameInput  ──────────────▶  2. Simulate                       │
│      • bodySnapshots[]                      • Integrate velocities         │
│      • deltaTime                            • Integrate positions          │
│      • gravity                              • Detect collisions            │
│                                             • Resolve collisions           │
│                                                                              │
│   4. Apply results      ◀──────────────  3. Return results                 │
│      • Update transforms                    PhysicsStepResult              │
│      • Update velocities                    • positions[]                  │
│                                             • velocities[]                 │
│                                             • collisionCount               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Usage

Physics simulation happens automatically when you use `RigidBody` components. The engine handles actor coordination internally.

```swift
// Just add physics components - actors are managed automatically
let ball = createGameObject(name: "Ball")
ball.addComponent(SphereCollider(radius: 0.5))
ball.addComponent(RigidBody(mass: 1.0))

// Physics runs on PhysicsActor automatically
```

### Fixed Timestep

```swift
// PhysicsActor simulates at fixed 60Hz regardless of frame rate
// This ensures deterministic, stable physics

Frame deltaTime: 16.67ms  →  1 physics step
Frame deltaTime: 33.33ms  →  2 physics steps
Frame deltaTime: 50.00ms  →  3 physics steps

// Accumulator pattern prevents physics from falling behind
```

---

## AssetLoadingActor

Loads assets (meshes, textures) asynchronously without blocking the main thread.

### Usage

```swift
// Load mesh asynchronously
let mesh = await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")

// Load with progress callback
let mesh = await AssetLoadingActor.shared.loadMesh(from: "models/large.obj") { progress in
    print("Loading: \(Int(progress * 100))%")
}

// Load multiple assets concurrently
async let mesh1 = AssetLoadingActor.shared.loadMesh(from: "models/a.obj")
async let mesh2 = AssetLoadingActor.shared.loadMesh(from: "models/b.obj")
async let mesh3 = AssetLoadingActor.shared.loadMesh(from: "models/c.obj")

let (m1, m2, m3) = await (mesh1, mesh2, mesh3)
```

### In Scene Setup

```swift
@MainActor
public final class MyScene: GameObjectScene {
    public override func setup() async {
        // Load assets while showing loading screen
        let characterMesh = await AssetLoadingActor.shared.loadMesh(from: "character.obj")
        
        // Create game object with loaded mesh
        let character = createGameObject(name: "Character")
        let renderer = character.addComponent(MeshRenderer.self)
        renderer.mesh = characterMesh
    }
}
```

---

## GameLogicActor

Runs expensive game logic computations off the main thread.

### Use Cases

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    GameLogicActor Use Cases                                  │
│                                                                              │
│   • AI decision making         Heavy computation that would block           │
│   • Pathfinding                the main thread if done synchronously        │
│   • Procedural generation                                                   │
│   • Large-scale simulations                                                 │
│   • Complex math operations                                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Usage

```swift
// Offload expensive computation
let result = await GameLogicActor.shared.performComputation {
    // This runs on the GameLogicActor
    return expensiveCalculation()
}

// AI pathfinding example
let path = await GameLogicActor.shared.findPath(from: start, to: end, grid: navGrid)
```

---

## ActorCoordinator

Orchestrates updates across multiple actors, ensuring proper data flow and synchronization.

### Frame Update Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ActorCoordinator Frame Flow                             │
│                                                                              │
│   1. Engine calls ActorCoordinator.update()                                 │
│                     │                                                        │
│   2. Create physics ├──────────────────────────────┐                        │
│      input snapshot │                              │                        │
│                     │                              ▼                        │
│   3. Send to actors │                    ┌────────────────┐                 │
│                     │                    │ PhysicsActor   │                 │
│                     │                    │ simulate()     │                 │
│                     │                    └───────┬────────┘                 │
│                     │                            │                          │
│   4. Await results  │◀───────────────────────────┘                          │
│                     │                                                        │
│   5. Apply results  │                                                        │
│      to GameObjects │                                                        │
│                     ▼                                                        │
│   6. Return to engine for rendering                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Thread Safety

### Sendable Types

Data passed between actors must be `Sendable`:

```swift
// PhysicsFrameInput is Sendable - safe to pass between actors
public struct PhysicsFrameInput: Sendable {
    public let bodySnapshots: [BodySnapshot]
    public let deltaTime: Float
    public let gravity: Vec3d
}

// BodySnapshot is also Sendable
public struct BodySnapshot: Sendable {
    public let id: Int
    public let position: Vec3d
    public let velocity: Vec3d
    // ... immutable snapshot data
}
```

### Actor Isolation

```swift
// PhysicsActor - isolated, only accessible via async calls
actor PhysicsActor {
    // All mutable state is isolated to this actor
    private var accumulator: Float = 0
    
    // Called from MainActor - requires await
    func simulate(input: PhysicsFrameInput) async -> PhysicsStepResult {
        // Safe - running on PhysicsActor
    }
}

// MainActor - UI and game loop
@MainActor
class Engine {
    func update() async {
        // Must await to call PhysicsActor
        let result = await physicsActor.simulate(input: physicsInput)
    }
}
```

---

## Best Practices

1. **Keep MainActor light** - Move heavy computation to dedicated actors
2. **Use snapshots** - Pass immutable copies between actors, not references
3. **Batch operations** - Send one large request instead of many small ones
4. **Await strategically** - Don't await in tight loops
5. **Handle errors** - Actor calls can throw, handle failures gracefully

```swift
// Good - batch physics input
let input = PhysicsFrameInput(
    bodySnapshots: allBodies.map { $0.snapshot },
    deltaTime: dt,
    gravity: gravity
)
let result = await physicsActor.simulate(input: input)

// Bad - individual calls per body (too much overhead)
for body in allBodies {
    await physicsActor.updateBody(body)  // Don't do this!
}
```
