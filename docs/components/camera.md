# Camera Component

The Camera component defines how the 3D world is viewed and projected onto the screen.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Camera                                        │
│                                                                          │
│  Projection Settings              View Settings                          │
│  ───────────────────              ─────────────                          │
│  projection: .perspective         (from Transform)                       │
│  fieldOfView: 60.0°               position                               │
│  nearClipPlane: 0.1               rotation                               │
│  farClipPlane: 100.0                                                     │
│  aspect: auto                     Static Access                          │
│                                   ─────────────                          │
│  Display Settings                 Camera.main                            │
│  ────────────────                 Camera.all                             │
│  backgroundColor: Color                                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Creating a Camera

```swift
let cameraObject = createGameObject(name: "Camera", at: Vec3d(0, 2, 10))

let camera = cameraObject.addComponent(Camera.self)
camera.projection = .perspective
camera.fieldOfView = 60.0
camera.nearClipPlane = 0.1
camera.farClipPlane = 100.0
camera.backgroundColor = Color(r: 30, g: 30, b: 40)
```

## Projection Types

### Perspective

Objects appear smaller when further away (realistic 3D):

```
            Near                Far
             ├───────────────────┤
            ╱│                   │╲
           ╱ │                   │ ╲
          ╱  │   Field of       │  ╲
Camera ◉────│       View        │────▶
          ╲  │                   │  ╱
           ╲ │                   │ ╱
            ╲│                   │╱
             ├───────────────────┤
```

```swift
camera.projection = .perspective
camera.fieldOfView = 60.0  // Vertical FOV in degrees
```

### Orthographic

No perspective - objects stay same size regardless of distance (2D/isometric):

```
            Near                Far
             ├───────────────────┤
             │                   │
             │                   │
             │                   │
Camera ◉────│       Size        │────▶
             │                   │
             │                   │
             │                   │
             ├───────────────────┤
```

```swift
camera.projection = .orthographic
camera.orthographicSize = 5.0  // Half-height in world units
```

## Camera Properties

### Field of View

```swift
camera.fieldOfView = 60.0   // Normal view
camera.fieldOfView = 90.0   // Wide angle
camera.fieldOfView = 30.0   // Zoomed in
```

```
FOV 30° (telephoto):     FOV 60° (normal):      FOV 90° (wide):
       /\                    /    \                /        \
      /  \                  /      \              /          \
     /    \                /        \            /            \
Camera ◉   |           Camera ◉     |        Camera ◉         |
     \    /                \        /            \            /
      \  /                  \      /              \          /
       \/                    \    /                \        /
```

### Clipping Planes

```swift
camera.nearClipPlane = 0.1    // Minimum render distance
camera.farClipPlane = 1000.0  // Maximum render distance
```

```
            near            far
              │               │
Camera ◉──────┼───────────────┼──────▶
              │   Rendered    │
              │     Zone      │
              │               │
        ◀────▶               ◀─────▶
        Clipped              Clipped
```

### Background Color

```swift
camera.backgroundColor = .black
camera.backgroundColor = Color(r: 135, g: 206, b: 235)  // Sky blue
camera.backgroundColor = .vsCodeDark  // Dark IDE theme
```

## Static Access

### Main Camera

The first enabled camera is automatically the "main" camera:

```swift
// Access the main camera from anywhere
if let camera = Camera.main {
    let viewProj = camera.viewProjectionMatrix
}
```

### All Cameras

```swift
// Get all active cameras
let cameras = Camera.all

// Render from multiple viewpoints
for camera in cameras {
    RenderPipeline.shared.render(meshRenderers: renderers, 
                                  camera: camera, 
                                  context: context)
}
```

## Camera Matrices

### View Matrix

Transforms world space to camera space:

```swift
let viewMatrix = camera.viewMatrix
// Inverse of camera's world transform
```

### Projection Matrix

Transforms camera space to clip space:

```swift
let projectionMatrix = camera.projectionMatrix
// Perspective or orthographic
```

### Combined View-Projection

```swift
let viewProj = camera.viewProjectionMatrix
// projectionMatrix * viewMatrix

// Transform a world point to clip space
let clipPos = viewProj * Vec4d(worldPos.x, worldPos.y, worldPos.z, 1)
```

## Frustum

The camera's visible volume:

