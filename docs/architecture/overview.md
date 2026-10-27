# Architecture Overview

Understanding the high-level architecture of GameEngine.

## System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                            Engine                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                        Main Loop                              │  │
│  │   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────────┐  │  │
│  │   │ Input   │──▶│ Update  │──▶│ Render  │──▶│ Present     │  │  │
│  │   │ Poll    │   │ Scene   │   │ Scene   │   │ Backbuffer  │  │  │
│  │   └─────────┘   └─────────┘   └─────────┘   └─────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                         Scene                                 │  │
│  │   ┌─────────────────────────────────────────────────────┐    │  │
│  │   │                   GameObjects                        │    │  │
│  │   │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │    │  │
│  │   │  │ Transform │  │ Transform │  │ Transform │       │    │  │
│  │   │  ├───────────┤  ├───────────┤  ├───────────┤       │    │  │
│  │   │  │ Camera    │  │MeshRender │  │ Light     │       │    │  │
│  │   │  │ Player    │  │ Rotator   │  │           │       │    │  │
│  │   │  │ Controller│  │           │  │           │       │    │  │
│  │   │  └───────────┘  └───────────┘  └───────────┘       │    │  │
│  │   └─────────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

## Core Systems

### Engine

The `Engine` class is the heart of the framework:

```swift
public final class Engine {
    // Configuration
    let config: EngineConfig
    
    // Core systems
    let input: Input           // Keyboard/mouse state
    let renderer: Renderer     // Drawing primitives
    
    // Scene management
    var currentScene: Scene?
    
    // Methods
    func loadScene(_ scene: Scene)
    func run()                 // Starts main loop
}
```

### Scene

Scenes contain your game world:

```
┌─────────────────────────────────────────────────────────┐
│                      Scene                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │                 GameObjectScene                    │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │              Root GameObjects               │  │  │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐    │  │  │
│  │  │  │ Player  │  │  Cube   │  │  Light  │    │  │  │
│  │  │  │  └─Cam  │  │  └─Mesh │  │  └─Dir  │    │  │  │
│  │  │  │  └─Ctrl │  │  └─Rot  │  │  └─Amb  │    │  │  │
│  │  │  └─────────┘  └─────────┘  └─────────┘    │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Component System

Components follow a simple lifecycle:

```
                    ┌──────────┐
                    │  init()  │
                    └────┬─────┘
                         │
                         ▼
                    ┌──────────┐
                    │  awake() │  Called immediately when added
                    └────┬─────┘
                         │
                         ▼
                    ┌──────────┐
                    │onEnable()│  Called when enabled
                    └────┬─────┘
                         │
                         ▼
                    ┌──────────┐
                    │  start() │  Called before first update
                    └────┬─────┘
                         │
            ┌────────────┴────────────┐
            │      Game Loop          │
            │  ┌──────────────────┐   │
            │  │ fixedUpdate()    │   │  Physics (fixed timestep)
            │  └────────┬─────────┘   │
            │           │             │
            │  ┌────────▼─────────┐   │
            │  │ update()         │   │  Game logic (every frame)
            │  └────────┬─────────┘   │
            │           │             │
            │  ┌────────▼─────────┐   │
            │  │ lateUpdate()     │   │  Post-update (camera follow)
            │  └──────────────────┘   │
            └────────────┬────────────┘
                         │
                         ▼
                   ┌───────────┐
                   │onDisable()│  When disabled
                   └─────┬─────┘
                         │
                         ▼
                   ┌───────────┐
                   │onDestroy()│  When removed/destroyed
                   └───────────┘
