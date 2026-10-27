# Getting Started

This guide will walk you through setting up your first GameEngine project.

## Prerequisites

Before you begin, ensure you have:

- **Swift 6.2+** installed (the package uses `swift-tools-version: 6.2`)
- **Windows 10/11** with **Visual Studio 2022** Build Tools, or
- **Linux** with X11 (run `scripts/setup-linux.sh` to install the toolchain and dependencies)

## Project Structure

```
YourProject/
├── Package.swift
├── build.ps1                ← Windows build script
├── scripts/
│   └── setup-linux.sh       ← Linux setup script
├── Sources/
│   ├── GameEngine/          ← Engine library (don't modify)
│   └── Game/                ← Your game code
│       ├── App.swift        ← Entry point
│       └── Scenes/          ← Your scenes
└── Tests/
    └── GameEngineTests/
```

## Creating Your First Scene

### Step 1: Set Up the Entry Point

Create `Sources/Game/App.swift`:

```swift
import GameEngine

@main
@MainActor
struct MyGame {
    static func main() async {
        // Configure the engine
        let config = EngineConfig(
            title: "My First Game",
            width: 800,
            height: 600,
            targetFps: 60,           // Optional: cap framerate
            showFpsInTitle: true     // Show FPS in window title
        )
        
        // Create and run the engine
        let engine = Engine(config: config)
        engine.loadScene(HelloWorldScene())
        await engine.run()
    }
}
```

### Step 2: Create Your Scene

Create `Sources/Game/Scenes/HelloWorldScene.swift`:

```swift
import GameEngine

@MainActor
public final class HelloWorldScene: GameObjectScene {
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // ─────────────────────────────────────────────
        // 1. Set up lighting
        // ─────────────────────────────────────────────
        let lightObject = createGameObject(name: "Light")
        
        let sun = lightObject.addComponent(DirectionalLight.self)
        sun.direction = Vec3d(0.5, 1.0, 0.3)  // Points toward light
        sun.intensity = 1.0
        
        let ambient = lightObject.addComponent(AmbientLight.self)
        ambient.intensity = 0.2
        
        // ─────────────────────────────────────────────
        // 2. Create a camera
        // ─────────────────────────────────────────────
        let cameraObject = createGameObject(name: "Camera", at: Vec3d(0, 2, 5))
        let camera = cameraObject.addComponent(Camera.self)
        camera.projection = .perspective
        camera.fieldOfView = 60.0
        camera.backgroundColor = Color(r: 30, g: 30, b: 40)
        
        // Optional: Add player controls
        let controller = cameraObject.addComponent(PlayerController.self)
        controller.moveSpeed = 5.0
        
        // ─────────────────────────────────────────────
        // 3. Create a cube
        // ─────────────────────────────────────────────
        let cube = createGameObject(name: "Cube", at: Vec3d(0, 0, 0))
        
        let material = Material.solid(.cornflowerBlue)
        material.shadingModel = .flat
        
        let renderer = cube.addComponent(MeshRenderer.self)
        renderer.mesh = CubeMesh.shared
        renderer.material = material
        
        // Make it spin!
        let rotator = cube.addComponent(Rotator.self)
        rotator.axis = .up
        rotator.speed = 1.0
    }
    
    private var playerController: PlayerController?
    
    public override func update(context: FrameContext, input: Input) {
        // Find player controller on first update
        if playerController == nil {
            playerController = findComponentsOfType(PlayerController.self).first
        }
        playerController?.setInput(input)
        
        super.update(context: context, input: input)
    }
}
```

No `render(context:)` override is needed: `GameObjectScene`'s default `render` sets `Camera.main`'s aspect ratio from the window, clears to the camera's `backgroundColor`, renders all `MeshRenderer`s, then calls `renderUIOverlays(context:)`. If you override `render`, you take over all of that yourself.

### Step 3: Build and Run

**Windows:**

```powershell
# Build in release mode (faster)
.\build.ps1 build-release

# Run the game
.\build.ps1 run-release
```

**Linux (X11):**

```bash
# One-time setup: Swift toolchain, X11 headers and other dependencies
scripts/setup-linux.sh

# Build, test, and run in release mode
swift build
swift test
swift run -c release Game
```

## Controls

Default controls when using `PlayerController`:

| Key / Action | Description |
|--------------|-------------|
| `W` / `↑` | Move forward |
| `S` / `↓` | Move backward |
| `A` / `←` | Strafe left |
| `D` / `→` | Strafe right |
| `E` | Move up |
| `Q` | Move down |
| `ESC` | Exit the game (handled by the engine) |

`PlayerController` itself does not capture the mouse. The demo scenes in `Sources/Game/Scenes` capture it on left click and release it on right click in their own `update`, using `engine?.captureMouse()` / `engine?.releaseMouse()`.

### Mouse Capture

For FPS-style camera controls, the mouse can be captured to enable free look:

```swift
// Capture programmatically
engine.captureMouse()

// Release
engine.releaseMouse()

// Toggle
engine.toggleMouseCapture()

// Check state
if engine.isMouseCaptured { ... }
```

When captured, the cursor is hidden and locked to the window center. The `PlayerController` component will automatically use mouse movement for camera rotation when `enableMouseLook` is set to `true` and the mouse is captured.

## Scene Lifecycle

```mermaid
stateDiagram-v2
    [*] --> onLoad: engine.loadScene()
    onLoad --> onActivate
    onActivate --> GameLoop
    
    state GameLoop {
        [*] --> update
        update --> render
        render --> [*]
    }
    
    GameLoop --> onDeactivate: scene change
    onDeactivate --> onUnload
    onUnload --> [*]
```

## What's Next?

- [Architecture Overview](architecture/overview.md) - Understand how the engine works
- [GameObjects & Components](core/gameobject-component.md) - Entity-component system
- [Materials](graphics/materials.md) - Customize appearance
- [Creating Custom Components](examples/custom-components.md) - Extend the engine