```swift
let frustum = camera.frustum

// Check if a point is visible
if frustum.containsPoint(worldPosition) {
    // Point is in view
}

// Check if bounds are visible (for culling)
if frustum.intersectsBounds(objectBounds) {
    // At least partially visible
}
```

### Frustum Planes

```
                    Top
                   ╱    ╲
                  ╱      ╲
                 ╱        ╲
               ╱    Far    ╲
              ╱    Plane    ╲
             ╱              ╲
    Left ───┼────────────────┼─── Right
             ╲              ╱
              ╲   Near    ╱
               ╲ Plane   ╱
                ╲      ╱
                 ╲    ╱
                  Bottom

6 planes: near, far, left, right, top, bottom
```

## Camera Movement

### Basic Movement

```swift
// Move camera position
cameraObject.transform.localPosition += Vec3d(0, 0, -1) * speed * deltaTime

// Rotate camera
let rotation = Quaternion.fromAxisAngle(axis: .up, angle: turnSpeed * deltaTime)
cameraObject.transform.localRotation = rotation * cameraObject.transform.localRotation
```

### Using PlayerController

```swift
let player = createGameObject(name: "Player", at: Vec3d(0, 0, 10))
player.addComponent(Camera.self)

let controller = player.addComponent(PlayerController.self)
controller.moveSpeed = 5.0

// In update:
controller.setInput(input)
```

### Look At Target

```swift
public final class FollowCamera: Component {
    public var target: Transform?
    public var offset = Vec3d(0, 5, 10)
    
    public override func lateUpdate(deltaTime: Float) {
        guard let target = target else { return }
        
        // Position behind target
        let targetPos = target.worldPosition
        transform.localPosition = targetPos + offset
        
        // Look at target
        let direction = (targetPos - transform.worldPosition).normalized
        transform.localRotation = Quaternion.lookRotation(
            forward: direction,
            up: Vec3d.up
        )
    }
}
```

## Common Camera Setups

### First-Person Camera

```swift
let player = createGameObject(name: "Player", at: Vec3d(0, 1.7, 0))
let camera = player.addComponent(Camera.self)
camera.fieldOfView = 75.0

let controller = player.addComponent(PlayerController.self)
controller.moveSpeed = 5.0
controller.enableMouseLook = true
```

### Third-Person Camera

```swift
let player = createGameObject(name: "Player")
// ... player setup ...

let cameraArm = createGameObject(name: "CameraArm", parent: player)
cameraArm.transform.localPosition = Vec3d(0, 2, 0)

let cameraObj = createGameObject(name: "Camera", parent: cameraArm)
cameraObj.transform.localPosition = Vec3d(0, 0, 5)  // Behind player
cameraObj.addComponent(Camera.self)

// Rotating cameraArm rotates camera around player
```

### Top-Down Camera

```swift
let camera = createGameObject(name: "Camera", at: Vec3d(0, 20, 0))
let cam = camera.addComponent(Camera.self)
cam.projection = .orthographic
cam.orthographicSize = 10.0

// Look straight down
camera.transform.localRotation = Quaternion.fromAxisAngle(
    axis: Vec3d.right, 
    angle: -Float.pi / 2  // -90 degrees
)
```

### Isometric Camera

```swift
let camera = createGameObject(name: "Camera", at: Vec3d(10, 10, 10))
let cam = camera.addComponent(Camera.self)
cam.projection = .orthographic
cam.orthographicSize = 8.0

// Look at origin from corner
let direction = (Vec3d.zero - camera.transform.localPosition).normalized
camera.transform.localRotation = Quaternion.lookRotation(
    forward: direction,
    up: Vec3d.up
)
```

## Screen-Space Conversion

```swift
// World position to screen position (approximately)
func worldToScreen(_ worldPos: Vec3d, camera: Camera, screenSize: Vec2) -> Vec2? {
    let viewProj = camera.viewProjectionMatrix
    let clip = viewProj.transformPoint(worldPos)
    
    // Behind camera check
    guard clip.z > 0 else { return nil }
    
    // NDC to screen
    let screenX = (clip.x + 1) * 0.5 * Float(screenSize.x)
    let screenY = (1 - clip.y) * 0.5 * Float(screenSize.y)  // Flip Y
    
    return Vec2(Int32(screenX), Int32(screenY))
}
```
