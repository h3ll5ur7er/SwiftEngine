# Debug Drawing

GameEngine provides a `DebugDraw` utility for visualizing colliders and drawing 3D debug lines and points.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DebugDraw System                                   │
│                                                                              │
│   Usage: Call DebugDraw.shared from your scene's render(context:)           │
│          Lines are drawn immediately into the backbuffer (no depth test)    │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  Available Drawing                                                   │   │
│   │                                                                      │   │
│   │  □─────□─   Colliders  draw(context:camera:) - all colliders         │   │
│   │  ─────────  Lines      draw3DLine(from:to:color:context:camera:)     │   │
│   │  ──●       Points     draw3DPoint(_:color:size:context:camera:)     │   │
│   │                                                                      │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

`DebugDraw` is a `@MainActor` class used through its shared instance, `DebugDraw.shared`. All drawing methods need the frame's `RenderContext` and a `Camera`, so call them during rendering (inside `render(context:)`), not from `update`.

## Basic Usage

```swift
import GameEngine

@MainActor
public final class MyScene: GameObjectScene {
    public override func render(context: RenderContext) {
        // Default rendering: 3D scene + UI overlays
        super.render(context: context)
        
        guard let camera = Camera.main else { return }
        
        // Draw wireframes for every enabled collider
        DebugDraw.shared.draw(context: context, camera: camera)
        
        // Draw a red line
        DebugDraw.shared.draw3DLine(
            from: Vec3d(0, 0, 0),
            to: Vec3d(5, 0, 0),
            color: .red,
            context: context,
            camera: camera
        )
    }
}
```

---

## Drawing Functions

### Colliders

```swift
// Draws all enabled colliders on active GameObjects (from CollisionManager)
DebugDraw.shared.draw(context: context, camera: camera)
```

- **BoxCollider** - the box rotated by the transform (`worldCorners`), plus, if `showAABB` is on, the axis-aligned box around those rotated corners (`worldMin`/`worldMax`). Note that physics ignores rotation and collides with the unrotated box, so for rotated boxes neither wireframe is exactly the collision shape.
- **SphereCollider** - three circles (XY, XZ and YZ planes)
- **PlaneCollider** - a 20×20 grid around `worldPlanePoint`, plus a line along the normal

`draw` does nothing when `isEnabled` or `showColliders` is false.

### Lines

```swift
// Line between two world-space points (clipped against the near plane)
DebugDraw.shared.draw3DLine(
    from: Vec3d(0, 0, 0),
    to: Vec3d(10, 5, 0),
    color: .white,
    context: context,
    camera: camera
)
```

### Points

```swift
// Mark a position with a small 3D cross (size defaults to 0.1)
DebugDraw.shared.draw3DPoint(
    hitPoint,
    color: .red,
    size: 0.2,
    context: context,
    camera: camera
)
```

### Settings

```swift
let debug = DebugDraw.shared

debug.isEnabled = true        // Master switch for draw(context:camera:)
debug.showColliders = true    // Draw collider wireframes
debug.showAABB = true         // Also draw the AABB around rotated box colliders

// Colors
debug.boxColliderColor = .green
debug.aabbColor = .yellow
debug.sphereColliderColor = .cyan
debug.planeColliderColor = .purple
debug.contactColor = .red     // Stored, but nothing is drawn with it yet
```

`isEnabled` and `showColliders` only affect `draw(context:camera:)`; `draw3DLine` and `draw3DPoint` always draw.

---

## Common Debug Visualizations

### Velocity Visualization

```swift
// Inside render(context:), after the 3D pass
for rb in findComponentsOfType(RigidBody.self) {
    let pos = rb.transform.position
    DebugDraw.shared.draw3DLine(
        from: pos,
        to: pos + rb.velocity * 0.5,  // Scale for visibility
        color: .cyan,
        context: context,
        camera: camera
    )
}
```

### Path Visualization

```swift
func debugDrawPath(_ path: [Vec3d], context: RenderContext, camera: Camera) {
    guard path.count >= 2 else { return }
    let debug = DebugDraw.shared
    
    for i in 0..<(path.count - 1) {
        debug.draw3DLine(from: path[i], to: path[i + 1], color: .yellow, context: context, camera: camera)
        debug.draw3DPoint(path[i], color: .green, size: 0.1, context: context, camera: camera)
    }
    
    // Mark destination
    debug.draw3DPoint(path.last!, color: .red, size: 0.2, context: context, camera: camera)
}
```

### Mesh Bounds

```swift
func debugDrawBounds(_ renderer: MeshRenderer, context: RenderContext, camera: Camera) {
    // World-space AABB (accounts for position/rotation/scale)
    guard let bounds = renderer.worldBounds else { return }
    let mn = bounds.min, mx = bounds.max
    let corners = [
        Vec3d(mn.x, mn.y, mn.z), Vec3d(mx.x, mn.y, mn.z), Vec3d(mx.x, mx.y, mn.z), Vec3d(mn.x, mx.y, mn.z),
        Vec3d(mn.x, mn.y, mx.z), Vec3d(mx.x, mn.y, mx.z), Vec3d(mx.x, mx.y, mx.z), Vec3d(mn.x, mx.y, mx.z)
    ]
    let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)]
    for (i, j) in edges {
        DebugDraw.shared.draw3DLine(from: corners[i], to: corners[j], color: .magenta, context: context, camera: camera)
    }
}
```

---

## Toggle Debug Drawing

```swift
@MainActor
public final class MyScene: GameObjectScene {
    public override func update(context: FrameContext, input: Input) {
        // Toggle collider wireframes with F1
        if input.isKeyPressed(.f1) {
            DebugDraw.shared.showColliders.toggle()
        }
        
        super.update(context: context, input: input)
    }
}
```

---

## Performance Considerations

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Debug Draw Performance                                   │
│                                                                              │
│   • Debug draws are immediate-mode (no batching)                            │
│   • Each line is projected and drawn straight into the backbuffer           │
│   • draw(context:camera:) visits every registered collider                  │
│   • Disable in production builds                                            │
│                                                                              │
│   Recommendation:                                                            │
│   ──────────────                                                            │
│   #if DEBUG                                                                 │
│       DebugDraw.shared.draw(context: context, camera: camera)               │
│   #endif                                                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
// Compile-time debug draw toggle
#if DEBUG
DebugDraw.shared.isEnabled = true
#else
DebugDraw.shared.isEnabled = false  // draw(context:camera:) becomes a no-op
#endif
```

---

## Best Practices

1. **Use for debugging only** - Remove or disable in production
2. **Use consistent colors** - Red for errors, green for valid, yellow for warnings
3. **Draw during render** - After the 3D pass, so lines appear on top of the scene
4. **Use toggle keys** - F1-F12 for different debug visualizations
5. **Scale appropriately** - Make debug visuals visible but not overwhelming
6. **Add labels mentally** - Color-code to remember what each visualization means
