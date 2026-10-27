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
│  roughness: Float                   alphaCutoff: Float                   │
│  metallic: Float                                                         │
│  emissionColor: Color                                                    │
│  emissionIntensity: Float                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

> **What the renderer uses:** `color` (RGB), `shadingModel`, `cullMode`, and `renderMode` (wireframe vs filled). `mainTexture`, `opacity`, `alphaCutoff`, `roughness`, `metallic`, `emissionColor` and `emissionIntensity` are stored on the material but **not used by the renderer**: textures aren't sampled, and `.transparent` / `.cutout` materials render as opaque.

## Creating Materials

### Factory Methods

```swift
// Solid color (opaque)
let red = Material.solid(.red)

// Matte surface (roughness = 1)
let concrete = Material.matte(Color(gray: 128))

// Metallic surface
let gold = Material.metallic(Color(r: 255, g: 215, b: 0), roughness: 0.3)

// Transparent (opacity is stored, but currently renders opaque)
let glass = Material.transparent(.white, opacity: 0.3)

// Emissive - sets emission and .unlit shading; renders as flat unlit color
let neon = Material.emissive(.cyan, intensity: 2.0)

// Note: roughness, metallic, opacity and emission don't affect rendering yet
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
    case gouraud  // Per-vertex lighting, interpolated across each triangle
    case pbr      // Physically-based rendering (future; shaded like .flat)
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

### Gouraud Shading

Lights each vertex using its normal and interpolates the colors across the triangle for a smooth look. It only differs from flat shading on meshes whose vertices carry smooth (shared or averaged) normals; `CubeMesh` has per-face normals, so it looks the same either way.

```swift
let material = Material.solid(.orange)
material.shadingModel = .gouraud  // Per-vertex lighting
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
    case transparent // Alpha blending (not implemented - renders as opaque)
    case cutout      // Binary transparency (not implemented - renders as opaque)
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

Intended for alpha blending (glass, water, etc.), but not implemented yet: the renderer ignores `opacity` and draws these materials as opaque. There is no blending or sorting.

```swift
let glass = Material.transparent(.white, opacity: 0.3)
glass.renderMode = .transparent
// Note: currently renders as an opaque white surface
```

### Cutout

Intended for binary transparency (pixels either fully visible or invisible), but not implemented yet: no alpha test is performed and cutout materials render as opaque.

```swift
let foliage = Material()
foliage.renderMode = .cutout
foliage.alphaCutoff = 0.5  // Stored, but not used by the renderer yet
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
// metallic/roughness are stored but not used by the renderer yet
```

### Glowing Object

```swift
let glow = Material.emissive(.cyan, intensity: 2.0)
glow.shadingModel = .unlit  // Already set by emissive(); emission intensity isn't rendered
```

### Glass/Window

```swift
let glass = Material.transparent(Color(r: 200, g: 220, b: 255), opacity: 0.3)
glass.cullMode = .none  // Render both sides (still opaque - transparency isn't implemented)
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
3. **Use `.flat`** for a low-poly look, `.gouraud` for smooth shading on meshes with smooth normals
4. **Set `.cullMode = .none`** for thin objects like leaves, grass
5. **Don't rely on textures, opacity or PBR properties** - the renderer currently ignores them

```swift
// Shared material pattern
class Materials {
    static let redMetal = Material.metallic(.red, roughness: 0.3)
    static let grayMatte = Material.matte(Color(gray: 128))
    static let debug = Material.wireframe  // Built-in white wireframe material (a static property)
}

// Usage
renderer1.material = Materials.redMetal
renderer2.material = Materials.redMetal  // Same instance!
```
