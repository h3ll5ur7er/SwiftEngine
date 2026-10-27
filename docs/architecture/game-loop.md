# Game Loop

Understanding the frame-by-frame execution of GameEngine.

## Loop Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           MAIN LOOP                                  │
│                                                                      │
│    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐   │
│    │  Input   │───▶│  Update  │───▶│  Render  │───▶│ Present  │   │
│    │  Poll    │    │  Scene   │    │  Scene   │    │ Buffer   │   │
│    └──────────┘    └──────────┘    └──────────┘    └──────────┘   │
│         │               │               │               │          │
│         │               │               │               │          │
│         ▼               ▼               ▼               ▼          │
│    Read keys      Update all      Draw to         Blit to         │
│    and mouse      components      backbuffer      window          │
│                                                                      │
│    ◀─────────────────── One Frame ───────────────────▶             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Engine Frame Steps

`Engine.run()` performs these steps every frame, all on the main actor:

1. **Poll input** - process window events into `Input` (press/release transitions are kept for the frame)
2. **Update scene** - `scene.update(context:input:)`; a `GameObjectScene` starts new objects, runs `fixedUpdate`, `update`, `lateUpdate`, then destroys pending objects
3. **Physics and actors** - `ActorCoordinator.shared.update` steps physics through `PhysicsSystem` (inline by default, on `PhysicsActor` when `asyncPhysicsEnabled`), then runs any `GameLogicActor` handlers and applies their transform updates
4. **Render** - `scene.render(context:)`
5. **Present** - copy the backbuffer to the window
6. **Yield** - `await Task.yield()` lets other main-actor work run (`Task {}` bodies, async asset loads)
7. **Frame limiting** - sleep to honor `targetFps`

## Frame Timeline

```
Time ──────────────────────────────────────────────────────────────────▶

Frame N                              Frame N+1
├──────────────────────────────────┤├──────────────────────────────────┤
│                                  ││                                  │
│  ┌─────┐ ┌──────┐ ┌──────┐ ┌──┐││  ┌─────┐ ┌──────┐ ┌──────┐ ┌──┐│
│  │Input│ │Update│ │Render│ │P ││  │Input│ │Update│ │Render│ │P ││
│  └─────┘ └──────┘ └──────┘ └──┘││  └─────┘ └──────┘ └──────┘ └──┘│
│                                  ││                                  │
├────────────── deltaTime ─────────┤                                  │
│                                  │
└──────────────────────────────────┘
        ~16.6ms at 60 FPS
```

## Delta Time

`deltaTime` is the time elapsed since the last frame, measured in seconds:

```swift
public override func update(context: FrameContext, input: Input) {
    let dt = Float(context.deltaTime)
    
    // Move 5 units per SECOND, regardless of framerate
    position.x += 5.0 * dt
}
```

### Why Use Delta Time?

```
Without deltaTime (bad):              With deltaTime (good):
┌────────────────────────┐           ┌────────────────────────┐
│ 60 FPS: moves 60/sec   │           │ 60 FPS: moves 5/sec    │
│ 30 FPS: moves 30/sec   │  ───▶     │ 30 FPS: moves 5/sec    │
│ 120 FPS: moves 120/sec │           │ 120 FPS: moves 5/sec   │
└────────────────────────┘           └────────────────────────┘
  Speed depends on FPS!                Speed is consistent!
```

## Update Order

Within each frame, updates happen in a specific order:

