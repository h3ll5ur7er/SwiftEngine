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
│  MeshRenderer  Model→Clip    Frustum,      Directional   Depth-tested │
│  components    space         near/far clip + Ambient     triangles    │
│                              + backface    lighting                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Using the Pipeline

### Basic Usage

`GameObjectScene` already has a default `render(context:)` that does this: it matches `Camera.main`'s aspect ratio to the window, clears to the camera's background color, renders all `MeshRenderer`s, then draws UI overlays. Override it only for custom rendering, along these lines:

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
let p = vertex.position
let clipPos = mvp * Vec4d(p.x, p.y, p.z, 1)  // Vec4d, before the perspective divide
```

### 4. Triangle Processing

Each triangle is processed individually:

```swift
// Trivially reject triangles entirely outside the left/right/top/bottom planes
if (c0.x > c0.w && c1.x > c1.w && c2.x > c2.w) ||
   (c0.x < -c0.w && c1.x < -c1.w && c2.x < -c2.w) || /* ...same for y... */ {
    return
}

// Triangles crossing the near or far plane are clipped (TriangleClipper);
// the resulting polygon is drawn as a triangle fan
if !TriangleClipper.isInsideDepthRange(c0, c1, c2) {
    let polygon = TriangleClipper.clip(v0, v1, v2)
}

// Perspective divide: Clip → NDC → Screen coordinates
let invW = 1 / c.w
let screenX = (c.x * invW + 1) * 0.5 * screenWidth
let screenY = (1 - c.y * invW) * 0.5 * screenHeight  // Y flipped
let depth = c.z * invW                                // kept for the depth test
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

Flat shading (the default) computes one color per triangle from its face normal. Gouraud shading (`ShadingModel.gouraud`) instead lights each vertex using its normal (transformed by the inverse-transpose of the world matrix) and interpolates the colors across the triangle. Unlit materials skip lighting.

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

### 7. Depth Testing (Z-Buffer)

There is no sorting step. Each call to `RenderPipeline.render` first clears a per-pixel depth buffer (`Renderer.clearDepth()`), and the rasterizer only writes a pixel when it is closer than what is already there:

```
Per-pixel depth test:

1. Interpolate depth (NDC z) across the triangle
2. Compare with the depth buffer at that pixel
3. Write color + depth only if closer

Result: Near surfaces correctly hide far ones,
        regardless of draw order - even intersecting triangles
```

```swift
// Inside the rasterizer, for each pixel of a triangle:
if z < depth[i] {
    depth[i] = z
    pixels[i] = color
}
```

### 8. Rasterization

Finally, triangles are filled pixel by pixel (`TriangleRasterizer`), with the depth test above. Materials with `renderMode = .wireframe` draw triangle outlines instead:

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
  - Fill pixels from left to right (depth-tested;
    Gouraud colors interpolated per pixel)
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
    case gouraud  // Per-vertex lighting, colors interpolated across the triangle
    case pbr      // Physically-based rendering (not implemented; shaded like .flat)
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

### 4. No Sorting Needed

The pipeline doesn't sort meshes or triangles; the depth buffer resolves visibility, so draw order doesn't affect the result.

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
        from: Vec2(0, 0),
        to: Vec2(context.width, context.height),
        color: .white
    )
}
```
