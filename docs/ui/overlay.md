# UIOverlay Component

The `UIOverlay` component integrates the UI framework with the GameObject system, allowing you to attach UI elements to GameObjects and render them as overlays on top of your 3D scene.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         3D Scene Rendering                               │
│    ┌─────────┐                                                          │
│    │ Player  │    ┌───────┐                                             │
│    └─────────┘    │ Enemy │        ┌───────────┐                        │
│                   └───────┘        │  Terrain  │                        │
│                                    └───────────┘                        │
├─────────────────────────────────────────────────────────────────────────┤
│                         UI Overlay Layer                                 │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Health: ████████░░ 80%              Score: 1500      Level: 3    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│                                              ┌────────────────────────┐ │
│                                              │     Mini Map           │ │
│                                              │      ┌─┐               │ │
│                                              │      └─┘               │ │
│                                              └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## Basic Usage

### Creating a HUD

```swift
class GameScene: GameObjectScene {
    private var scoreText: Text?
    private var score = 0
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Create HUD GameObject
        let hud = createGameObject(name: "HUD")
        let overlay = hud.addComponent(UIOverlay.self)
        
        // Create score text reference for updates
        let scoreLabel = Text("Score: 0")
            .foregroundColor(.white)
        self.scoreText = scoreLabel
        
        overlay.setContent {
            HStack {
                scoreLabel
                Spacer()
                Text("Level 1")
                    .foregroundColor(.yellow)
            }
            .padding(20)
        }
    }
    
    func addScore(_ points: Int) {
        score += points
        scoreText?.content = "Score: \(score)"
    }
    
    // No render override needed: the default render(context:) draws the
    // 3D scene from Camera.main and then calls renderUIOverlays(context:).
    
    override func update(context: FrameContext, input: Input) {
        // Handle UI input first (FrameContext has no screen size;
        // use engine.windowSize)
        let screen = engine!.windowSize
        let uiHandled = handleUIOverlayInput(
            input,
            screenWidth: Float(screen.width),
            screenHeight: Float(screen.height)
        )
        
        // Only handle game input if UI didn't consume it
        // (true only when the mouse is over an overlay with blocksInput)
        if !uiHandled {
            // Game input handling
        }
        
        super.update(context: context, input: input)
    }
}
```

## Anchoring and Positioning

### Screen Anchors

Position overlays at specific screen locations. There is no default anchor: with `anchor == nil` (and no `size`) the overlay covers the full screen. With an anchor but no `size`, the overlay fits its content's ideal size plus `padding` and is placed by the anchor.

```swift
// Top-left corner
overlay.anchor(.topLeft)

// Center of screen
overlay.anchor(.center)

// Bottom-right corner
overlay.anchor(.bottomRight)

// Custom position (50% from left, 25% from top)
overlay.anchor(UIOverlay.Anchor(x: 0.5, y: 0.25))
```

### Available Anchors

| Anchor | Position |
|--------|----------|
| `.topLeft` | Top-left corner |
| `.topCenter` | Top center |
| `.topRight` | Top-right corner |
| `.centerLeft` | Middle left |
| `.center` | Screen center |
| `.centerRight` | Middle right |
| `.bottomLeft` | Bottom-left corner |
| `.bottomCenter` | Bottom center |
| `.bottomRight` | Bottom-right corner |

### Fixed Size Overlays

Create fixed-size UI panels. A fixed `size` is placed by the anchor (at the top-left if there is no anchor):

```swift
let minimap = createGameObject(name: "Minimap")
let overlay = minimap.addComponent(UIOverlay.self)

overlay
    .anchor(.bottomRight)
    .size(200, 200)
    .padding(10)
    .backgroundColor(Color(r: 0, g: 0, b: 0, a: 180))

overlay.setContent {
    // Minimap content
}
```

## Depth and Layering

### Render Order

Control which overlays appear on top:

```swift
// HUD renders first (behind)
hudOverlay.depth = 0

// Pause menu renders on top
pauseMenuOverlay.depth = 100

// Dialog box renders on top of everything
dialogOverlay.depth = 200
```

### Input Blocking

Prevent input from reaching lower overlays:

```swift
// Pause menu blocks input to HUD
pauseMenuOverlay.blocksInput = true
```

Input is routed to an overlay only while the mouse is within its bounds (the area it was last rendered in). `handleUIOverlayInput` returns `true` only when an overlay under the mouse has `blocksInput` set (overlays below it then get nothing); an overlay without `blocksInput` passes the input on to the overlays below it.

## Multiple Overlays Example

