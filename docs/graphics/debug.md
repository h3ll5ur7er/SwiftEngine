# Debug Drawing

GameEngine provides a `DebugDraw` utility for visualizing debug information like lines, boxes, and spheres.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DebugDraw System                                   │
│                                                                              │
│   Usage: Call debug draw functions from anywhere in your code               │
│          Drawings are rendered for one frame only (fire-and-forget)         │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  Available Primitives                                                │   │
│   │                                                                      │   │
│   │  ─────────  Lines      point to point                               │   │
│   │  □─────□─   Wireframe  box edges                                    │   │
│   │  ○         Spheres    wireframe spheres                             │   │
│   │  →──────▶  Rays       directional lines                             │   │
│   │  ▪→ ▪→ ▪→  Vectors    at positions                                  │   │
│   │  ──●       Points     marked positions                              │   │
│   │                                                                      │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Basic Usage

```swift
import GameEngine

@MainActor
public final class MyComponent: Component {
    public override func update(deltaTime: Float) {
        // Draw a red line
        DebugDraw.line(
            from: Vec3d(0, 0, 0),
            to: Vec3d(5, 0, 0),
            color: .red
        )
        
        // Draw a green wireframe box
        DebugDraw.box(
            center: transform.position,
            size: Vec3d(1, 1, 1),
            color: .green
        )
    }
}
```

---

## Drawing Functions

### Lines

```swift
// Simple line
DebugDraw.line(
    from: Vec3d(0, 0, 0),
    to: Vec3d(10, 5, 0),
    color: .white
)

// Line with custom thickness (if supported)
DebugDraw.line(
    from: startPoint,
    to: endPoint,
    color: .yellow,
    thickness: 2.0
)
```

### Rays

```swift
// Ray from origin in direction
DebugDraw.ray(
    origin: transform.position,
    direction: transform.forward,
    length: 10.0,
    color: .cyan
)

// Visualize a raycast
DebugDraw.ray(
    origin: camera.position,
    direction: camera.forward,
    length: 100.0,
    color: .magenta
)
```

### Boxes

```swift
// Wireframe box
DebugDraw.box(
    center: Vec3d(0, 1, 0),
    size: Vec3d(2, 2, 2),
    color: .green
)

// Box matching a BoxCollider
if let collider = gameObject?.getComponent(BoxCollider.self) {
    DebugDraw.box(
        center: collider.worldCenter,
        size: collider.size,
        color: .yellow
    )
}
```

### Spheres

```swift
// Wireframe sphere
DebugDraw.sphere(
    center: Vec3d(0, 2, 0),
    radius: 1.0,
    color: .blue
)

// Sphere matching a SphereCollider
if let collider = gameObject?.getComponent(SphereCollider.self) {
    DebugDraw.sphere(
        center: collider.worldCenter,
        radius: collider.radius,
        color: .cyan
    )
}
```

### Points

```swift
// Mark a position with a small cross
DebugDraw.point(
    position: hitPoint,
    color: .red,
    size: 0.2
)
```

### Axes / Coordinate System

```swift
// Draw XYZ axes at a position
DebugDraw.axes(
    at: transform.position,
    rotation: transform.rotation,
    scale: 1.0
)
// Red = X, Green = Y, Blue = Z
```

---

## Common Debug Visualizations

### Collider Visualization

```swift
@MainActor
public final class ColliderDebug: Component {
    var showColliders = true
    
    public override func lateUpdate(deltaTime: Float) {
        guard showColliders else { return }
        guard let scene = gameObject?.scene else { return }
        
        // Draw all colliders in scene
        for go in scene.gameObjects {
            if let box = go.getComponent(BoxCollider.self) {
                DebugDraw.box(
                    center: box.worldCenter,
                    size: box.size,
                    color: box.isTrigger ? .yellow : .green
                )
            }
            if let sphere = go.getComponent(SphereCollider.self) {
                DebugDraw.sphere(
                    center: sphere.worldCenter,
                    radius: sphere.radius,
                    color: sphere.isTrigger ? .yellow : .cyan
                )
            }
        }
    }
}
```

### Velocity Visualization

```swift
@MainActor
public final class VelocityDebug: Component {
    public override func lateUpdate(deltaTime: Float) {
        guard let rb = gameObject?.getComponent(RigidBody.self) else { return }
        
        // Draw velocity vector
        let pos = transform.position
        let vel = rb.velocity
        
        DebugDraw.ray(
            origin: pos,
            direction: vel.normalized,
            length: vel.length * 0.5,  // Scale for visibility
            color: .cyan
        )
    }
}
```

### Path Visualization

```swift
func debugDrawPath(_ path: [Vec3d]) {
    guard path.count >= 2 else { return }
    
    for i in 0..<(path.count - 1) {
        DebugDraw.line(
            from: path[i],
            to: path[i + 1],
            color: .yellow
        )
        
        DebugDraw.point(
            position: path[i],
            color: .green,
            size: 0.1
        )
    }
    
    // Mark destination
    DebugDraw.point(
        position: path.last!,
        color: .red,
        size: 0.2
    )
}
```

### Frustum Visualization

```swift
func debugDrawFrustum(_ frustum: Frustum, color: Color = .white) {
    // Draw the 6 planes of the view frustum
    for plane in frustum.planes {
        // Plane visualization
        DebugDraw.ray(
            origin: plane.point,
            direction: plane.normal,
            length: 1.0,
            color: color
        )
    }
}
```

### Bounding Sphere

```swift
func debugDrawBoundingSphere(_ mesh: Mesh, at transform: Transform) {
    let center = transform.position + mesh.boundingCenter
    let radius = mesh.boundingRadius * transform.scale.maxComponent
    
    DebugDraw.sphere(
        center: center,
        radius: radius,
        color: .magenta
    )
}
```

---

## Toggle Debug Drawing

```swift
@MainActor
public final class DebugManager: Component {
    static var showColliders = false
    static var showVelocities = false
    static var showPaths = false
    
    public override func update(deltaTime: Float) {
        let input = Input.shared
        
        // Toggle with function keys
        if input.isKeyPressed(.f1) {
            Self.showColliders.toggle()
        }
        if input.isKeyPressed(.f2) {
            Self.showVelocities.toggle()
        }
        if input.isKeyPressed(.f3) {
            Self.showPaths.toggle()
        }
    }
}

// Use in other components
if DebugManager.showColliders {
    DebugDraw.box(center: center, size: size, color: .green)
}
```

---

## Performance Considerations

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Debug Draw Performance                                   │
│                                                                              │
│   • Debug draws are immediate-mode (no batching)                            │
│   • Each call adds to the render queue                                      │
│   • Disable in production builds                                            │
│                                                                              │
│   Recommendation:                                                            │
│   ──────────────                                                            │
│   #if DEBUG                                                                 │
│       DebugDraw.box(center: pos, size: size, color: .green)                │
│   #endif                                                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

```swift
// Compile-time debug draw toggle
#if DEBUG
func debugVisualize() {
    DebugDraw.box(center: transform.position, size: Vec3d(1,1,1), color: .green)
}
#else
func debugVisualize() { }  // No-op in release
#endif
```

---

## Best Practices

1. **Use for debugging only** - Remove or disable in production
2. **Use consistent colors** - Red for errors, green for valid, yellow for warnings
3. **Draw in lateUpdate** - Ensures transforms are final
4. **Use toggle keys** - F1-F12 for different debug visualizations
5. **Scale appropriately** - Make debug visuals visible but not overwhelming
6. **Add labels mentally** - Color-code to remember what each visualization means
