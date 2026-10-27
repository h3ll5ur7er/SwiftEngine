# Meshes

Meshes define the 3D geometry of objects in your scene.

## Mesh Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Mesh                                        │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        Vertices[]                                │   │
│   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │   │
│   │   │ Vertex  │  │ Vertex  │  │ Vertex  │  │ Vertex  │  ...      │   │
│   │   │ pos     │  │ pos     │  │ pos     │  │ pos     │           │   │
│   │   │ normal  │  │ normal  │  │ normal  │  │ normal  │           │   │
│   │   │ uv      │  │ uv      │  │ uv      │  │ uv      │           │   │
│   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘           │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                        Indices[]                                 │   │
│   │   [0, 1, 2,  0, 2, 3,  4, 5, 6,  ...]                           │   │
│   │    └─tri─┘   └─tri─┘   └─tri─┘                                  │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   bounds: Bounds (AABB for frustum culling)                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Vertex Structure

```swift
public struct Vertex {
    public var position: Vec3d   // 3D position
    public var normal: Vec3d     // Surface normal (for lighting)
    public var uv: Vec2d         // Texture coordinates (not sampled by the renderer yet)
    
    public init(position: Vec3d, normal: Vec3d = .zero, uv: Vec2d = .zero)
}
```

Vertices have no color; a mesh's color comes from its renderer's `Material`.

## Built-in Primitive Meshes

### CubeMesh

```
        4────────5
       /│       /│
      / │      / │
     0────────1  │
     │  7─────│──6
     │ /      │ /
     │/       │/
     3────────2

  Unit cube: -0.5 to 0.5 on all axes
  12 triangles, 24 vertices (6 faces × 4 verts)
```

```swift
// Use shared singleton
let renderer = obj.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared

// Access directly
let mesh = CubeMesh.shared
print(mesh.vertices.count)  // 24
print(mesh.indices.count)   // 36 (12 triangles × 3)
```

### PlaneMesh

```
     0─────────────1
     │             │
     │      Y      │
     │      │      │
     │      └──X   │
     │             │
     3─────────────2

  Horizontal plane at Y=0
  2 triangles, 4 vertices
```

```swift
// Create with custom size
let floor = PlaneMesh(width: 10, depth: 10)

// Normal points up (0, 1, 0)
let renderer = obj.addComponent(MeshRenderer.self)
renderer.mesh = floor
```

### QuadMesh

```
     0───────1
     │       │
     │   Z   │
     │   │   │
     │   └─X │
     │       │
     3───────2

  Vertical quad facing +Z
  2 triangles, 4 vertices
```

```swift
// Create with custom size
let billboard = QuadMesh(width: 2, height: 3)

// Normal points forward (0, 0, 1)
let renderer = obj.addComponent(MeshRenderer.self)
renderer.mesh = billboard
```

## The Mesh Protocol

```swift
public protocol Mesh: AnyObject, Sendable {
    /// All vertices in the mesh
    var vertices: [Vertex] { get }
    
    /// Triangle indices (every 3 indices = 1 triangle)
    var indices: [UInt32] { get }
    
    /// Axis-aligned bounding box (local space)
    var bounds: Bounds { get }
    
    /// Number of triangles (default implementation: indices.count / 3)
    var triangleCount: Int { get }
}
```

## Creating Custom Meshes

### Simple Custom Mesh

```swift
public final class TriangleMesh: Mesh, @unchecked Sendable {
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: Bounds
    
    public init() {
        // Define vertices
        vertices = [
            Vertex(
                position: Vec3d(0, 1, 0),      // Top
                normal: Vec3d(0, 0, 1),        // Facing camera
                uv: Vec2d(0.5, 0)
            ),
            Vertex(
                position: Vec3d(-1, -1, 0),    // Bottom left
                normal: Vec3d(0, 0, 1),
                uv: Vec2d(0, 1)
            ),
            Vertex(
                position: Vec3d(1, -1, 0),     // Bottom right
                normal: Vec3d(0, 0, 1),
                uv: Vec2d(1, 1)
            )
        ]
        
        // Define triangle (counter-clockwise winding)
        indices = [0, 1, 2]
        
        // Calculate bounds
        bounds = Bounds.fromMinMax(
            min: Vec3d(-1, -1, 0),
            max: Vec3d(1, 1, 0)
        )
    }
}
```

### Procedural Mesh Example: Pyramid