```swift
class GameScene: GameObjectScene {
    private var hudOverlay: UIOverlay!
    private var minimapOverlay: UIOverlay!
    private var pauseMenuOverlay: UIOverlay!
    
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // HUD - always visible, lowest depth
        let hud = createGameObject(name: "HUD")
        hudOverlay = hud.addComponent(UIOverlay.self)
        hudOverlay.depth = 0
        hudOverlay.setContent {
            VStack {
                // Health bar, score, etc.
            }
        }
        
        // Minimap - bottom right corner
        let minimap = createGameObject(name: "Minimap")
        minimapOverlay = minimap.addComponent(UIOverlay.self)
        minimapOverlay
            .depth(10)
            .anchor(.bottomRight)
            .size(150, 150)
            .padding(10)
        minimapOverlay.setContent {
            // Minimap content
        }
        
        // Pause menu - centered, hidden by default
        let pauseMenu = createGameObject(name: "PauseMenu")
        pauseMenuOverlay = pauseMenu.addComponent(UIOverlay.self)
        pauseMenuOverlay
            .depth(100)
            .anchor(.center)
            .size(400, 300)
            .blocksInput(true)
            .backgroundColor(Color(r: 0, g: 0, b: 0, a: 200))
        pauseMenuOverlay.isVisible = false
        pauseMenuOverlay.setContent {
            VStack(spacing: 20) {
                Text("PAUSED")
                    .foregroundColor(.white)
                    .fontSize(2)
                Button("Resume") {
                    self.resumeGame()
                }
                Button("Quit") {
                    self.quitGame()
                }
            }
            .padding(30)
        }
    }
    
    func togglePause() {
        pauseMenuOverlay.isVisible.toggle()
    }
}
```

## Dynamic Content Updates

### Updating Text

```swift
class HUD {
    private var healthText: Text?
    private var health: Int = 100
    
    func setup(overlay: UIOverlay) {
        let label = Text("Health: 100")
        self.healthText = label
        
        overlay.setContent {
            label
        }
    }
    
    func updateHealth(_ newHealth: Int) {
        health = newHealth
        healthText?.content = "Health: \(health)"
    }
}
```

### Rebuilding Content

For major structural changes, rebuild the entire overlay:

```swift
func showVictoryScreen() {
    overlay.setContent {
        VStack(spacing: 20) {
            Text("VICTORY!")
                .foregroundColor(.yellow)
                .fontSize(3)
            Text("Final Score: \(score)")
            Button("Play Again") {
                self.restartGame()
            }
        }
    }
}
```

### Deferred Rebuilds

Mark content for rebuild on next frame:

```swift
overlay.setNeedsRebuild()  // Will rebuild in next update()
```

## UIOverlayManager

The `UIOverlayManager` singleton manages all overlays:

```swift
// Get all active overlays
let overlays = UIOverlayManager.shared.allOverlays

// Clear all overlays (useful when changing scenes)
UIOverlayManager.shared.clear()

// Notify depth changed (if you modify depth directly)
UIOverlayManager.shared.notifyDepthChanged()
```

## Integration with Scenes

### GameObjectScene Extensions

The framework adds convenience methods to `GameObjectScene`:

```swift
// Render all UI overlays. The default render(context:) already calls this
// after drawing the 3D scene; only call it yourself if you override render
// without calling super.render.
renderUIOverlays(context: context)

// Handle input for overlays (call at start of update)
let handled = handleUIOverlayInput(input, screenWidth: w, screenHeight: h)
```

### Complete Scene Template

```swift
class MyGameScene: GameObjectScene {
    override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        setupUI()
        setupGame()
    }
    
    private func setupUI() {
        let hud = createGameObject(name: "HUD")
        let overlay = hud.addComponent(UIOverlay.self)
        overlay.setContent {
            // UI content
        }
    }
    
    override func update(context: FrameContext, input: Input) {
        // 1. Handle UI input
        let screen = engine!.windowSize
        let uiHandled = handleUIOverlayInput(
            input,
            screenWidth: Float(screen.width),
            screenHeight: Float(screen.height)
        )
        
        // 2. Handle game input if UI didn't consume it
        if !uiHandled {
            handleGameInput(input)
        }
        
        // 3. Update game logic
        super.update(context: context, input: input)
    }
    
    override func render(context: RenderContext) {
        // Clears the screen, renders the 3D scene from Camera.main,
        // then renders the UI overlays on top. Don't call
        // renderUIOverlays(context:) again after this.
        super.render(context: context)
    }
}
```

## Properties Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `depth` | `Int` | `0` | Render order (higher = on top) |
| `blocksInput` | `Bool` | `false` | Block input to lower overlays |
| `isVisible` | `Bool` | `true` | Whether overlay is rendered |
| `anchor` | `Anchor?` | `nil` | Screen position (nil = full screen) |
| `size` | `Size?` | `nil` | Fixed size (nil = full screen without an anchor, fit content plus padding with one) |
| `padding` | `EdgeInsets` | `0` | Content padding |
| `backgroundColor` | `Color?` | `nil` | Background color |