```

## Rendering Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RenderPipeline                                │
│                                                                      │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐               │
│  │   Collect   │   │  Transform  │   │   Cull      │               │
│  │   Meshes    │──▶│  Vertices   │──▶│  Triangles  │               │
│  └─────────────┘   └─────────────┘   └─────────────┘               │
│         │                                    │                       │
│         │         MeshRenderer[]             │                       │
│         │                                    ▼                       │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐               │
│  │   Present   │◀──│  Rasterize  │◀──│   Light     │               │
│  │   Buffer    │   │  Triangles  │   │   & Shade   │               │
│  └─────────────┘   └─────────────┘   └─────────────┘               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Pipeline Stages

1. **Collect Meshes** - Gather all `MeshRenderer` components
2. **Frustum Cull** - Skip objects outside camera view
3. **Transform Vertices** - Model → World → View → Clip space
4. **Clip & Cull** - Clip triangles against the near/far planes, backface culling
5. **Lighting** - Flat (per face) or Gouraud (per vertex) shading from the scene lights
6. **Rasterize** - Scanline fill with a per-pixel depth buffer (`TriangleRasterizer`)
7. **Present** - Display backbuffer in window

## Coordinate System

GameEngine uses a **right-handed** coordinate system:

```
        Y (up)
        │
        │
        │
        └───────── X (right)
       /
      /
     Z (toward the viewer, out of screen)
```

Cameras and `Transform.forward` look down **-Z** (into the screen).

### Space Transformations

```
Local Space ──[Model Matrix]──▶ World Space ──[View Matrix]──▶ View Space
                                                                    │
                                                             [Projection]
                                                                    │
Screen Space ◀──[Viewport]── NDC Space ◀──[Perspective Divide]─────┘
```

| Space | Description |
|-------|-------------|
| **Local** | Object's own coordinate system |
| **World** | Global scene coordinates |
| **View** | Camera-relative coordinates |
| **Clip** | After projection, before divide |
| **NDC** | Normalized Device Coordinates (-1 to 1) |
| **Screen** | Pixel coordinates |

## Memory Model

```
┌─────────────────────────────────────────────┐
│                   Scene                      │
│  owns                                        │
│  ┌────────────────────────────────────────┐ │
│  │            GameObjects[]               │ │
│  │  owns                                  │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │         Components[]              │ │ │
│  │  │  weak ref                         │ │ │
│  │  │  ┌────────────────────────────┐  │ │ │
│  │  │  │    gameObject: GameObject? │  │ │ │
│  │  │  └────────────────────────────┘  │ │ │
│  │  └──────────────────────────────────┘ │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

- Scenes own GameObjects
- GameObjects own Components
- Components have weak reference to their GameObject
- Transform is a special component (always present)

## Threading Model

GameEngine uses Swift's actor model for concurrency:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Threading Architecture                              │
│                                                                              │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                    MainActor (Game Loop)                           │     │
│   │  • Window/Input handling    • Rendering     • Scene updates       │     │
│   │  • Component lifecycle      • UI updates    • Physics coordination│     │
│   └─────────────────────────────────┬─────────────────────────────────┘     │
│                                     │                                        │
│                              async/await                                     │
│                      ┌──────────────┼──────────────┐                        │
│                      ▼              ▼              ▼                        │
│   ┌────────────────────┐  ┌────────────────┐  ┌────────────────┐           │
│   │   PhysicsActor     │  │AssetLoadingActor│ │ GameLogicActor │           │
│   │ • Collision detect │  │ • Mesh loading  │  │ • AI compute   │           │
│   │ • Rigid body sim   │  │ • Texture load  │  │ • Pathfinding  │           │
│   │ • Fixed timestep   │  │ • Async I/O     │  │ • Heavy calc   │           │
│   └────────────────────┘  └────────────────┘  └────────────────┘           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Main Actor

Most game code runs on the **main actor** (`@MainActor`):

```swift
@MainActor
public final class Engine { ... }

@MainActor
public final class MyScene: GameObjectScene { ... }

@MainActor
public class Component { ... }
```

Game logic, rendering, and input processing happens on the main thread. This simplifies the programming model and avoids synchronization issues.

### Background Actors

CPU-intensive operations run on dedicated actors to keep the main thread responsive:

- **PhysicsActor** - Collision detection, rigid body simulation (60Hz fixed timestep)
- **AssetLoadingActor** - Mesh and texture loading without blocking
- **GameLogicActor** - Heavy AI calculations, pathfinding

See [Actor System](actors.md) for detailed documentation.
