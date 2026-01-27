# Rendering Pipeline

Understanding how GameEngine renders your 3D scenes.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RENDER PIPELINE                                  │
│                                                                          │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐  │
│  │ Collect │──▶│Transform│──▶│  Cull   │──▶│  Light  │──▶│Rasterize│  │
│  │ Meshes  │   │Vertices │   │Triangles│   │ & Shade │   │  Draw   │  │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘  │
│       │             │             │             │             │         │
│  MeshRenderer  Model→Clip    Frustum +     Directional   Filled       │
│  components    space         Backface      + Ambient     triangles    │
│                              culling       lighting                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Using the Pipeline

### Basic Usage

```swift
public override func render(context: RenderContext) {
    // 1. Clear the screen
    context.renderer.clear(Camera.main?.backgroundColor ?? .black)
    
    // 2. Get camera
    guard let camera = Camera.main else { return }
    
    // 3. Collect all mesh renderers
    let meshRenderers = findComponentsOfType(MeshRenderer.self)
    
    // 4. Render through pipeline
    RenderPipeline.shared.render(
        meshRenderers: meshRenderers,
        camera: camera,
        context: context
    )
}
```

## Pipeline Stages

### 1. Collect Meshes

The pipeline gathers all `MeshRenderer` components:

```swift
// Pipeline internally does:
for renderer in meshRenderers where renderer.isVisible && renderer.isEnabled {
    // Process this renderer
}
```

### 2. Frustum Culling

Objects outside the camera view are skipped early:

```
                    Camera Frustum
                    ┌─────────────────────────┐
                   /│                         │\
                  / │    Visible Objects      │ \
                 /  │    ┌───┐  ┌───┐        │  \
                /   │    │ A │  │ B │        │   \
               /    │    └───┘  └───┘        │    \
              /     │                         │     \
    Camera ◉──────────────────────────────────────────▶
              \     │                         │     /
               \    │                         │    /
                \   │                         │   /
                 \  │                         │  /
                  \ │                         │ /
                   \└─────────────────────────┘/
                    
     ┌───┐                                        ┌───┐
     │ C │  ← Culled (outside frustum)            │ D │  ← Culled
     └───┘                                        └───┘
```

```swift
// Early bounds check
if let worldBounds = renderer.worldBounds {
    if !frustum.intersectsBounds(worldBounds) {
        continue  // Skip this object entirely
    }
}
```

### 3. Vertex Transformation

Vertices are transformed through the graphics pipeline spaces:

```
Local Space ────▶ World Space ────▶ View Space ────▶ Clip Space
     │                 │                │                │
  Model             World            View           Projection
  Matrix            Matrix           Matrix           Matrix
     │                 │                │                │
     └────────────────┴────────────────┴────────────────┘
                           │
                    MVP = P × V × M
```

```swift
// For each vertex:
let worldPos = worldMatrix.transformPoint(vertex.position)
let clipPos = mvpMatrix.transformPoint(vertex.position)  // Vec4d
```

### 4. Triangle Processing

Each triangle is processed individually:

```swift
// Near plane clipping
if v0.w < nearW && v1.w < nearW && v2.w < nearW {
    continue  // All behind camera - skip
}

// Perspective divide: Clip → NDC
let ndc0 = Vec3d(v0.x / v0.w, v0.y / v0.w, v0.z / v0.w)

// NDC → Screen coordinates
let screen0 = Vec2(
    Int32((ndc0.x + 1) * 0.5 * screenWidth),
    Int32((1 - ndc0.y) * 0.5 * screenHeight)  // Y flipped
)
```

### 5. Backface Culling

Triangles facing away from the camera are skipped:

```
Front Face (visible):          Back Face (culled):

    1                               1
   /│\                             /│\
  / │ \                           / │ \
 /  │  \  CCW winding            /  │  \  CW winding
2───┼───3  (facing camera)      3───┼───2  (facing away)
    │                               │
    │ Normal →                      │ Normal ← (away)
    ▼                               ▼
  Camera                          Camera
```

```swift
// Screen-space winding check
let cross = edge1x * edge2y - edge1y * edge2x

if material.cullMode == .back && cross > 0 { continue }
if material.cullMode == .front && cross < 0 { continue }
```

### 6. Lighting Calculation

Flat shading computes one color per triangle:

```swift
// Calculate face normal
let faceNormal = (p1 - p0).cross(p2 - p0).normalized

// Directional light contribution
for light in directionalLights {
    let nDotL = max(0, faceNormal.dot(light.direction))
    contribution += nDotL * light.intensity
}

// Add ambient
let finalIntensity = ambientIntensity + contribution
let finalColor = baseColor * finalIntensity
```