```swift
public final class PyramidMesh: Mesh, @unchecked Sendable {
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: Bounds
    
    public init(baseSize: Float = 1, height: Float = 1) {
        let half = baseSize / 2
        
        // Apex
        let apex = Vec3d(0, height, 0)
        
        // Base corners
        let bl = Vec3d(-half, 0, half)   // Back-left
        let br = Vec3d(half, 0, half)    // Back-right
        let fr = Vec3d(half, 0, -half)   // Front-right
        let fl = Vec3d(-half, 0, -half)  // Front-left
        
        // Build faces (each face has its own vertices for flat shading)
        var verts: [Vertex] = []
        var inds: [UInt32] = []
        
        // Helper to add a triangle
        func addTriangle(_ p0: Vec3d, _ p1: Vec3d, _ p2: Vec3d) {
            let normal = (p1 - p0).cross(p2 - p0).normalized
            let baseIdx = UInt32(verts.count)
            
            verts.append(Vertex(position: p0, normal: normal, uv: .zero))
            verts.append(Vertex(position: p1, normal: normal, uv: .zero))
            verts.append(Vertex(position: p2, normal: normal, uv: .zero))
            
            inds.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])
        }
        
        // Four side faces
        addTriangle(apex, bl, br)  // Back
        addTriangle(apex, br, fr)  // Right
        addTriangle(apex, fr, fl)  // Front
        addTriangle(apex, fl, bl)  // Left
        
        // Base (two triangles)
        addTriangle(bl, fl, fr)
        addTriangle(bl, fr, br)
        
        self.vertices = verts
        self.indices = inds
        self.bounds = Bounds.fromMinMax(
            min: Vec3d(-half, 0, -half),
            max: Vec3d(half, height, half)
        )
    }
}
```

## Winding Order

Triangles use **counter-clockwise** winding for front faces:

```
      0
     /│\
    / │ \
   /  │  \
  2───┼───1
      │
      ▼
   Normal (facing you)

Indices: [0, 1, 2] = Counter-clockwise = Front face
Indices: [0, 2, 1] = Clockwise = Back face
```

## Bounds (AABB)

Axis-Aligned Bounding Box for frustum culling:

```swift
public struct Bounds: Sendable {
    public var center: Vec3d  // Center of the box
    public var size: Vec3d    // Full size on each axis
    
    public var min: Vec3d { get }      // center - size / 2
    public var max: Vec3d { get }      // center + size / 2
    public var extents: Vec3d { get }  // size / 2
    
    public init(center: Vec3d = .zero, size: Vec3d = .one)
    public static func fromMinMax(min: Vec3d, max: Vec3d) -> Bounds
    
    public func contains(_ point: Vec3d) -> Bool
    public func intersects(_ other: Bounds) -> Bool
}
```

```swift
// Two ways to build the same bounds
let a = Bounds(center: Vec3d(0, 0.5, 0), size: Vec3d(1, 1, 1))
let b = Bounds.fromMinMax(min: Vec3d(-0.5, 0, -0.5), max: Vec3d(0.5, 1, 0.5))
```

```
      max
       ├──────────┐
       │          │
       │  Mesh    │
       │   is     │
       │  inside  │
       │          │
       └──────────┤
                 min
```

## Using Meshes

### Assign to MeshRenderer

```swift
let cube = createGameObject(name: "Cube")
let renderer = cube.addComponent(MeshRenderer.self)
renderer.mesh = CubeMesh.shared
renderer.material = Material.solid(.blue)
```

### Check Bounds

```swift
if let worldBounds = renderer.worldBounds {
    // worldBounds accounts for position/rotation/scale
    print("Object bounds: \(worldBounds.min) to \(worldBounds.max)")
}
```

### Shared vs Instance

```swift
// Shared (recommended for primitives)
renderer1.mesh = CubeMesh.shared
renderer2.mesh = CubeMesh.shared  // Same mesh data

// Instance (when you need different sizes)
renderer1.mesh = PlaneMesh(width: 5, depth: 5)
renderer2.mesh = PlaneMesh(width: 10, depth: 2)  // Different size
```

## Performance Tips

1. **Share meshes** when possible - primitives provide `.shared` instances
2. **Use appropriate complexity** - don't use high-poly when low-poly works
3. **Ensure valid bounds** - bad bounds = bad frustum culling
4. **Pre-calculate normals** - don't compute per-frame
5. **Index triangles** - reuse vertices via indices

```swift
// ❌ Bad: 6 vertices per quad (2 triangles × 3 verts)
// ✅ Good: 4 vertices per quad, indexed

// 4 vertices
let verts = [v0, v1, v2, v3]

// 6 indices (2 triangles)
let inds: [UInt32] = [
    0, 1, 2,  // Triangle 1
    0, 2, 3   // Triangle 2 (reuses v0 and v2)
]
```
