# Example: Basic 3D Scene

A complete walkthrough of creating a 3D scene with lighting, camera, and objects.

## The Complete Scene

```swift
import GameEngine

@MainActor
public final class BasicScene: GameObjectScene {
    
    private var playerController: PlayerController?
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        setupLighting()
        setupPlayer()
        setupEnvironment()
    }
    
    private func setupLighting() {
        // Ambient light for base illumination
        let ambient = createGameObject(name: "AmbientLight")
        let ambientLight = ambient.addComponent(AmbientLight.self)
        ambientLight.color = Color(r: 64, g: 64, b: 80)
        ambientLight.intensity = 0.3
        
        // Main directional light (sun)
        let sun = createGameObject(name: "Sun")
        let sunLight = sun.addComponent(DirectionalLight.self)
        sunLight.color = Color(r: 255, g: 250, b: 240)
        sunLight.intensity = 0.8
        // Direction points toward the light: 60° above the horizon, 45° around Y.
        // (Rotating the light's transform has no effect; only `direction` is used.)
        sunLight.direction = Vec3d(0.35, 0.87, 0.35)
    }
    
    private func setupPlayer() {
        // Player with camera and controls
        let player = createGameObject(name: "Player", at: Vec3d(0, 2, 8))
        player.addComponent(Camera.self)
        
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
        playerController?.lookSpeed = 0.002  // radians per pixel (used with enableMouseLook)
    }
    
    private func setupEnvironment() {
        // Ground plane
        let ground = createGameObject(name: "Ground", at: Vec3d(0, 0, 0))
        let groundRenderer = ground.addComponent(MeshRenderer.self)
        groundRenderer.mesh = PlaneMesh.shared
        groundRenderer.material = Material.solid(Color(r: 80, g: 120, b: 80))
        ground.transform.localScale = Vec3d(10, 1, 10)
        
        // Colored cubes arranged in a circle
        let colors: [Color] = [.red, .green, .blue, .yellow, .cyan, .magenta]
        let radius: Float = 4.0
        
        for (index, color) in colors.enumerated() {
            let angle = Float(index) / Float(colors.count) * Float.pi * 2
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            let cube = createGameObject(
                name: "Cube_\(index)", 
                at: Vec3d(x, 1, z)
            )
            
            let renderer = cube.addComponent(MeshRenderer.self)
            renderer.mesh = CubeMesh.shared
            renderer.material = Material.solid(color)
            renderer.material.shadingModel = .flat
            
            // Add rotation
            let rotator = cube.addComponent(Rotator.self)
            rotator.axis = .up
            rotator.speed = 0.5 + Float(index) * 0.2
        }
        
        // Center pillar
        let pillar = createGameObject(name: "Pillar", at: Vec3d(0, 1.5, 0))
        let pillarRenderer = pillar.addComponent(MeshRenderer.self)
        pillarRenderer.mesh = CubeMesh.shared
        pillarRenderer.material = Material.solid(Color(r: 200, g: 200, b: 200))
        pillarRenderer.material.shadingModel = .flat
        pillar.transform.localScale = Vec3d(0.5, 3, 0.5)
    }
    
    public override func update(context: FrameContext, input: Input) {
        // Provide input to controller
        playerController?.setInput(input)
        
        // Call parent to update all GameObjects
        super.update(context: context, input: input)
    }
    
    // No render override: GameObjectScene's default render(context:) sets the
    // camera's aspect ratio, clears to its backgroundColor, draws all
    // MeshRenderers, then draws UI overlays.
}
```

## Scene Breakdown

### 1. Lighting Setup

```
                    ☀️ Sun (DirectionalLight)
                   ╲
                    ╲  60° above horizon, 45° around Y
                     ╲
                      ╲
    ═══════════════════●═══════════════════
                      ╱│╲
             ┌───────╱ │ ╲───────┐
             │      ╱  │  ╲      │
             │     ╱   │   ╲     │
    Ambient ─┼────●────●────●────┼─ Ambient
    Light    │         │         │  Light
    fills    │    Scene Objects  │  (uniform)
    shadows  │         │         │
             └─────────┴─────────┘
```

