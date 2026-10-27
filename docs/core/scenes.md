# Scenes

Scenes contain your game world and manage GameObjects.

## Scene Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Scene (Protocol)                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  onLoad(engine:)                                               │  │
│  │  onUnload(engine:)                                             │  │
│  │  onActivate(engine:)                                           │  │
│  │  onDeactivate(engine:)                                         │  │
│  │  update(context:input:)                                        │  │
│  │  render(context:)                                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              ▲                                       │
│                              │ implements                            │
│  ┌───────────────────────────┴───────────────────────────────────┐  │
│  │                     GameObjectScene                            │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │  + createGameObject(name:)                              │  │  │
│  │  │  + createGameObject(name:at:)                           │  │  │
│  │  │  + addGameObject(_:)                                    │  │  │
│  │  │  + destroy(_:)                                          │  │  │
│  │  │  + find(name:) / findAll(name:)                         │  │  │
│  │  │  + findWithTag(_:) / findFirstWithTag(_:)               │  │  │
│  │  │  + findObjectsOfType(_:)                                │  │  │
│  │  │  + findComponentsOfType(_:)                             │  │  │
│  │  │  + render(context:)  (default rendering)                │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Creating a Scene

### Basic Scene (Protocol)

For simple scenes without GameObjects:

```swift
import GameEngine

@MainActor
public final class SplashScreen: Scene {
    private var timer: Float = 0
    
    public init() {}
    
    public func onLoad(engine: Engine) {
        // Load resources
    }
    
    public func onUnload(engine: Engine) {
        // Cleanup
    }
    
    public func onActivate(engine: Engine) {
        timer = 0
    }
    
    public func onDeactivate(engine: Engine) { }
    
    public func update(context: FrameContext, input: Input) {
        timer += Float(context.deltaTime)
        if timer > 3.0 {
            // Transition to game scene
        }
    }
    
    public func render(context: RenderContext) {
        context.renderer.clear(.black)
        // Draw splash image
    }
}
```

### GameObjectScene (Recommended)

For scenes with GameObjects and components:

```swift
import GameEngine

@MainActor
public final class GameLevel: GameObjectScene {
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)  // Important!
        
        // Create your game world
        setupLighting()
        setupPlayer()
        setupLevel()
    }
    
    private func setupLighting() {
        let light = createGameObject(name: "Light")
        let sun = light.addComponent(DirectionalLight.self)
        sun.direction = Vec3d(0.5, 1, 0.3)
        
        let ambient = light.addComponent(AmbientLight.self)
        ambient.intensity = 0.2
    }
    
    private func setupPlayer() {
        let player = createGameObject(name: "Player", at: Vec3d(0, 0, 5))
        player.addComponent(Camera.self)
        player.addComponent(PlayerController.self)
    }
    
    private func setupLevel() {
        // Create floor
        let floor = createGameObject(name: "Floor")
        let renderer = floor.addComponent(MeshRenderer.self)
        renderer.mesh = PlaneMesh(width: 20, depth: 20)
        renderer.material = Material.matte(.gray)
    }
    
    public override func update(context: FrameContext, input: Input) {
        // Handle input before component updates
        if let controller = findComponentsOfType(PlayerController.self).first {
            controller.setInput(input)
        }
        
        super.update(context: context, input: input)  // Updates all components
    }
    
    // No render(context:) override needed - see "Default Rendering" below
}
```

### Default Rendering

`GameObjectScene` provides a default `render(context:)`. Each frame it:

1. Sets `Camera.main`'s `aspectRatio` from the window size
2. Clears the screen to the camera's `backgroundColor`
3. Renders all `MeshRenderer`s from `Camera.main`
4. Calls `renderUIOverlays(context:)`

A scene that only builds objects in `onLoad(engine:)` (calling `super.onLoad(engine: engine)`) draws without overriding `render`. If you override `render`, you take over all of these steps yourself (or call `super.render(context: context)` and draw on top).

## Scene Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: Scene()
    Created --> Loaded: engine.loadScene()
    
    state Loaded {
        [*] --> onLoad
        onLoad --> onActivate
        onActivate --> Active
        
        state Active {
            [*] --> Update
            Update --> Render
            Render --> Update
        }
    }
    
    Active --> onDeactivate: scene change / unload
    onDeactivate --> onUnload
    onUnload --> [*]
