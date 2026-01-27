# MeshRenderer Component

The MeshRenderer component displays 3D geometry in your scene.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MeshRenderer                                     │
│                                                                          │
│  ┌────────────────────┐         ┌────────────────────┐                 │
│  │       Mesh         │         │      Material      │                 │
│  │  ┌──────────────┐  │         │  ┌──────────────┐  │                 │
│  │  │   Vertices   │  │    +    │  │    Color     │  │                 │
│  │  │   Indices    │  │         │  │   Shading    │  │                 │
│  │  │   Bounds     │  │         │  │   Culling    │  │                 │
│  │  └──────────────┘  │         │  └──────────────┘  │                 │
│  └────────────────────┘         └────────────────────┘                 │
│                                                                          │
│  isVisible: Bool                                                        │
│  worldBounds: Bounds? (computed)                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Basic Usage

```swift
let cube = createGameObject(name: "Cube", at: Vec3d(0, 0, 0))

// Add MeshRenderer component
let renderer = cube.addComponent(MeshRenderer.self)

// Set mesh geometry
renderer.mesh = CubeMesh.shared

// Set material appearance
renderer.material = Material.solid(.cornflowerBlue)
renderer.material.shadingModel = .flat
```

## Properties

### Mesh

The 3D geometry to render:

```swift
// Built-in primitives
renderer.mesh = CubeMesh.shared
renderer.mesh = PlaneMesh(width: 10, depth: 10)
renderer.mesh = QuadMesh(width: 2, height: 3)

// Custom mesh
renderer.mesh = MyCustomMesh()
```

### Material

The visual appearance:

```swift
// Using factory methods
renderer.material = Material.solid(.red)
renderer.material = Material.matte(Color(gray: 128))
renderer.material = Material.metallic(.gold, roughness: 0.3)

// Configure existing material
renderer.material.color = .blue
renderer.material.shadingModel = .flat
renderer.material.cullMode = .none
```

### Convenience Color Property

Quick access to material color:

```swift
// These are equivalent:
renderer.color = .green
renderer.material.color = .green

// Read color
let currentColor = renderer.color
```

### Visibility

```swift
// Hide without removing
renderer.isVisible = false

// Show again
renderer.isVisible = true

// Check if enabled (from Component base class)
if renderer.isEnabled && renderer.isVisible {
    // Will be rendered
}
```

### World Bounds

Get the axis-aligned bounding box in world space:

```swift
if let bounds = renderer.worldBounds {
    print("Min: \(bounds.min)")
    print("Max: \(bounds.max)")
    print("Center: \(bounds.center)")
    print("Size: \(bounds.size)")
}
```

## Setting Up Objects

### Static Object

```swift
let wall = createGameObject(name: "Wall", at: Vec3d(0, 0, -5))
let renderer = wall.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.material = Material.matte(Color(r: 128, g: 100, b: 80))

// Scale to wall shape
wall.transform.localScale = Vec3d(5, 3, 0.2)
```

### Animated Object

```swift
let cube = createGameObject(name: "SpinningCube")
let renderer = cube.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.material = Material.solid(.cyan)

// Add rotation
let rotator = cube.addComponent(Rotator.self)
rotator.axis = Vec3d(1, 1, 0).normalized
rotator.speed = 2.0
```

### Multiple Materials (Sub-meshes)

```swift
// For objects with multiple sub-meshes
renderer.materials = [
    Material.solid(.red),    // Sub-mesh 0
    Material.solid(.green),  // Sub-mesh 1
    Material.solid(.blue)    // Sub-mesh 2
]
```

## Common Patterns

### Dynamic Color Change

```swift
public final class ColorPulse: Component {
    public override func update(deltaTime: Float) {
        guard let renderer = gameObject?.getComponent(MeshRenderer.self) else { return }
        
        // Pulse between two colors
        let t = (sin(Float(totalTime) * 2) + 1) / 2
        renderer.color = Color.lerp(from: .red, to: .blue, t: t)
    }
}
```

### Visibility Toggle