Two-light setup:
- **Ambient Light**: Low-intensity uniform illumination
- **Directional Light**: Main light source; set its `direction` (its transform's rotation is ignored)

### 2. Player Setup

```swift
let player = createGameObject(name: "Player", at: Vec3d(0, 2, 8))
```

```
    Top View:
    
           -Z (forward)
            ▲
            │
            │    ┌───┐
            │    │   │ Cubes in circle
         ┌──┼────●   │
         │  │    │   │
    -X ──┼──●────┼───┼── +X
         │  │    │   │
         │  │    ● Player (at Z=8)
         │  │    📷
         └──┼────────┘
            │
            ▼
           +Z
```

### 3. Object Arrangement

```swift
// Circle formula
let angle = Float(index) / Float(count) * Float.pi * 2
let x = cos(angle) * radius
let z = sin(angle) * radius
```

```
           Top View (Y looking down)
           
                    ● Red (0°)
                  ╱   ╲
                ╱       ╲
    Magenta ● ╱           ╲ ● Green (60°)
              ╲    ■      ╱
               ╲ Pillar  ╱
                ╲       ╱
                  ╲   ╱
       Cyan ●      ╳       ● Blue (120°)
                  ╱ ╲
                ╱     ╲
              ╱         ╲
    Yellow ●               ● (continues around)
```

### 4. Material & Shading

Each cube gets:
- Unique solid color
- Flat shading for hard edges
- Different rotation speeds

```swift
renderer.material = Material.solid(color)
renderer.material.shadingModel = .flat
```

---

## Variations

### Night Scene

```swift
private func setupNightLighting() {
    let ambient = createGameObject(name: "Ambient")
    let ambientLight = ambient.addComponent(AmbientLight.self)
    ambientLight.color = Color(r: 20, g: 20, b: 40)
    ambientLight.intensity = 0.2
    
    // Moonlight
    let moon = createGameObject(name: "Moon")
    let moonLight = moon.addComponent(DirectionalLight.self)
    moonLight.color = Color(r: 200, g: 200, b: 255)
    moonLight.intensity = 0.4
    moonLight.direction = Vec3d(0, 0.71, 0.71)  // 45° above the horizon
}
```

### Sunset Scene

```swift
private func setupSunsetLighting() {
    let ambient = createGameObject(name: "Ambient")
    let ambientLight = ambient.addComponent(AmbientLight.self)
    ambientLight.color = Color(r: 60, g: 40, b: 50)
    ambientLight.intensity = 0.3
    
    let sun = createGameObject(name: "Sun")
    let sunLight = sun.addComponent(DirectionalLight.self)
    sunLight.color = Color(r: 255, g: 160, b: 80)
    sunLight.intensity = 0.6
    sunLight.direction = Vec3d(0.97, 0.26, 0)  // Low on horizon (15°)
}
```

### Grid Layout

```swift
private func createGrid(rows: Int, cols: Int, spacing: Float) {
    let offsetX = Float(cols - 1) * spacing / 2
    let offsetZ = Float(rows - 1) * spacing / 2
    
    for row in 0..<rows {
        for col in 0..<cols {
            let x = Float(col) * spacing - offsetX
            let z = Float(row) * spacing - offsetZ
            
            let cube = createGameObject(
                name: "Cube_\(row)_\(col)",
                at: Vec3d(x, 0.5, z)
            )
            
            let renderer = cube.addComponent(MeshRenderer.self)
            renderer.mesh = CubeMesh.shared
            
            // Checkerboard colors
            let isEven = (row + col) % 2 == 0
            renderer.color = isEven ? .white : .black
        }
    }
}
```

---

## Common Patterns

### Parent-Child Hierarchies

```swift
// Solar system style
// (worldPositionStays: false keeps each `at:` position as the local offset)
let sun = createGameObject(name: "Sun", at: .zero)
sun.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .yellow))

let earthOrbit = createGameObject(name: "EarthOrbit")
earthOrbit.setParent(sun, worldPositionStays: false)
earthOrbit.addComponent(Rotator.self).speed = 0.5

let earth = createGameObject(name: "Earth", at: Vec3d(5, 0, 0))
earth.setParent(earthOrbit, worldPositionStays: false)
earth.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .blue))
earth.addComponent(Rotator.self).speed = 2.0

let moonOrbit = createGameObject(name: "MoonOrbit")
moonOrbit.setParent(earth, worldPositionStays: false)
moonOrbit.addComponent(Rotator.self).speed = 1.5

let moon = createGameObject(name: "Moon", at: Vec3d(1.5, 0, 0))
moon.setParent(moonOrbit, worldPositionStays: false)
moon.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .gray))
moon.transform.localScale = Vec3d(0.3, 0.3, 0.3)
```

### Dynamic Object Creation

```swift
@MainActor
public final class Spawner: Component {
    var spawnInterval: Float = 2.0
    var timer: Float = 0
    
    public override func update(deltaTime: Float) {
        timer += deltaTime
        if timer >= spawnInterval {
            timer = 0
            spawnObject()
        }
    }
    
    private func spawnObject() {
        guard let scene = gameObject?.scene else { return }
        
        let obj = scene.createGameObject(
            name: "Spawned_\(Date().timeIntervalSince1970)",
            at: transform.position
        )
        let renderer = obj.addComponent(MeshRenderer.self)
        renderer.mesh = CubeMesh.shared
        renderer.color = Color(
            r: UInt8.random(in: 100...255),
            g: UInt8.random(in: 100...255),
            b: UInt8.random(in: 100...255)
        )
    }
}
```

### Object Pooling

```swift
@MainActor
public final class ObjectPool: Component {
    private var pool: [GameObject] = []
    private var activeObjects: Set<ObjectIdentifier> = []
    var poolSize: Int = 20
    
    public override func start() {
        guard let scene = gameObject?.scene else { return }
        
        for i in 0..<poolSize {
            let obj = scene.createGameObject(name: "Pooled_\(i)")
            let renderer = obj.addComponent(MeshRenderer.self)
            renderer.mesh = CubeMesh.shared
            obj.isActive = false
            pool.append(obj)
        }
    }
    
    func acquire() -> GameObject? {
        for obj in pool {
            let id = ObjectIdentifier(obj)
            if !activeObjects.contains(id) {
                activeObjects.insert(id)
                obj.isActive = true
                return obj
            }
        }
        return nil
    }
    
    func release(_ obj: GameObject) {
        let id = ObjectIdentifier(obj)
        if activeObjects.contains(id) {
            activeObjects.remove(id)
            obj.isActive = false
        }
    }
}
```
