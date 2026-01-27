# Math: Vectors, Matrices & Quaternions

GameEngine provides a comprehensive math library for 3D graphics.

## Vector Types

### Integer Vectors

| Type | Components | Element Type | Use Case |
|------|------------|--------------|----------|
| `Vec2` | x, y | `Int32` | Screen coordinates, pixel positions |
| `Vec3` | x, y, z | `Int32` | Voxel positions, integer grids |
| `Vec4` | x, y, z, w | `Int32` | Integer color (RGBA) |

### Floating-Point Vectors

| Type | Components | Element Type | Use Case |
|------|------------|--------------|----------|
| `Vec2d` | x, y | `Float32` | 2D positions, UV coordinates |
| `Vec3d` | x, y, z | `Float32` | 3D positions, directions, colors |
| `Vec4d` | x, y, z, w | `Float32` | Homogeneous coordinates, clip space |

## Vec2d

```swift
// Creation
let a = Vec2d(3, 4)
let b = Vec2d(1, 0)

// Arithmetic
let sum = a + b           // Vec2d(4, 4)
let diff = a - b          // Vec2d(2, 4)
let scaled = a * 2        // Vec2d(6, 8)
let divided = a / 2       // Vec2d(1.5, 2)
let negated = -a          // Vec2d(-3, -4)

// Properties
let length = a.length           // 5.0
let lengthSq = a.squaredLength  // 25.0
let normalized = a.normalized   // Vec2d(0.6, 0.8)

// Operations
let dot = a.dot(b)              // 3.0
let cross = a.cross(b)          // 4.0 (2D cross = scalar)
let dist = a.distance(to: b)    // 4.47...
let perpCW = a.perpendicularCW  // Vec2d(4, -3)
let perpCCW = a.perpendicularCCW // Vec2d(-4, 3)

// Interpolation
let lerped = a.lerp(to: b, t: 0.5)  // Vec2d(2, 2)

// Angles
let angle = Vec2d.fromAngle(Float.pi / 4)  // Vec2d(0.707, 0.707)
let angleBetween = a.angle(to: b)          // Angle in radians
```

## Vec3d

```swift
// Creation
let a = Vec3d(1, 2, 3)
let b = Vec3d(4, 5, 6)

// Static vectors
let zero = Vec3d.zero       // (0, 0, 0)
let one = Vec3d.one         // (1, 1, 1)
let up = Vec3d.up           // (0, 1, 0)
let down = Vec3d.down       // (0, -1, 0)
let right = Vec3d.right     // (1, 0, 0)
let left = Vec3d.left       // (-1, 0, 0)
let forward = Vec3d.forward // (0, 0, -1)
let back = Vec3d.back       // (0, 0, 1)

// Arithmetic
let sum = a + b           // Vec3d(5, 7, 9)
let scaled = a * 2        // Vec3d(2, 4, 6)

// Properties
let length = a.length
let normalized = a.normalized

// Operations
let dot = a.dot(b)                    // Scalar
let cross = a.cross(b)                // Vec3d perpendicular to both
let reflected = a.reflect(normal: n)  // Reflect off surface

// Interpolation
let lerped = a.lerp(to: b, t: 0.5)
```

### Cross Product Visualization

```
           cross(a, b)
              │
              │   b
              │  /
              │ /
              │/
    ──────────●────────── a
             /│
            / │
           /  │
          (perpendicular to both)
```

## Vec4d

```swift
// Creation
let v = Vec4d(1, 2, 3, 1)  // w=1 for positions

// Extract Vec3d
let xyz = v.xyz  // Vec3d(1, 2, 3)

// Common in graphics
let clipSpace = Vec4d(x, y, z, w)
let ndc = Vec3d(clipSpace.x / clipSpace.w,
                clipSpace.y / clipSpace.w,
                clipSpace.z / clipSpace.w)
```

## Matrices

### Matrix Types

| Type | Size | Use Case |
|------|------|----------|
| `Mat2d` | 2×2 | 2D rotation, scale |
| `Mat3d` | 3×3 | 3D rotation, scale, normal transforms |
| `Mat4d` | 4×4 | Full 3D transforms (position, rotation, scale) |

### Mat4d

The workhorse for 3D graphics:

```swift
// Identity matrix
let identity = Mat4d.identity

// Translation
let translate = Mat4d.translation(Vec3d(10, 0, 0))

// Rotation (individual axes)
let rotX = Mat4d.rotationX(angle: Float.pi / 4)  // 45° around X
let rotY = Mat4d.rotationY(angle: Float.pi / 4)  // 45° around Y
let rotZ = Mat4d.rotationZ(angle: Float.pi / 4)  // 45° around Z

// Rotation (arbitrary axis)
let rot = Mat4d.rotation(axis: Vec3d.up, angle: Float.pi / 2)

// Scale
let scale = Mat4d.scale(Vec3d(2, 2, 2))  // Double size

// Combine transformations
let model = translate * rotY * scale  // Scale, then rotate, then translate
```

### Matrix Memory Layout (Row-Major)

```
┌─────────────────────────────────────┐
│  m00  m01  m02  m03  │  Row 0 (X)   │
│  m10  m11  m12  m13  │  Row 1 (Y)   │
│  m20  m21  m22  m23  │  Row 2 (Z)   │
│  m30  m31  m32  m33  │  Row 3 (W)   │
└─────────────────────────────────────┘
       Translation is in m03, m13, m23
```

