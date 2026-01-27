# Materials

Materials define the visual appearance of surfaces in your scene.

## Material Properties

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Material                                       │
│                                                                          │
│  Visual Properties                  Rendering Properties                 │
│  ──────────────────                 ────────────────────                 │
│  color: Color                       renderMode: RenderMode               │
│  mainTexture: Texture?              cullMode: CullMode                   │
│  opacity: Float                     shadingModel: ShadingModel           │
│                                                                          │
│  Lighting Properties (PBR)          Other                                │
│  ─────────────────────              ─────                                │
│  roughness: Float                   cutoffThreshold: Float               │
│  metallic: Float                                                         │
│  emissionColor: Color                                                    │
│  emissionIntensity: Float                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Creating Materials

### Factory Methods

```swift
// Solid color (opaque)
let red = Material.solid(.red)

// Matte surface (roughness = 1)
let concrete = Material.matte(Color(gray: 128))

// Metallic surface
let gold = Material.metallic(Color(r: 255, g: 215, b: 0), roughness: 0.3)

// Transparent
let glass = Material.transparent(.white, opacity: 0.3)

// Emissive (glowing)
let neon = Material.emissive(.cyan, intensity: 2.0)
```

### Manual Creation

```swift
let material = Material()

// Set color
material.color = Color(r: 100, g: 150, b: 200)

// Set shading
material.shadingModel = .flat

// Set culling
material.cullMode = .back  // Don't render back faces

// Set render mode
material.renderMode = .opaque
```

## Shading Models

```swift
public enum ShadingModel {
    case unlit    // No lighting calculations
    case flat     // One color per face
    case gouraud  // Smooth vertex interpolation (future)
    case pbr      // Physically-based rendering (future)
}
```

### Unlit

```
No lighting - perfect for UI, debug, or stylized graphics

    ┌──────────┐
    │ ████████ │  Same color regardless
    │ ████████ │  of light direction
    │ ████████ │
    └──────────┘
```

```swift
let material = Material.solid(.red)
material.shadingModel = .unlit
```

### Flat Shading

```
One color per face - classic low-poly look

           Light ↘
    ┌──────────────┐
    │ ████████████ │  Bright (facing light)
    │ ████████████ │
    │──────────────│
    │ ▓▓▓▓▓▓▓▓▓▓▓▓ │  Medium (angled)
    │ ▓▓▓▓▓▓▓▓▓▓▓▓ │
    │──────────────│
    │ ░░░░░░░░░░░░ │  Dark (away from light)
    │ ░░░░░░░░░░░░ │
    └──────────────┘
```

```swift
let material = Material.solid(.blue)
material.shadingModel = .flat  // Responds to DirectionalLight
```

## Cull Modes

```swift
public enum CullMode {
    case back   // Don't render back faces (default, most efficient)
    case front  // Don't render front faces (rare)
    case none   // Render both sides (for 2D planes, leaves, etc.)
}
```

### Visualization

```
CullMode.back (default):        CullMode.none:
─────────────────────           ─────────────────

Front visible, back hidden      Both sides visible

      ┌─────┐                        ┌─────┐
     /│     │                       /│     │
    / │ vis │                      / │ vis │
   /  │ible │                     /  │ible │
  ────┤     │                    ────┤     │
      │     │                        │ vis │
      └─────┘                        │ible │
                                     └─────┘
```

```swift
// Two-sided material (grass, leaves)
let leafMaterial = Material.solid(.green)
leafMaterial.cullMode = .none
```

## Render Modes

```swift
public enum RenderMode {
    case opaque      // Solid, no transparency
    case transparent // Alpha blending
    case cutout      // Binary transparency (alpha test)
    case wireframe   // Lines only (debug)
}
```

### Opaque

Standard solid rendering, most efficient:

```swift
let wall = Material.solid(Color(gray: 128))
wall.renderMode = .opaque
```

### Transparent

Alpha blending for glass, water, etc.:

```swift
let glass = Material.transparent(.white, opacity: 0.3)
glass.renderMode = .transparent
// Note: Transparent objects need special sorting
```

### Cutout

Binary transparency - pixels are either fully visible or invisible:

```swift
let foliage = Material()
foliage.renderMode = .cutout
foliage.cutoffThreshold = 0.5  // Alpha < 0.5 = invisible
```

### Wireframe

Debug rendering showing mesh edges:

```swift
let debug = Material()
debug.renderMode = .wireframe
debug.color = .green
```

## Material and Lighting

Materials interact with the lighting system:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LIGHTING CALCULATION                                  │
│                                                                          │
│   Final Color = (Ambient + Directional) × Base Color                    │
│                                                                          │
│   Ambient:                                                               │
│   ────────                                                               │
│   color × ambientIntensity × ambientColor                               │
│                                                                          │
│   Directional (per light):                                              │
│   ────────────────────────                                              │
│   color × max(0, normal·lightDir) × lightIntensity × lightColor         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

```swift
// Scene setup
let light = createGameObject(name: "Light")

let sun = light.addComponent(DirectionalLight.self)
sun.direction = Vec3d(1, 1, 0.5)
sun.intensity = 1.0
sun.color = .white

let ambient = light.addComponent(AmbientLight.self)
ambient.intensity = 0.2  // 20% base illumination
ambient.color = Color(r: 200, g: 200, b: 255)  // Slight blue tint
```

## Common Material Setups

### Ground/Floor

```swift
let ground = Material.matte(Color(r: 80, g: 60, b: 40))  // Brown
ground.shadingModel = .flat
```

### Metal Object

```swift
let metal = Material.metallic(Color(gray: 200), roughness: 0.2)
metal.shadingModel = .flat
```

### Glowing Object

```swift
let glow = Material.emissive(.cyan, intensity: 2.0)
glow.shadingModel = .unlit  // Emissive ignores external lighting
```

### Glass/Window

```swift
let glass = Material.transparent(Color(r: 200, g: 220, b: 255), opacity: 0.3)
glass.cullMode = .none  // See through from both sides
```

### Debug/Wireframe

```swift
let debug = Material()
debug.renderMode = .wireframe
debug.color = .green
debug.cullMode = .none
```

## Using Materials with MeshRenderer

```swift
let cube = createGameObject(name: "Cube")

// Create material
let material = Material.solid(.cornflowerBlue)
material.shadingModel = .flat

// Assign to renderer
let renderer = cube.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.material = material

// Change color at runtime
renderer.material.color = .red

// Or use convenience property
renderer.color = .green  // Same as renderer.material.color = .green
```

## Best Practices

1. **Reuse materials** when possible - multiple renderers can share one material
2. **Use `.unlit`** for UI elements and skyboxes
3. **Use `.flat`** for most 3D objects with current renderer
4. **Set `.cullMode = .none`** for thin objects like leaves, grass
5. **Keep `.opacity = 1`** unless you need transparency (faster rendering)

```swift
// Shared material pattern
class Materials {
    static let redMetal = Material.metallic(.red, roughness: 0.3)
    static let grayMatte = Material.matte(Color(gray: 128))
    static let debug = Material.wireframe(.green)
}

// Usage
renderer1.material = Materials.redMetal
renderer2.material = Materials.redMetal  // Same instance!
```