```
┌─────────────────────────────────────────────────────────────────────┐
│                          UPDATE PHASE                                │
│                                                                      │
│   1. Pending GameObjects                                            │
│      └─▶ internalStart() called on new objects                      │
│                                                                      │
│   2. Fixed Update Loop                                              │
│      └─▶ fixedUpdate() at fixed 60Hz (physics rate)                 │
│          └─▶ accumulator += deltaTime                               │
│          └─▶ while accumulator >= fixedDeltaTime:                   │
│                  call fixedUpdate() on all components               │
│                                                                      │
│   3. Regular Update                                                 │
│      └─▶ update(deltaTime:) on all enabled components               │
│                                                                      │
│   4. Late Update                                                    │
│      └─▶ lateUpdate(deltaTime:) on all enabled components           │
│                                                                      │
│   5. Pending Destroy                                                │
│      └─▶ Actually destroy marked GameObjects                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Fixed Update vs Update

| Method | Timing | Use Case |
|--------|--------|----------|
| `fixedUpdate()` | Fixed interval (default: 60Hz, `fixedDeltaTime`) | Physics, deterministic logic |
| `update()` | Every frame (variable) | Game logic, input handling |
| `lateUpdate()` | After all updates | Camera follow, cleanup |

```swift
public override func fixedUpdate(fixedDeltaTime: Float) {
    // Fixed step - always 1/60 second by default
    velocity += gravity * fixedDeltaTime
    position += velocity * fixedDeltaTime
}

public override func update(deltaTime: Float) {
    // Smooth visuals, input
    if input.isKeyPressed(.space) {
        jump()
    }
}

public override func lateUpdate(deltaTime: Float) {
    // Camera follows player AFTER player has moved
    cameraPosition = playerPosition + offset
}
```

## Frame Context

The `FrameContext` provides timing information:

```swift
public struct FrameContext {
    /// Time since last frame (seconds)
    public let deltaTime: Double
    
    /// Total time since engine started (seconds)
    public let totalTime: Double
    
    /// Current frame number
    public let frameCount: UInt64
    
    /// Frames per second (updated once per second)
    public let fps: Double
}
```

### Usage Example

```swift
public override func update(context: FrameContext, input: Input) {
    // Oscillate based on total time
    let wave = sin(Float(context.totalTime) * 2.0)
    transform.localPosition.y = wave
    
    // Log every 100 frames
    if context.frameCount % 100 == 0 {
        print("Frame \(context.frameCount)")
    }
    
    super.update(context: context, input: input)
}
```

## Render Context

The `RenderContext` provides rendering information:

```swift
public struct RenderContext {
    /// The renderer for drawing primitives
    public let renderer: Renderer
    
    /// Screen width in pixels
    public var width: Int32 { get }
    
    /// Screen height in pixels
    public var height: Int32 { get }
    
    /// Screen bounds
    public var bounds: Rect { get }
}
```

## FPS and Performance

### Target FPS

```swift
let config = EngineConfig(
    title: "My Game",
    width: 800,
    height: 600,
    targetFps: 60,          // Cap at 60 FPS (nil = uncapped)
    showFpsInTitle: true    // "My Game - 60 FPS"
)
```

### Performance Monitoring

```swift
public override func update(context: FrameContext, input: Input) {
    // deltaTime spike detection
    if context.deltaTime > 0.1 {  // > 100ms = lag spike
        print("⚠️ Lag spike: \(context.deltaTime * 1000)ms")
    }
    
    super.update(context: context, input: input)
}
```

## Complete Frame Example

```swift
@MainActor
public final class MyScene: GameObjectScene {
    
    public override func update(context: FrameContext, input: Input) {
        // 1. Handle input
        if input.isKeyPressed(.escape) {
            // Quit game
        }
        
        // 2. Update game state
        super.update(context: context, input: input)  // Updates all components
    }
    
    public override func render(context: RenderContext) {
        // 3. Clear screen
        context.renderer.clear(.black)
        
        // 4. Render 3D scene
        guard let camera = Camera.main else { return }
        let meshRenderers = findComponentsOfType(MeshRenderer.self)
        RenderPipeline.shared.render(
            meshRenderers: meshRenderers,
            camera: camera,
            context: context
        )
        
        // 5. Render UI overlays (UIOverlay components) on top
        UIOverlayManager.shared.renderOverlays(context: context)
    }
}
```
