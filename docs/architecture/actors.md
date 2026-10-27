# Actor System

GameEngine uses Swift Actors to isolate physics, asset loading and game logic state from the main actor. The engine awaits each actor's results within the frame, so actor work happens before rendering, not in parallel with it.

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
│   │  • Collision detection     │   │  • Mesh loading (OBJ, STL) │          │
│   │  • Rigid body simulation   │   │  • Mesh cache              │          │
│   │  • Fixed timestep          │   │  • Async file I/O          │          │
│   │  • Opt-in (inline default) │   │  • Batch loading           │          │
│   └────────────────────────────┘   └────────────────────────────┘          │
│                                                                              │
│   ┌────────────────────────────┐   ┌────────────────────────────┐          │
│   │    GameLogicActor          │   │    ActorCoordinator        │          │
│   │                            │   │                            │          │
│   │  • Per-component handlers  │   │  • Orchestrates updates    │          │
│   │  • Custom per-frame tasks  │   │  • Data flow management    │          │
│   │  • Batch AI decisions      │   │  • Sync point              │          │
│   └────────────────────────────┘   └────────────────────────────┘          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Why Actors?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Inline vs Actor Physics (one frame)                      │
│                                                                             │
│   INLINE (default)                     ACTOR (asyncPhysicsEnabled = true)   │
│   ────────────────                     ──────────────────────────────────   │
│                                                                             │
│   MainActor:                           MainActor:                           │
│   ┌────────────────────────────┐       ┌──────────────┐     ┌────────────┐  │
│   │ Input│Update│Physics│Render│       │ Input│Update │ ... │   Render   │  │
│   └────────────────────────────┘       └──────┬───────┘     └─────▲──────┘  │
│                                               │ await             │         │
│                                        PhysicsActor: ┌───────┐    │         │
│                                                      │Physics├────┘         │
│                                                      └───────┘              │
│                                                                             │
│   Same simulation code                 Simulation state isolated on the     │
│   (PhysicsSimulation)                  actor; rendering still waits for it  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## PhysicsActor