### 7. Depth Sorting (Painter's Algorithm)

Triangles are sorted back-to-front:

```
Back-to-Front Rendering:

1. Sort by average Z depth
2. Draw furthest first
3. Closer objects overwrite

    ┌───────────────────────┐
    │ ┌─────────────────┐   │  ← Drawn first (back)
    │ │   ┌─────────┐   │   │
    │ │   │  Near   │   │   │  ← Drawn last (front)
    │ │   └─────────┘   │   │
    │ └─────────────────┘   │
    └───────────────────────┘

Result: Near objects correctly overlap far objects
```

```swift
// Sort triangles
trianglesToRender.sort { $0.depth > $1.depth }

// Draw in order
for tri in trianglesToRender {
    Primitives.fillTriangle(tri.vertices[0], tri.vertices[1], tri.vertices[2], 
                           color: tri.color)
}
```

### 8. Rasterization

Finally, triangles are filled pixel by pixel:

```
Screen Space Triangle:

     (100, 50)
        /\
       /  \
      /    \
     /______\
(50, 150)  (150, 150)

For each scanline Y from 50 to 150:
  - Find left and right X intersections
  - Fill pixels from left to right
```

## Coordinate Systems

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        COORDINATE SPACES                                 │
│                                                                          │
│   LOCAL           WORLD           VIEW            CLIP           NDC    │
│  ┌─────┐         ┌─────┐        ┌─────┐        ┌─────┐        ┌─────┐  │
│  │ Y   │         │ Y   │        │ Y   │        │ Y   │        │ Y   │  │
│  │ │   │   M     │ │   │   V    │ │   │   P    │ │   │  /w    │ │   │  │
│  │ └─X │  ───▶   │ └─X │  ───▶  │ └─X │  ───▶  │ └─X │  ───▶  │ └─X │  │
│  │/    │         │/    │        │/    │        │/    │        │/    │  │
│  Z     │         Z     │        Z     │        Z/W   │        │-1,1 │  │
│  └─────┘         └─────┘        └─────┘        └─────┘        └─────┘  │
│                                                                          │
│   Object's       Scene          Camera          After            After  │
│   own space      space          space          projection      divide   │
│                                                                          │
│                                                    ▼                     │
│                                              ┌───────────┐               │
│                                  SCREEN      │ 0,0───────┤               │
│                                  ───────▶    │ │ pixels  │               │
│                                  Viewport    │ │         │               │
│                                  transform   │ └─────────┤               │
│                                              │      W,H  │               │
│                                              └───────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Shading Models

```swift
public enum ShadingModel {
    case unlit    // No lighting - use base color as-is
    case flat     // One color per triangle face
    case gouraud  // Interpolate colors across vertices (not implemented)
    case pbr      // Physically-based rendering (not implemented)
}
```

### Flat Shading Example

```
                Light
                  ↘
    ┌──────────────┐
    │ ████████████ │ ← Bright face (facing light)
    │              │
    │              │
    │ ▒▒▒▒▒▒▒▒▒▒▒▒ │ ← Medium face (angled)
    │              │
    │              │
    │ ░░░░░░░░░░░░ │ ← Dark face (facing away)
    └──────────────┘
```

## Performance Tips

### 1. Reduce Triangle Count

```swift
// Use simpler meshes for distant objects
let detailedMesh = CubeMesh.shared        // 12 triangles
let simpleMesh = /* lower poly version */  // 6 triangles
```

### 2. Use Frustum Culling

```swift
// Ensure meshes have bounds
renderer.mesh = myMesh  // Should have valid bounds property
```

### 3. Cull Invisible Objects

```swift
// Disable renderers you don't need
renderer.isVisible = false  // Won't be processed at all
```

### 4. Batch Similar Materials

The pipeline already sorts by depth, but keeping similar materials together can help cache performance.

## Custom Rendering

For special effects, you can bypass the pipeline:

```swift
public override func render(context: RenderContext) {
    // Standard 3D rendering
    RenderPipeline.shared.render(...)
    
    // Custom 2D overlay
    Primitives.fillTriangle(
        Vec2(100, 100),
        Vec2(200, 100),
        Vec2(150, 50),
        color: .red
    )
    
    // Direct line drawing
    Primitives.drawLine(
        Vec2(0, 0),
        Vec2(context.width, context.height),
        color: .white
    )
}
```