```swift
public final class Flasher: Component {
    var timer: Float = 0
    var interval: Float = 0.5
    
    public override func update(deltaTime: Float) {
        timer += deltaTime
        if timer >= interval {
            timer = 0
            if let renderer = gameObject?.getComponent(MeshRenderer.self) {
                renderer.isVisible.toggle()
            }
        }
    }
}
```

### Distance-Based LOD (Level of Detail)

```swift
public final class SimpleLOD: Component {
    var highDetailMesh: Mesh?
    var lowDetailMesh: Mesh?
    var lodDistance: Float = 20.0
    
    public override func update(deltaTime: Float) {
        guard let renderer = gameObject?.getComponent(MeshRenderer.self),
              let camera = Camera.main else { return }
        
        let distance = (transform.worldPosition - camera.transform.worldPosition).length
        
        if distance > lodDistance {
            renderer.mesh = lowDetailMesh
        } else {
            renderer.mesh = highDetailMesh
        }
    }
}
```

## Rendering Process

When you call `RenderPipeline.shared.render()`:

```
1. Collect all MeshRenderers
   └─▶ Filter: isVisible && isEnabled

2. For each MeshRenderer:
   ├─▶ Frustum cull using worldBounds
   ├─▶ Get mesh vertices and indices
   ├─▶ Transform vertices using transform.worldMatrix
   ├─▶ Apply material settings
   └─▶ Add triangles to render queue

3. Sort triangles by depth

4. Rasterize triangles with material colors
```

## Performance Considerations

### Mesh Sharing

```swift
// ✅ Good: Share meshes between renderers
let sharedCube = CubeMesh.shared
renderer1.mesh = sharedCube
renderer2.mesh = sharedCube

// ❌ Avoid: Creating new meshes for identical geometry
renderer1.mesh = CubeMesh()  // New instance
renderer2.mesh = CubeMesh()  // Another new instance
```

### Visibility Culling

```swift
// Hide objects that don't need rendering
if objectIsBehindWall {
    renderer.isVisible = false
}
```

### Bounds Accuracy

Accurate bounds improve frustum culling:

```swift
// Mesh should have tight bounds
let bounds = Bounds(
    min: Vec3d(-1, -1, -1),
    max: Vec3d(1, 1, 1)
)
// Not overly large bounds that waste rendering
```

## Complete Example

```swift
@MainActor
public final class RenderExample: GameObjectScene {
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Lighting
        let light = createGameObject(name: "Light")
        let sun = light.addComponent(DirectionalLight.self)
        sun.direction = Vec3d(0.5, 1, 0.3)
        light.addComponent(AmbientLight.self).intensity = 0.2
        
        // Camera
        let camera = createGameObject(name: "Camera", at: Vec3d(0, 3, 8))
        camera.addComponent(Camera.self)
        
        // Ground
        let ground = createGameObject(name: "Ground")
        let groundRenderer = ground.addComponent(MeshRenderer.self)
        groundRenderer.mesh = PlaneMesh(width: 20, depth: 20)
        groundRenderer.material = Material.matte(Color(r: 50, g: 80, b: 50))
        
        // Multiple cubes
        for i in 0..<5 {
            let cube = createGameObject(name: "Cube\(i)")
            cube.transform.localPosition = Vec3d(Float(i - 2) * 2, 0.5, 0)
            
            let renderer = cube.addComponent(MeshRenderer.self)
            renderer.mesh = CubeMesh.shared
            renderer.material = Material.solid(randomColor())
            renderer.material.shadingModel = .flat
            
            // Add rotation
            let rotator = cube.addComponent(Rotator.self)
            rotator.speed = Float(i + 1) * 0.5
        }
    }
    
    private func randomColor() -> Color {
        Color(
            r: UInt8.random(in: 100...255),
            g: UInt8.random(in: 100...255),
            b: UInt8.random(in: 100...255)
        )
    }
    
    public override func render(context: RenderContext) {
        context.renderer.clear(Camera.main?.backgroundColor ?? .black)
        guard let camera = Camera.main else { return }
        
        let renderers = findComponentsOfType(MeshRenderer.self)
        RenderPipeline.shared.render(
            meshRenderers: renderers,
            camera: camera,
            context: context
        )
    }
}
```