### Transforming Points and Directions

```swift
let matrix = Mat4d.translation(Vec3d(10, 0, 0)) * 
             Mat4d.rotationY(angle: Float.pi / 2)

// Transform a point (includes translation)
let worldPoint = matrix.transformPoint(Vec3d(0, 0, 0))  // (10, 0, 0)

// Transform a direction (ignores translation)
let worldDir = matrix.transformDirection(Vec3d(0, 0, -1))  // (-1, 0, 0)
```

### Camera Matrices

```swift
// View matrix (camera transform)
let view = Mat4d.lookAt(
    eye: Vec3d(0, 5, 10),      // Camera position
    target: Vec3d(0, 0, 0),    // Look at point
    up: Vec3d.up               // Up direction
)

// Perspective projection
let projection = Mat4d.perspective(
    fovY: Float.pi / 3,        // 60° vertical FOV
    aspect: 16.0 / 9.0,        // Aspect ratio
    near: 0.1,                 // Near clip plane
    far: 100.0                 // Far clip plane
)

// Orthographic projection
let ortho = Mat4d.orthographic(
    left: -10, right: 10,
    bottom: -10, top: 10,
    near: 0.1, far: 100
)

// Combined view-projection
let viewProj = projection * view
```

### Matrix Operations

```swift
// Inverse (for un-transforming)
let inverse = matrix.inverse  // Optional, nil if not invertible

// Transpose
let transposed = matrix.transposed

// Extract 3x3 (for normals)
let mat3 = matrix.mat3

// Determinant
let det = matrix.determinant
```

## Quaternions

Quaternions represent rotations without gimbal lock:

```swift
// Identity (no rotation)
let identity = Quaternion.identity

// From axis-angle
let rot90Y = Quaternion.fromAxisAngle(
    axis: Vec3d.up,
    angle: Float.pi / 2  // 90 degrees
)

// From Euler angles
let rotation = Quaternion.fromEulerAngles(
    pitch: 0,              // X rotation
    yaw: Float.pi / 4,     // Y rotation
    roll: 0                // Z rotation
)

// Look rotation
let lookRot = Quaternion.lookRotation(
    forward: (target - position).normalized,
    up: Vec3d.up
)

// Rotation from one direction to another
let fromTo = Quaternion.fromTo(
    from: Vec3d.forward,
    to: someDirection
)
```

### Quaternion Operations

```swift
// Combine rotations (order matters!)
let combined = rotB * rotA  // Apply A, then B

// Rotate a vector
let rotatedVec = quaternion.rotate(Vec3d(1, 0, 0))

// Interpolate (smooth rotation)
let smooth = Quaternion.slerp(from: q1, to: q2, t: 0.5)

// Inverse (opposite rotation)
let inverse = quaternion.inverse

// Extract axis and angle
let axis = quaternion.axis
let angle = quaternion.angle

// Convert to Euler angles
let euler = quaternion.eulerAngles  // Vec3d(pitch, yaw, roll)

// Convert to matrix
let matrix = quaternion.toMatrix  // Mat4d
```

### Why Quaternions?

```
Euler Angles Problem (Gimbal Lock):
═══════════════════════════════════

When pitch = 90°:
  - Yaw and roll become the same axis!
  - Lost one degree of freedom
  
    Y                  After 90° pitch:
    │                       Z
    │     Z                 │
    │    /                  │  
    │   /                   │  X and Z align!
    │  /                    │ /
    └──────── X             └─────── X (same as Z rotation)

Quaternions avoid this by using 4D math.
```

## Color

Colors use `UInt8` components (0-255):

```swift
// Creation
let red = Color(r: 255, g: 0, b: 0)
let green = Color(r: 0, g: 255, b: 0, a: 128)  // Semi-transparent
let gray = Color(gray: 128)

// Predefined colors
let white = Color.white
let black = Color.black
let blue = Color.cornflowerBlue
let steel = Color.steelBlue

// Operations
let lighter = color.scaled(by: 1.5)
let lerped = Color.lerp(from: red, to: blue, t: 0.5)
let blended = color.blendOver(background)
```

## Common Patterns

### Smooth Movement

```swift
let current = Vec3d(0, 0, 0)
let target = Vec3d(10, 0, 0)
let smoothed = current.lerp(to: target, t: 5.0 * deltaTime)
```

### Distance Check

```swift
let distance = (a - b).length
let distanceSq = (a - b).squaredLength  // Faster, no sqrt

if distanceSq < radius * radius {
    // Within radius
}
```

### Angle Between Vectors

```swift
let a = Vec3d(1, 0, 0).normalized
let b = Vec3d(0, 1, 0).normalized
let cosAngle = a.dot(b)  // cos(90°) = 0
let angle = acos(cosAngle)  // π/2
```

### Reflection

```swift
let incoming = Vec3d(1, -1, 0).normalized
let normal = Vec3d.up
let reflected = incoming.reflect(normal: normal)  // (1, 1, 0).normalized
```

```
        │ normal
        │
        │ reflected
   ─────┼─────/
        │    /
        │   /
        │  / incoming
        │ /
        │/
    ────●────
      surface
```