Runs the shared `PhysicsSimulation` (the same fixed-timestep code `PhysicsSystem` runs inline) on a dedicated actor. It is opt-in: by default the engine steps physics inline on the main actor.

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Physics Actor Data Flow                                 │
│                                                                              │
│   MainActor                              PhysicsActor                        │
│   ─────────                              ────────────                        │
│                                                                              │
│   1. Create snapshot                                                        │
│      PhysicsFrameInput  ──────────────▶  2. Simulate (fixed steps)         │
│      • bodies [GameUUID:                    • Integrate velocities         │
│        PhysicsBodyState]                    • Integrate positions          │
│      • colliders [ColliderSnapshot]         • Detect collisions            │
│      • deltaTime                            • Resolve collisions           │
│      (gravity etc. come from the                                           │
│       actor's PhysicsSettings)                                             │
│                                                                              │
│   4. Apply results      ◀──────────────  3. Return results                 │
│      • Update transforms                    PhysicsStepResult              │
│      • Update velocities                    • updatedBodies                │
│      • Report collisions                    • collisions                   │
│        (CollisionManager.onCollision)       • simulatedTime                │
│                                             • stepsExecuted                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Usage

Physics simulation happens automatically when you use `RigidBody` components: the engine steps it each frame through `ActorCoordinator.shared.update`. By default that runs inline on the main actor; set `asyncPhysicsEnabled` to run it on `PhysicsActor` instead. `PhysicsSystem.shared.settings` (and `gravity`) apply in both modes, because `PhysicsSystem.updateAsync` pushes them to the actor before simulating.

```swift
// Just add physics components - the engine steps them every frame
let ball = createGameObject(name: "Ball")
ball.addComponent(SphereCollider(radius: 0.5))
ball.addComponent(RigidBody(mass: 1.0))

// Physics runs inline on the main actor by default.
// Opt in to running it on PhysicsActor:
ActorCoordinator.shared.asyncPhysicsEnabled = true
```

### Fixed Timestep

```swift
// The simulation steps at a fixed 60Hz (PhysicsSettings.fixedDeltaTime) regardless of frame rate
// This ensures deterministic, stable physics

Frame deltaTime: 16.67ms  →  1 physics step
Frame deltaTime: 33.33ms  →  2 physics steps
Frame deltaTime: 50.00ms  →  2 physics steps  (frame time is clamped to maxDeltaTime = 1/30 s)

// Leftover time carries over in an accumulator; maxDeltaTime and
// maxStepsPerFrame (4) keep slow frames from spiralling
```

---

## AssetLoadingActor

Loads mesh data (OBJ and binary STL files) off the main actor and caches it by path. It does not load textures and has no progress reporting.

### Usage

```swift
// Load mesh data asynchronously (non-throwing; returns AssetLoadResult<MeshData>)
let result = await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")
switch result {
case .success(let meshData):
    print("Loaded \(meshData.triangleCount) triangles")
case .failure(let error):
    print("Failed: \(error)")
}

// Load multiple meshes in one call
let results = await AssetLoadingActor.shared.loadMeshes(from: [
    "models/a.obj", "models/b.obj", "models/c.obj"
])  // [String: AssetLoadResult<MeshData>]
```

`MeshData` is plain Sendable data, not a `Mesh`. To get something a `MeshRenderer` can draw, use `LoadableMesh`, which loads through this actor.

### In Scene Setup

```swift
@MainActor
public final class MyScene: GameObjectScene {
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // LoadableMesh is a Mesh; it renders nothing until loading finishes
        let characterMesh = LoadableMesh(path: "character.obj")
        
        // Create game object with the mesh
        let character = createGameObject(name: "Character")
        let renderer = character.addComponent(MeshRenderer.self)
        renderer.mesh = characterMesh
        
        // Load on AssetLoadingActor (or `await characterMesh.loadAsync()` from an async context)
        characterMesh.load()
    }
}
```

---

## GameLogicActor

Runs registered game logic handlers and tasks off the main actor. `ActorCoordinator` calls it each frame (after physics) when `asyncGameLogicEnabled` is true (the default) and at least one handler or task is registered.

### Use Cases

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    GameLogicActor Use Cases                                  │
│                                                                              │
│   • Per-component updates      Handlers keyed by component type name;       │
│     (registerHandler)          they get a GameObjectSnapshot and return     │
│                                a TransformUpdate applied on the MainActor   │
│   • Per-frame tasks            Arbitrary work run once per frame            │
│     (registerTask)                                                          │
│   • Batch AI decisions         processAIDecisions (placeholder logic:       │
│     (processAIDecisions)       currently returns .idle for every entity)    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Usage

```swift
// Per-component handler, keyed by the component's type name.
// Runs for every active GameObject with an enabled "Spinner" component;
// the returned TransformUpdate is applied back on the MainActor.
await GameLogicActor.shared.registerHandler(for: "Spinner") { snapshot, deltaTime in
    let spin = Quaternion.fromAxisAngle(axis: .up, angle: deltaTime)
    return TransformUpdate(rotation: spin * snapshot.rotation)
}

// Custom task run once per frame
await GameLogicActor.shared.registerTask(name: "economy") { deltaTime in
    // Work that doesn't touch MainActor state
}

// Batch AI decisions (placeholder: every decision is currently .idle)
let decisions = await GameLogicActor.shared.processAIDecisions(
    entities: aiStates,          // [AIEntityState]
    worldState: worldSnapshot    // WorldStateSnapshot
)
```

---

## ActorCoordinator

Orchestrates updates across multiple actors, ensuring proper data flow and synchronization.

### Frame Update Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ActorCoordinator Frame Flow                             │
│                                                                              │
│   1. Engine calls ActorCoordinator.update() after the scene update          │
│                     │                                                       │
│   2. Step physics   ├─ inline (default): PhysicsSystem.update()             │
│                     │                                                       │
│                     ├─ asyncPhysicsEnabled: PhysicsSystem.updateAsync()     │
│                     │      snapshot ──▶ ┌────────────────┐                  │
│                     │                   │ PhysicsActor   │                  │
│                     │                   │ simulate()     │                  │
│                     │      results ◀────┴────────────────┘                  │
│                     │                                                       │
│   3. Apply physics  │  transforms, velocities, onCollision                  │
│      results        │                                                       │
│                     │                                                       │
│   4. Game logic     ├─ if asyncGameLogicEnabled and handlers/tasks exist:   │
│      pass           │      snapshots ──▶ ┌────────────────────┐             │
│                     │                    │ GameLogicActor     │             │
│                     │                    │ processGameObjects │             │
│                     │      updates ◀─────┴────────────────────┘             │
│                     │                                                       │
│   5. Apply transform│                                                       │
│      updates        ▼                                                       │
│   6. Return to engine for rendering                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Thread Safety

### Sendable Types

Data passed between actors must be `Sendable`:

```swift
// PhysicsFrameInput is Sendable - safe to pass between actors
public struct PhysicsFrameInput: Sendable {
    public let bodies: [GameUUID: PhysicsBodyState]
    public let colliders: [ColliderSnapshot]
    public let deltaTime: Float
}

// PhysicsBodyState is also Sendable (a value-type snapshot)
public struct PhysicsBodyState: Sendable {
    public let id: GameUUID
    public var position: Vec3d
    public var velocity: Vec3d
    public var rotation: Quaternion
    // ... mass, isKinematic, accumulated force/torque, limits
}
```

### Actor Isolation

```swift
// PhysicsActor - isolated, only accessible via async calls
public actor PhysicsActor {
    // All mutable state (including the accumulator) is isolated to this actor
    private var simulation = PhysicsSimulation()
    
    // Called from MainActor - requires await
    public func simulate(input: PhysicsFrameInput) async -> PhysicsStepResult {
        // Safe - running on PhysicsActor
    }
}

// MainActor - game loop side
@MainActor
public final class PhysicsSystem {
    public func updateAsync(deltaTime: Float) async {
        // Must await to call PhysicsActor
        await PhysicsActor.shared.configure(settings)
        let result = await PhysicsActor.shared.simulate(input: input)
        // ... apply result to GameObjects
    }
}
```

---

## Best Practices

1. **Keep MainActor light** - Move heavy computation to dedicated actors
2. **Use snapshots** - Pass immutable copies between actors, not references
3. **Batch operations** - Send one large request instead of many small ones
4. **Await strategically** - Don't await in tight loops
5. **Handle failures** - The engine's actor calls don't throw; asset loads report failures as `AssetLoadResult.failure`, so check the result

```swift
// Good - one input containing every body and collider
let input = PhysicsFrameInput(
    bodies: bodies,          // [GameUUID: PhysicsBodyState]
    colliders: colliders,    // [ColliderSnapshot]
    deltaTime: dt
)
let result = await PhysicsActor.shared.simulate(input: input)

// Bad - one call per body (actor hop overhead, bodies never see each other,
// and every call advances the accumulator)
for (id, body) in bodies {
    _ = await PhysicsActor.shared.simulate(  // Don't do this!
        input: PhysicsFrameInput(bodies: [id: body], colliders: colliders, deltaTime: dt)
    )
}
```