```

### Lifecycle Methods

| Method | When Called | Use For |
|--------|-------------|---------|
| `onLoad()` | Scene is loaded | Create GameObjects, load assets |
| `onActivate()` | Scene becomes active | Start music, reset state |
| `update()` | Every frame | Game logic |
| `render()` | Every frame | Drawing |
| `onDeactivate()` | Another scene loaded | Pause, save state |
| `onUnload()` | Scene is unloaded | Cleanup |

## Loading Scenes

```swift
// In your entry point
let engine = Engine(config: config)
engine.loadScene(MainMenuScene())
await engine.run()  // inside `static func main() async`

// Switch scenes at runtime (e.g., from a component)
// Note: You need a reference to the engine
public final class LevelComplete: Component {
    weak var engine: Engine?
    
    func goToNextLevel() {
        engine?.loadScene(Level2Scene())
    }
}
```

## Scene Querying

### Finding GameObjects

```swift
// Find by name (first match)
let player = find(name: "Player")

// Find all with name
let enemies = findAll(name: "Enemy")

// Find by tag
let collectibles = findWithTag("collectible")
let boss = findFirstWithTag("boss")

// Remove a GameObject (deferred until the end of the frame)
if let player { destroy(player) }
```

### Finding Components

```swift
// Find a single component (first match)
let camera = findComponentsOfType(Camera.self).first

// Find all components
let allRenderers = findComponentsOfType(MeshRenderer.self)
let allLights = findComponentsOfType(DirectionalLight.self)

// Find all GameObjects that have a component
let renderedObjects = findObjectsOfType(MeshRenderer.self)
```

## GameObjectScene Properties

```swift
// Access all root GameObjects
let roots = rootGameObjects

// Access all GameObjects (including children)
let all = allGameObjects

// Reference to engine
let engine = self.engine

// Fixed timestep for Component.fixedUpdate (default 1/60)
fixedDeltaTime = 1.0 / 50.0  // call fixedUpdate at 50Hz

// The physics simulation uses its own timestep:
// PhysicsSystem.shared.settings.fixedDeltaTime
```

## Scene Patterns

### Scene with Multiple Cameras

```swift
public override func render(context: RenderContext) {
    let allRenderers = findComponentsOfType(MeshRenderer.self)
    
    // Main view (full screen)
    if let mainCamera = Camera.main {
        context.renderer.clear(mainCamera.backgroundColor)
        RenderPipeline.shared.render(
            meshRenderers: allRenderers,
            camera: mainCamera,
            context: context
        )
    }
    
    // Minimap camera (corner)
    if let minimapCam = find(name: "MinimapCamera")?
        .getComponent(Camera.self) {
        // Render to a viewport region
        // (Would need viewport support in renderer)
    }
}
```

### Scene with Pause State

```swift
@MainActor
public final class GameLevel: GameObjectScene {
    private var isPaused = false
    
    public override func update(context: FrameContext, input: Input) {
        // Toggle pause (Escape is reserved: the engine stops on it)
        if input.isKeyPressed(.p) {
            isPaused.toggle()
        }
        
        // Skip component updates when paused
        if !isPaused {
            super.update(context: context, input: input)
        }
    }
    
    public override func render(context: RenderContext) {
        // Always render scene (default rendering)
        super.render(context: context)
        
        // Overlay pause menu
        if isPaused {
            renderPauseMenu(context: context)
        }
    }
}
```

### Scene with Loading Screen

```swift
@MainActor
public final class LoadingScene: Scene {
    private var nextScene: Scene
    private var isLoaded = false
    
    public init(nextScene: Scene) {
        self.nextScene = nextScene
    }
    
    public func update(context: FrameContext, input: Input) {
        if !isLoaded {
            // In a real engine, this would be async
            loadAssets()
            isLoaded = true
        } else {
            // Transition to next scene
            // (Would need engine reference)
        }
    }
    
    public func render(context: RenderContext) {
        context.renderer.clear(.black)
        // Draw loading bar
    }
    
    private func loadAssets() {
        // Load textures, meshes, etc.
    }
}
```

## Best Practices

1. **Call super methods** - Always call `super.onLoad()`, `super.update()` in GameObjectScene
2. **Create GameObjects in onLoad** - Not in init
3. **Use onActivate for resets** - Scene may be reused
4. **Query once, cache results** - Don't search every frame
5. **Keep scenes focused** - One scene = one game state
