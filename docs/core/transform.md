# Transform

Every GameObject has a Transform component that defines its position, rotation, and scale.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Transform                                   │
│                                                                      │
│   localPosition: Vec3d    ──────────────────────▶  Position         │
│   localRotation: Quaternion ────────────────────▶  Rotation         │
│   localScale: Vec3d       ──────────────────────▶  Scale            │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                    Computed Properties                       │   │
│   │                                                              │   │
│   │   worldPosition  ◀───  localPosition + parent transforms    │   │
│   │   worldRotation  ◀───  localRotation * parent rotations     │   │
│   │   worldScale     ◀───  localScale * parent scales           │   │
│   │   worldMatrix    ◀───  combined 4x4 transformation matrix   │   │
│   └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Local vs World Space

```
World Space                          Local Space
═══════════════                      ═══════════════

     Y (world up)                    Parent GameObject
     │                               │
     │    Child                      └─── Y (parent's up)
     │   /                                │
     │  /                                 │    Child
     └──────── X (world)                  │   /
    /                                     │  /
   /                                      └──────── X
  Z                                      /
                                        Z

The child's localPosition is              The same position in
relative to its parent                    world coordinates
```

### Example

```swift
let parent = createGameObject(name: "Parent", at: Vec3d(10, 0, 0))
let child = createGameObject(name: "Child", parent: parent)

child.transform.localPosition = Vec3d(2, 0, 0)

// Local position is (2, 0, 0) - relative to parent
print(child.transform.localPosition)  // Vec3d(2, 0, 0)

// World position is (12, 0, 0) - absolute in scene
print(child.transform.worldPosition)  // Vec3d(12, 0, 0)
```

## Position

### Setting Position

```swift
// Local position (relative to parent)
transform.localPosition = Vec3d(5, 0, 0)

// Move by offset
transform.localPosition += Vec3d(1, 0, 0)  // Move 1 unit right
```

### Reading Position

```swift
// Get local position
let local = transform.localPosition

// Get world position (includes parent transforms)
let world = transform.worldPosition
```

## Rotation

Rotations use **Quaternions** internally for smooth interpolation and avoiding gimbal lock.

### Setting Rotation

```swift
// From Euler angles (in radians)
transform.localRotation = Quaternion.fromEulerAngles(
    pitch: 0,           // X rotation
    yaw: Float.pi / 2,  // Y rotation (90°)
    roll: 0             // Z rotation
)

// From axis-angle
transform.localRotation = Quaternion.fromAxisAngle(
    axis: Vec3d.up,     // Rotate around Y
    angle: Float.pi / 4 // 45 degrees
)

// Look at a target
let direction = target.transform.worldPosition - transform.worldPosition
transform.localRotation = Quaternion.lookRotation(
    forward: direction.normalized,
    up: Vec3d.up
)
```

### Reading Rotation

```swift
// Get quaternion
let rotation = transform.localRotation

// Get Euler angles
let euler = transform.localRotation.eulerAngles
let pitch = euler.x
let yaw = euler.y
let roll = euler.z
```

### Rotating Over Time

```swift
public override func update(deltaTime: Float) {
    // Rotate 90 degrees per second around Y axis
    let rotation = Quaternion.fromAxisAngle(
        axis: Vec3d.up,
        angle: (Float.pi / 2) * deltaTime
    )
    transform.localRotation = rotation * transform.localRotation
}
```

## Scale

```swift
// Uniform scale
transform.localScale = Vec3d(2, 2, 2)  // Double size

// Non-uniform scale
transform.localScale = Vec3d(2, 1, 1)  // Stretch along X

// Scale relative to current
transform.localScale = transform.localScale * 1.1  // Grow 10%
```

## Direction Vectors

Transform provides convenient direction vectors:

```
            forward (Z-)
               ▲
               │
               │
    left ◀─────┼─────▶ right
    (X-)       │       (X+)
               │
               ▼
            back (Z+)
            
            up (Y+)
             ▲
             │
             │
             ●──────▶
            down (Y-)
```

```swift
// Get local direction vectors (accounting for rotation)
let forward = transform.forward   // -Z direction
let right = transform.right       // +X direction
let up = transform.up             // +Y direction

// Move forward
transform.localPosition += transform.forward * speed * deltaTime

// Strafe right
transform.localPosition += transform.right * speed * deltaTime
```

## Transformation Matrix

The `worldMatrix` combines position, rotation, and scale into a 4x4 matrix:

```swift
// Get the full transformation matrix
let matrix = transform.worldMatrix

// Transform a point from local to world space
let localPoint = Vec3d(1, 0, 0)
let worldPoint = matrix.transformPoint(localPoint)

// Transform a direction (ignores translation)
let localDir = Vec3d(0, 0, -1)
let worldDir = matrix.transformDirection(localDir)
```

### Matrix Composition

```
World Matrix = Parent World Matrix × Local Matrix

Local Matrix = Translation × Rotation × Scale

┌─────────────────────────┐
│ [Rotation × Scale]  T  │     T = Translation
│                     T  │     
│                     T  │     Rotation × Scale is 3×3
│    0    0    0      1  │
└─────────────────────────┘
```

## Hierarchy Transformations

```swift
// Create a hierarchy
let arm = createGameObject(name: "Arm")
let hand = createGameObject(name: "Hand", parent: arm)
let finger = createGameObject(name: "Finger", parent: hand)

// Position locally
arm.transform.localPosition = Vec3d(0, 1, 0)     // Arm at Y=1
hand.transform.localPosition = Vec3d(0.5, 0, 0)  // Hand offset from arm
finger.transform.localPosition = Vec3d(0.2, 0, 0) // Finger offset from hand

// Rotate the arm - hand and finger follow!
arm.transform.localRotation = Quaternion.fromAxisAngle(
    axis: Vec3d.forward,
    angle: Float.pi / 4  // 45°
)

// The finger's world position accounts for all parent transforms
let fingerWorldPos = finger.transform.worldPosition
```

```
Before rotation:                After 45° arm rotation:
                                          
      F─H─A                              A
                                        /
                                       H
                                      /
                                     F

F = Finger, H = Hand, A = Arm
```

## Common Operations

### Look At Target

```swift
func lookAt(target: Vec3d) {
    let direction = (target - transform.worldPosition).normalized
    if direction.length > 0.001 {
        transform.localRotation = Quaternion.lookRotation(
            forward: direction,
            up: Vec3d.up
        )
    }
}
```

### Move Toward Target

```swift
func moveToward(target: Vec3d, speed: Float, deltaTime: Float) {
    let direction = target - transform.worldPosition
    let distance = direction.length
    
    if distance > 0.01 {
        let moveAmount = min(speed * deltaTime, distance)
        transform.localPosition += direction.normalized * moveAmount
    }
}
```

### Orbit Around Point

```swift
func orbitAround(center: Vec3d, axis: Vec3d, speed: Float, deltaTime: Float) {
    let offset = transform.worldPosition - center
    let rotation = Quaternion.fromAxisAngle(axis: axis, angle: speed * deltaTime)
    let newOffset = rotation.rotate(offset)
    transform.localPosition = center + newOffset
    
    // Optionally face the center
    lookAt(target: center)
}
```

### Smooth Follow

```swift
var targetPosition: Vec3d = .zero
let smoothSpeed: Float = 5.0

public override func lateUpdate(deltaTime: Float) {
    // Smoothly interpolate toward target
    let current = transform.localPosition
    transform.localPosition = current.lerp(
        to: targetPosition, 
        t: smoothSpeed * deltaTime
    )
}
```
