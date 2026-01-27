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
        ambientLight.color = Color(red: 64, green: 64, blue: 80)
        ambientLight.intensity = 0.3
        
        // Main directional light (sun)
        let sun = createGameObject(name: "Sun")
        let sunLight = sun.addComponent(DirectionalLight.self)
        sunLight.color = Color(red: 255, green: 250, blue: 240)
        sunLight.intensity = 0.8
        sun.transform.localRotation = Quaternion.fromEuler(
            pitch: -Float.pi / 3,  // 60° down
            yaw: Float.pi / 4,     // 45° angle
            roll: 0
        )
    }
    
    private func setupPlayer() {
        // Player with camera and controls
        let player = createGameObject(name: "Player", at: Vec3d(0, 2, 8))
        player.addComponent(Camera.self)
        
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
        playerController?.lookSpeed = 2.0
    }
    
    private func setupEnvironment() {
        // Ground plane
        let ground = createGameObject(name: "Ground", at: Vec3d(0, 0, 0))
        let groundRenderer = ground.addComponent(MeshRenderer.self)
        groundRenderer.mesh = PlaneMesh.shared
        groundRenderer.material = Material.solid(Color(red: 80, green: 120, blue: 80))
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
            renderer.material?.shadingModel = .flat
            
            // Add rotation
            let rotator = cube.addComponent(Rotator.self)
            rotator.axis = .up
            rotator.speed = 0.5 + Float(index) * 0.2
        }
        
        // Center pillar
        let pillar = createGameObject(name: "Pillar", at: Vec3d(0, 1.5, 0))
        let pillarRenderer = pillar.addComponent(MeshRenderer.self)
        pillarRenderer.mesh = CubeMesh.shared
        pillarRenderer.material = Material.solid(Color(red: 200, green: 200, blue: 200))
        pillarRenderer.material?.shadingModel = .flat
        pillar.transform.localScale = Vec3d(0.5, 3, 0.5)
    }
    
    public override func update(context: FrameContext, input: Input) {
        // Provide input to controller
        playerController?.setInput(input)
        
        // Call parent to update all GameObjects
        super.update(context: context, input: input)
    }
}
```

## Scene Breakdown

### 1. Lighting Setup

```
                    ☀️ Sun (DirectionalLight)
                   ╲
                    ╲  60° down, 45° rotation
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
- **Directional Light**: Main light source with direction

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
renderer.material?.shadingModel = .flat
```

---

## Variations

### Night Scene

```swift
private func setupNightLighting() {
    let ambient = createGameObject(name: "Ambient")
    let ambientLight = ambient.addComponent(AmbientLight.self)
    ambientLight.color = Color(red: 20, green: 20, blue: 40)
    ambientLight.intensity = 0.2
    
    // Moonlight
    let moon = createGameObject(name: "Moon")
    let moonLight = moon.addComponent(DirectionalLight.self)
    moonLight.color = Color(red: 200, green: 200, blue: 255)
    moonLight.intensity = 0.4
    moon.transform.localRotation = Quaternion.fromEuler(
        pitch: -Float.pi / 4,
        yaw: 0,
        roll: 0
    )
}
```

### Sunset Scene

```swift
private func setupSunsetLighting() {
    let ambient = createGameObject(name: "Ambient")
    let ambientLight = ambient.addComponent(AmbientLight.self)
    ambientLight.color = Color(red: 60, green: 40, blue: 50)
    ambientLight.intensity = 0.3
    
    let sun = createGameObject(name: "Sun")
    let sunLight = sun.addComponent(DirectionalLight.self)
    sunLight.color = Color(red: 255, green: 160, blue: 80)
    sunLight.intensity = 0.6
    sun.transform.localRotation = Quaternion.fromEuler(
        pitch: -Float.pi / 12,  // Low on horizon (15°)
        yaw: Float.pi / 2,
        roll: 0
    )
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
let sun = createGameObject(name: "Sun", at: .zero)
sun.addComponent(MeshRenderer.self).color = .yellow

let earthOrbit = createGameObject(name: "EarthOrbit")
earthOrbit.transform.parent = sun.transform
earthOrbit.addComponent(Rotator.self).speed = 0.5

let earth = createGameObject(name: "Earth", at: Vec3d(5, 0, 0))
earth.transform.parent = earthOrbit.transform
earth.addComponent(MeshRenderer.self).color = .blue
earth.addComponent(Rotator.self).speed = 2.0

let moonOrbit = createGameObject(name: "MoonOrbit")
moonOrbit.transform.parent = earth.transform
moonOrbit.addComponent(Rotator.self).speed = 1.5

let moon = createGameObject(name: "Moon", at: Vec3d(1.5, 0, 0))
moon.transform.parent = moonOrbit.transform
moon.addComponent(MeshRenderer.self).color = .gray
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
            at: transform.worldPosition
        )
        let renderer = obj.addComponent(MeshRenderer.self)
        renderer.mesh = CubeMesh.shared
        renderer.color = Color(
            red: UInt8.random(in: 100...255),
            green: UInt8.random(in: 100...255),
            blue: UInt8.random(in: 100...255)
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
            obj.setActive(false)
            pool.append(obj)
        }
    }
    
    func acquire() -> GameObject? {
        for obj in pool {
            let id = ObjectIdentifier(obj)
            if !activeObjects.contains(id) {
                activeObjects.insert(id)
                obj.setActive(true)
                return obj
            }
        }
        return nil
    }
    
    func release(_ obj: GameObject) {
        let id = ObjectIdentifier(obj)
        if activeObjects.contains(id) {
            activeObjects.remove(id)
            obj.setActive(false)
        }
    }
}
```
