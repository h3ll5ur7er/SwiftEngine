# Swift Low-Level Renderer - Engine Reference

## Overview
A cross-platform 3D game engine written in Swift featuring:
- Platform abstraction layer for OS-independent code
- Component-based GameObjects
- Software 3D rendering with lighting
- Physics simulation with collision detection
- Actor-based concurrency (PhysicsActor, GameLogicActor, AssetLoadingActor)
- SwiftUI-inspired UI system

Currently supported platforms: Windows (via WinSDK)

---

## Directory Structure

```
Sources/
├── WindowsPlatform/     # Windows-specific platform implementation (separate module)
│   ├── Backbuffer.swift # GDI-based software rendering
│   ├── Window.swift     # Win32 window management
│   ├── Timer.swift      # High-precision timing
│   ├── KeyCodeTranslator.swift
│   └── Platform.swift   # Platform utilities
├── GameEngine/
│   ├── Actors/          # Concurrent actors for off-main-thread work
│   ├── Components/      # GameObject components (Camera, Colliders, etc.)
│   ├── Engine/          # Core engine types (Engine, Transform, Mesh, etc.)
│   ├── Graphics/        # Math types and rendering (Vec3d, Mat4d, Color, etc.)
│   ├── Platform/        # Platform abstraction (PlatformInterface + wrappers)
│   ├── Scene/           # Scene management and lights
│   └── UI/              # SwiftUI-style UI framework
└── Game/                # User game code
```

---

## Core Engine (`Engine/`)

### `Engine` (MainActor)
Main game loop and system coordination.
```swift
public final class Engine {
    public let input: Input
    public let renderer: Renderer
    
    public init(config: EngineConfig)
    public func loadScene(_ scene: Scene)
    public func unloadScene()
    public func run() async
    public func stop()
    public var windowSize: (width: Int32, height: Int32)
    public func captureMouse() / releaseMouse() / toggleMouseCapture()
}
```

### `EngineConfig` (Sendable)
```swift
public struct EngineConfig {
    public var title: String
    public var width: Int32
    public var height: Int32
    public var targetFps: Int?
    public var showFpsInTitle: Bool
}
```

### `GameObject` (MainActor)
Container for components with transform hierarchy.
```swift
public final class GameObject {
    public let id: UUID
    public var name: String
    public var isActive: Bool
    public let transform: Transform
    public var tag: String
    public var layer: Int
    
    @discardableResult public func addComponent<T: Component>(_ component: T) -> T
    @discardableResult public func addComponent<T: Component>(_ type: T.Type) -> T
    public func getComponent<T: Component>(_ type: T.Type) -> T?
    public func getComponents<T: Component>(_ type: T.Type) -> [T]
    public func removeComponent(_ component: Component)
    public func setParent(_ newParent: GameObject?, worldPositionStays: Bool = true)
}
```

### `Component` (MainActor, open)
Base class for all components.
```swift
open class Component {
    public weak var gameObject: GameObject?
    public var isEnabled: Bool
    public var transform: Transform { get }
    public var typeName: String { get }
    
    // Lifecycle (override in subclasses)
    open func awake()
    open func start()
    open func update(deltaTime: Float)
    open func lateUpdate(deltaTime: Float)
    open func fixedUpdate(fixedDeltaTime: Float)
    open func onDestroy()
    open func onEnable()
    open func onDisable()
}
```

### `Transform` (Sendable)
Position, rotation, scale with hierarchy support.
```swift
public final class Transform {
    public var localPosition: Vec3d
    public var localRotation: Quaternion
    public var localScale: Vec3d
    public weak var parent: Transform?
    public var children: [Transform]
    
    // World space properties
    public var position: Vec3d { get set }
    public var rotation: Quaternion { get set }
    public var lossyScale: Vec3d { get }
    
    // Matrices
    public var localMatrix: Mat4d { get }
    public var worldMatrix: Mat4d { get }
    
    // Direction vectors
    public var forward: Vec3d { get }
    public var right: Vec3d { get }
    public var up: Vec3d { get }
    
    // Operations
    public func translate(_ offset: Vec3d, relativeTo space: Space = .local)
    public func rotate(_ rotation: Quaternion, relativeTo space: Space = .local)
    public func lookAt(_ target: Vec3d, worldUp: Vec3d = .unitY)
    public func transformPoint(_ point: Vec3d) -> Vec3d
    public func inverseTransformPoint(_ point: Vec3d) -> Vec3d
}
```

### `Mesh` (Protocol)
```swift
public protocol Mesh: AnyObject, Sendable {
    var vertices: [Vertex] { get }
    var indices: [UInt32] { get }
    var bounds: Bounds { get }
    var triangleCount: Int { get }
}

public struct Vertex {
    public var position: Vec3d
    public var normal: Vec3d
    public var uv: Vec2d
}

public struct Bounds: Sendable {
    public var center: Vec3d
    public var size: Vec3d
    public var min: Vec3d { get }
    public var max: Vec3d { get }
}
```

Built-in meshes: `CubeMesh`, `PlaneMesh`, `QuadMesh`

### `LoadableMesh` (MainActor)
Async mesh loading from OBJ/STL files.
```swift
public final class LoadableMesh: Mesh {
    public enum LoadState { case notLoaded, loading, loaded, failed(String) }
    public var loadState: LoadState
    public let path: String
    
    public func load()
    public func loadAsync() async
}
```

### `Material`
Visual appearance of surfaces.
```swift
public final class Material {
    public var name: String
    public var color: Color
    public var mainTexture: Texture?
    public var renderMode: RenderMode     // .opaque, .transparent, .cutout, .wireframe
    public var cullMode: CullMode         // .back, .front, .none
    public var shadingModel: ShadingModel // .unlit, .flat, .gouraud, .pbr
    public var opacity: Float
    public var roughness: Float
    public var metallic: Float
    public var emissionColor: Color
    
    public static let `default`, unlit, wireframe
    public static func solid(_ color: Color) -> Material
    public static func transparent(_ color: Color, opacity: Float) -> Material
    public static func emissive(_ color: Color, intensity: Float) -> Material
}
```

### `PhysicsMaterial` (Sendable)
Physical surface properties.
```swift
public struct PhysicsMaterial {
    public var friction: Float
    public var bounciness: Float
    public var density: Float
    public var frictionCombine: CombineMode
    public var bounceCombine: CombineMode
    
    public static let `default`, rubber, ice, metal, wood, bouncyBall, stone
}
```

### `Texture`
2D texture with sampling.
```swift
public final class Texture {
    public let width: Int, height: Int
    public var filterMode: TextureFilter  // .point, .bilinear
    public var wrapModeU, wrapModeV: TextureWrap  // .repeat, .clamp, .mirror
    
    public func sample(u: Float, v: Float) -> Color
    public func getPixel(x: Int, y: Int) -> Color
    public func setPixel(x: Int, y: Int, color: Color)
    
    public static let white, black
    public static func checkerboard(size: Int, color1: Color, color2: Color) -> Texture
}
```

---

## Components (`Components/`)

### `Camera` (MainActor)
```swift
public final class Camera: Component {
    public static weak var main: Camera?
    
    public var projection: CameraProjection  // .perspective, .orthographic
    public var fieldOfView: Float
    public var orthographicSize: Float
    public var nearClipPlane: Float
    public var farClipPlane: Float
    public var aspectRatio: Float
    public var backgroundColor: Color
    public var depth: Int
    
    public var projectionMatrix: Mat4d { get }
    public var viewMatrix: Mat4d { get }
    public var viewProjectionMatrix: Mat4d { get }
    public var frustum: Frustum { get }
    
    public func worldToScreenPoint(_ worldPos: Vec3d) -> Vec3d
    public func screenToWorldRay(_ screenPos: Vec2d) -> (origin: Vec3d, direction: Vec3d)
}
```

### `MeshRenderer` (MainActor)
```swift
public final class MeshRenderer: Component {
    public var mesh: (any Mesh)?
    public var material: Material
    public var color: Color
    public var castShadows, receiveShadows: Bool
    public var sortingOrder: Int
    public var isVisible: Bool
    public var worldBounds: Bounds? { get }
}
```

### `RigidBody` (MainActor)
```swift
public final class RigidBody: Component {
    public var mass: Float
    public var isKinematic: Bool
    public var velocity: Vec3d { get }
    public var angularVelocity: Vec3d { get }
    public var angularDrag: Float
    public var maxVelocity: Float
    public var maxAngularVelocity: Float
    
    public func addForce(_ force: Vec3d)
    public func addTorque(_ torque: Vec3d)
    public func addImpulse(_ impulse: Vec3d)
    public func addAngularImpulse(_ impulse: Vec3d)
    public func setVelocity(_ newVelocity: Vec3d)
    public func setAngularVelocity(_ newAngularVelocity: Vec3d)
}
```

### Colliders (MainActor)

**Base class:**
```swift
open class Collider: Component, ColliderProtocol {
    open var colliderType: ColliderType  // .box, .sphere, .plane, .capsule, .mesh, .custom
    public var isTrigger: Bool
    public var center: Vec3d
    public var layer: Int
    public var material: PhysicsMaterial
    public var worldCenter: Vec3d { get }
    open var volume: Float { get }
    open var boundingSphereRadius: Float { get }
    open func intersects(with other: Collider) -> CollisionInfo?
}
```

**Concrete colliders:**
```swift
public final class BoxCollider: Collider {
    public var halfExtents: Vec3d
    public var size: Vec3d { get set }
    public var worldCorners: [Vec3d] { get }
    public var worldMin, worldMax: Vec3d { get }
}

public final class SphereCollider: Collider {
    public var radius: Float
}

public final class PlaneCollider: Collider {
    public var normal: Vec3d
    public var distance: Float
    public var worldNormal: Vec3d { get }
    public var worldPlanePoint: Vec3d { get }
}
```

### `CollisionInfo`
```swift
public struct CollisionInfo {
    public let other: Collider
    public let contactPoint: Vec3d
    public let normal: Vec3d
    public let penetrationDepth: Float
}
```

### `PlayerController` (MainActor)
FPS-style movement controller.
```swift
public final class PlayerController: Component {
    public var moveSpeed: Float
    public var lookSpeed: Float
    public var forwardKey, backwardKey, leftKey, rightKey, upKey, downKey: Key
    public var useArrowKeys: Bool
    public var enableMouseLook: Bool
    public var minPitch, maxPitch: Float
    
    public func setInput(_ input: Input)
}
```

### `UIOverlay` (MainActor)
Screen-space UI component.
```swift
public final class UIOverlay: Component {
    public var uiRoot: UIRoot?
    public var depth: Int
    public var blocksInput: Bool
    public var isVisible: Bool
    public var anchor: Anchor?
    public var size: Size?
    public var padding: EdgeInsets
    public var backgroundColor: Color?
    
    public func setContent(@ViewBuilder _ content: @escaping () -> [any View])
    public func rebuildContent()
}
```

---

## Physics System (`Engine/PhysicsSystem.swift`)

### `PhysicsSystem` (MainActor)
Coordinates physics simulation.
```swift
public final class PhysicsSystem {
    public static let shared: PhysicsSystem
    
    public var isEnabled: Bool
    public var gravity: Vec3d
    public var collisionsThisFrame: Int { get }
    public var stepsThisFrame: Int { get }
    public var bodyCount: Int { get }
    
    public func register(_ rigidBody: RigidBody)
    public func unregister(_ rigidBody: RigidBody)
    public func update(deltaTime: Float)           // Synchronous
    public func updateAsync(deltaTime: Float) async // Async (experimental)
    public func clear()
}
```

### `CollisionManager` (MainActor)
```swift
public final class CollisionManager {
    public static let shared: CollisionManager
    
    public var onCollision: ((Collider, Collider, CollisionInfo) -> Void)?
    public var colliderCount: Int { get }
    public var allColliders: [Collider] { get }
    
    public func register(_ collider: Collider)
    public func unregister(_ collider: Collider)
    public func detectCollisions() -> [(Collider, Collider, CollisionInfo)]
}
```

---

## Actors (`Actors/`)

### `PhysicsActor` (actor)
Off-main-thread physics simulation.
```swift
public actor PhysicsActor {
    public static let shared: PhysicsActor
    
    public var fixedDeltaTime: Float  // Default: 1/60
    public var maxDeltaTime: Float
    public var maxStepsPerFrame: Int
    public var gravity: Vec3d
    public var isEnabled: Bool
    
    public func simulate(input: PhysicsFrameInput) async -> PhysicsStepResult
}
```

### `GameLogicActor` (actor)
Concurrent game logic processing.
```swift
public actor GameLogicActor {
    public static let shared: GameLogicActor
    
    public func registerHandler(for componentType: String, 
        handler: @escaping @Sendable (GameObjectSnapshot, Float) async -> TransformUpdate?)
    public func registerTask(name: String, task: @escaping @Sendable (Float) async -> Void)
    public func processGameObjects(_ snapshots: [GameObjectSnapshot], deltaTime: Float) async -> GameLogicResult
    public func processAIDecisions(entities: [AIEntityState], worldState: WorldStateSnapshot) async -> [GameUUID: AIDecision]
}
```

### `AssetLoadingActor` (actor)
Async asset loading with caching.
```swift
public actor AssetLoadingActor {
    public static let shared: AssetLoadingActor
    
    public func loadMesh(from path: String) async -> AssetLoadResult<MeshData>
    public func loadMeshes(from paths: [String]) async -> [String: AssetLoadResult<MeshData>]
    public func preloadMeshes(from paths: [String]) async
    public func clearMeshCache()
}
```

### `ActorCoordinator` (MainActor)
Coordinates all actors.
```swift
public final class ActorCoordinator {
    public static let shared: ActorCoordinator
    
    public var asyncPhysicsEnabled: Bool
    public var asyncGameLogicEnabled: Bool
    
    public func update(deltaTime: Float, gameObjects: [GameObject]) async
    public func getPhysicsInterpolationAlpha() async -> Float
    public func getPerformanceStats() async -> ActorPerformanceStats
}
```

---

## Scene (`Scene/`)

### `Scene` (Protocol)
```swift
public protocol Scene: AnyObject {
    func onLoad(engine: Engine)
    func onUnload(engine: Engine)
    func onActivate(engine: Engine)
    func onDeactivate(engine: Engine)
    func update(context: FrameContext, input: Input)
    func render(context: RenderContext)
}
```

### `GameObjectScene` (MainActor)
Base class for scenes with GameObjects.
```swift
open class GameObjectScene: Scene {
    public private(set) var gameObjects: [GameObject]
    public private(set) weak var engine: Engine?
    
    public func createGameObject(name: String) -> GameObject
    public func createGameObject(name: String, parent: GameObject) -> GameObject
    public func destroyGameObject(_ gameObject: GameObject)
    public func findGameObject(named: String) -> GameObject?
    public func findGameObjects(withTag: String) -> [GameObject]
    public func getAllMeshRenderers() -> [MeshRenderer]
    
    // Override these
    open func setupScene() {}
    open func updateScene(context: FrameContext, input: Input) {}
    open func renderScene(context: RenderContext, camera: Camera) {}
}
```

### Lighting

```swift
// Ambient Light
public final class AmbientLight: Component {
    public static var current: AmbientLight?
    public var intensity: Float  // 0-1
    public var color: Color
    public static var effectiveIntensity: Float { get }
}

// Directional Light
public final class DirectionalLight: Component {
    public static var main: DirectionalLight?
    public static var all: [DirectionalLight]
    
    public var direction: Vec3d
    public var color: Color
    public var intensity: Float
    public var castsShadows: Bool
    
    public func calculateLighting(normal: Vec3d) -> Float
}
```

---

## Graphics (`Graphics/`)

### Vector Types
```swift
public struct Vec2d: Sendable {
    public var x, y: Float
    public static let zero, one
    public var length, squaredLength: Float
    public var normalized: Vec2d
    public func dot(_ other: Vec2d) -> Float
    public func lerp(to other: Vec2d, t: Float) -> Vec2d
}

public struct Vec3d: Sendable {
    public var x, y, z: Float
    public static let zero, one, unitX, unitY, unitZ, right, up, forward
    public var length, squaredLength: Float
    public var normalized: Vec3d
    public func dot(_ other: Vec3d) -> Float
    public func cross(_ other: Vec3d) -> Vec3d
    public func lerp(to other: Vec3d, t: Float) -> Vec3d
    public func reflect(normal: Vec3d) -> Vec3d
    public func distance(to other: Vec3d) -> Float
}

public struct Vec4d: Sendable {
    public var x, y, z, w: Float
}
```

### `Quaternion` (Sendable)
```swift
public struct Quaternion {
    public var x, y, z, w: Float
    public static let identity
    
    public var inverse: Quaternion { get }
    public var normalized: Quaternion { get }
    public var toMat4d: Mat4d { get }
    public var eulerAngles: Vec3d { get }
    
    public static func fromAxisAngle(axis: Vec3d, angle: Float) -> Quaternion
    public static func fromEuler(pitch: Float, yaw: Float, roll: Float) -> Quaternion
    public static func lookRotation(forward: Vec3d, up: Vec3d) -> Quaternion
    public static func slerp(_ a: Quaternion, _ b: Quaternion, t: Float) -> Quaternion
    
    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion
    public static func * (lhs: Quaternion, rhs: Vec3d) -> Vec3d  // Rotate vector
}
```

### `Mat4d` (Sendable)
4x4 transformation matrix.
```swift
public struct Mat4d {
    public static let identity
    
    public var inverse: Mat4d? { get }
    public var transposed: Mat4d { get }
    public var determinant: Float { get }
    
    public static func translate(vec: Vec3d) -> Mat4d
    public static func scale(sx: Float, sy: Float, sz: Float) -> Mat4d
    public static func rotateX/Y/Z(angle: Float) -> Mat4d
    public static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> Mat4d
    public static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> Mat4d
    public static func lookAt(eye: Vec3d, target: Vec3d, up: Vec3d) -> Mat4d
    
    public func transformPoint(_ point: Vec3d) -> Vec3d
    public func transformDirection(_ direction: Vec3d) -> Vec3d
}
```

### `Color` (Sendable)
```swift
public struct Color {
    public let argb: UInt32
    public var r, g, b, a: UInt8 { get }
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255)
    public func withAlpha(_ a: UInt8) -> Color
    public func scaled(by factor: Float) -> Color
    public func lighter(by amount: Float) -> Color
    public func darker(by amount: Float) -> Color
    public func lerp(to other: Color, t: Float) -> Color
    
    public static let black, white, red, green, blue, yellow, cyan, magenta
    public static let transparent, clear
    public static let darkGray, gray, lightGray
    public static let orange, purple, pink
    public static let cornflowerBlue, steelBlue
}
```

### `RenderPipeline` (MainActor)
3D rendering with lighting.
```swift
public final class RenderPipeline {
    public static let shared: RenderPipeline
    
    public func render(meshRenderers: [MeshRenderer], camera: Camera, context: RenderContext)
}
```

---

## Platform Abstraction Layer (`Platform/`)

### Architecture Overview

The platform layer uses a **separate compilation unit** approach for optimal performance:

1. **Platform Modules** (`Sources/WindowsPlatform/`, future: `Sources/MacOSPlatform/`, etc.)
   - Each platform has its own Swift module with concrete types
   - Types use generic names (e.g., `Backbuffer`, not `WindowsBackbuffer`)
   - No protocol overhead - direct concrete type usage

2. **PlatformInterface** (`Sources/GameEngine/Platform/PlatformInterface.swift`)
   - Central access point using `#if os(...)` for compile-time platform selection
   - Provides type aliases and factory methods
   - Engine code uses this interface exclusively

This design achieves:
- **Clean API**: End-users see platform-agnostic types
- **High Performance**: No protocol existential overhead (concrete types)
- **Easy Extension**: Add new platforms by creating modules and extending `PlatformInterface`

### `PlatformInterface` (MainActor)

The unified interface for all platform-specific functionality:

```swift
@MainActor
public enum PlatformInterface {
    // Factory methods
    public static func createWindow() -> PlatformWindow
    public static func createBackbuffer() -> PlatformBackbuffer
    public static func createTimer() -> PlatformTimer
    public static func createKeyCodeTranslator() -> PlatformKeyCodeTranslator
    
    // Utilities
    public static func exitProcess(_ code: Int32) -> Never
    public static func translateKeyCode(_ vk: Int32) -> Key?
    public static func mouseButtonFromPlatformIndex(_ index: Int32) -> MouseButton?
}
```

### Type Aliases

`PlatformInterface` provides type aliases that resolve to concrete platform types:

```swift
#if os(Windows)
public typealias PlatformWindow = WindowsPlatform.Window
public typealias PlatformBackbuffer = WindowsPlatform.Backbuffer
public typealias PlatformTimer = WindowsPlatform.Timer
public typealias PlatformKeyCodeTranslator = WindowsPlatform.KeyCodeTranslator
public typealias PlatformVirtualKey = WindowsPlatform.VirtualKey
public typealias PlatformMouseButtonIndex = WindowsPlatform.MouseButtonIndex
#endif
```

### `SharedTimer` (Sendable)

For timing in non-MainActor contexts (actors, async code):

```swift
/// Global shared timer instance
public let sharedTimer = SharedTimer()

public struct SharedTimer: Sendable {
    public func currentTimeMillis() -> UInt64
    public func sleep(milliseconds: UInt32)
}
```

### Platform Module Types (WindowsPlatform)

Each platform module provides these concrete types with generic names:

#### `Backbuffer` (MainActor)
Software rendering backbuffer.
```swift
public final class Backbuffer {
    public var width: Int32 { get }
    public var height: Int32 { get }
    public var pixels: UnsafeMutablePointer<UInt32>? { get }
    public var pixelCount: Int { get }
    
    public func resize(width: Int32, height: Int32)
}
```

#### `Window` (MainActor)
Native window management.
```swift
public final class Window {
    public var width: Int32 { get }
    public var height: Int32 { get }
    public var shouldClose: Bool { get }
    public var isMouseCaptured: Bool { get }
    
    public func create(title: String, width: Int32, height: Int32) -> Bool
    public func pollEvents()
    public func present()
    public func setTitle(_ title: String)
    public func captureMouse()
    public func releaseMouse()
    
    // Callbacks
    public var onResize: ((Int32, Int32) -> Void)?
    public var onClose: (() -> Void)?
    public var onKeyEvent: ((Int32, Bool) -> Void)?
    public var onMouseMove: ((Int32, Int32) -> Void)?
    public var onMouseButton: ((Int32, Bool) -> Void)?
}
```

#### `Timer` (Sendable)
High-precision timing.
```swift
public struct Timer: Sendable {
    public func currentTimeMillis() -> UInt64
    public func sleep(milliseconds: UInt32)
}
```

### Adding a New Platform

To add support for a new platform (e.g., macOS):

1. Create `Sources/MacOSPlatform/` with:
   - `Backbuffer.swift` - Core Graphics/Metal backbuffer
   - `Window.swift` - NSWindow wrapper
   - `Timer.swift` - mach_absolute_time wrapper
   - `KeyCodeTranslator.swift` - NSEvent key codes
   - `Platform.swift` - Platform utilities

2. Update `Package.swift` to add the new target

3. Extend `PlatformInterface.swift` with `#elseif os(macOS)` cases

---

### `Input` (MainActor)
```swift
public final class Input {
    public var isMouseCaptured: Bool { get }
    public var mouseDeltaX, mouseDeltaY: Int32 { get }
    
    public func isKeyDown(_ key: Key) -> Bool
    public func isKeyUp(_ key: Key) -> Bool
    public func isKeyPressed(_ key: Key) -> Bool   // Just pressed this frame
    public func isKeyReleased(_ key: Key) -> Bool  // Just released this frame
    
    public func getMousePosition() -> (x: Int32, y: Int32)
    public func getMouseDelta() -> (x: Int32, y: Int32)
    public func isMouseButtonDown(_ button: MouseButton) -> Bool
    public func isMouseButtonPressed(_ button: MouseButton) -> Bool
    public func isMouseButtonReleased(_ button: MouseButton) -> Bool
}
```

### `Key` (enum)
```swift
public enum Key: CaseIterable, Sendable {
    case left, right, up, down
    case escape, space, enter, tab, backspace, delete
    case shift, control, alt
    case a, b, c, ... z
    case num0, num1, ... num9
    case f1, f2, ... f12
}
```

### `MouseButton` (enum)
```swift
public enum MouseButton: CaseIterable, Sendable {
    case left, right, middle
}
```

### `Window` (MainActor)
Win32 window management (internal).

### `Renderer` (MainActor)
Low-level rendering (clear, present, etc.).

### `Primitives` (static)
2D drawing primitives (lines, triangles, rectangles).

---

## Context Types

```swift
// Passed to scene update()
public struct FrameContext: Sendable {
    public let deltaTime: Double
    public let totalTime: Double
    public let frameCount: UInt64
    public let fps: Double
}

// Passed to scene render()
public struct RenderContext {
    public let renderer: Renderer
    public var width: Int32 { get }
    public var height: Int32 { get }
    public var bounds: Rect { get }
}
```

---

## Physics Data Types (Sendable)

```swift
public struct PhysicsBodyState {
    public let id: GameUUID
    public var position: Vec3d
    public var velocity: Vec3d
    public var rotation: Quaternion
    public var angularVelocity: Vec3d
    public let mass: Float
    public let isKinematic: Bool
}

public struct ColliderSnapshot {
    public enum ColliderType {
        case box(halfExtents: Vec3d)
        case sphere(radius: Float)
        case plane(normal: Vec3d, offset: Float)
    }
    public let bodyId: GameUUID
    public let type: ColliderType
    public let worldCenter: Vec3d
    public let isTrigger: Bool
    public let material: PhysicsMaterial
}

public struct CollisionPair {
    public let bodyIdA, bodyIdB: GameUUID
    public let contactPoint: Vec3d
    public let normal: Vec3d
    public let penetrationDepth: Float
}

public struct PhysicsFrameInput {
    public let bodies: [GameUUID: PhysicsBodyState]
    public let colliders: [ColliderSnapshot]
    public let deltaTime: Float
}

public struct PhysicsStepResult {
    public let updatedBodies: [GameUUID: PhysicsBodyState]
    public let collisions: [CollisionPair]
    public let simulatedTime: Float
    public let stepsExecuted: Int
}
```

---

## UI System (SwiftUI-style)

### Core Views
- `Text`, `Label`
- `Button`, `Checkbox`, `Slider`, `ProgressBar`
- `VStack`, `HStack`, `ZStack`, `Spacer`
- `Panel`, `ScrollView`

### Modifiers
- `.padding()`, `.frame()`, `.background()`
- `.foregroundColor()`, `.font()`
- `.border()`, `.cornerRadius()`

### State Management
- `@UIState` property wrapper
- `UIBinding<T>` for two-way data binding

---

## Debug Tools

### `DebugDraw` (MainActor)
```swift
public final class DebugDraw {
    public static let shared: DebugDraw
    
    public var isEnabled: Bool
    public var showColliders: Bool
    public var showAABB: Bool
    public var boxColliderColor, sphereColliderColor, planeColliderColor: Color
    
    public func draw(context: RenderContext, camera: Camera)
    public func draw3DLine(from: Vec3d, to: Vec3d, color: Color, context: RenderContext, camera: Camera)
    public func draw3DPoint(_ point: Vec3d, color: Color, size: Float, context: RenderContext, camera: Camera)
}
```

---

## Type Aliases

```swift
public typealias GameUUID = Foundation.UUID  // Disambiguates from WinSDK GUID
```

---

## Typical Usage

```swift
// App entry point
@main
@MainActor
struct Main {
    static func main() async {
        // No platform initialization needed - handled automatically via PlatformInterface
        let config = EngineConfig(title: "My Game", width: 1024, height: 768)
        let engine = Engine(config: config)
        engine.loadScene(MyScene())
        await engine.run()
    }
}

// Scene definition
class MyScene: GameObjectScene {
    override func setupScene() {
        // Create camera
        let cameraObj = createGameObject(name: "Camera")
        cameraObj.transform.position = Vec3d(0, 5, 10)
        let camera = cameraObj.addComponent(Camera.self)
        camera.setAsMain()
        
        // Create lit cube with physics
        let cube = createGameObject(name: "Cube")
        cube.transform.position = Vec3d(0, 5, 0)
        cube.addComponent(MeshRenderer(mesh: CubeMesh.shared, color: .red))
        cube.addComponent(BoxCollider(size: Vec3d(1, 1, 1)))
        cube.addComponent(RigidBody(mass: 1.0))
        
        // Create floor
        let floor = createGameObject(name: "Floor")
        floor.addComponent(MeshRenderer(mesh: PlaneMesh(width: 20, depth: 20), color: .gray))
        floor.addComponent(PlaneCollider())
        floor.addComponent(RigidBody(mass: 1.0, isKinematic: true))
        
        // Add lights
        let lightObj = createGameObject(name: "Light")
        lightObj.addComponent(DirectionalLight(direction: Vec3d(0.5, 1, 0.3)))
        lightObj.addComponent(AmbientLight(intensity: 0.2))
    }
}
```

---

## Known Issues / TODOs

1. **Window close in debug mode**: Process may not terminate cleanly in debug builds; works correctly in release.
2. **Async physics**: Currently using synchronous physics due to interaction with Win32 message pump; async version available but experimental.
3. **UI System**: Full documentation pending for Text/, State/, Containers/, Controls/, Views/ subdirectories.
4. **Platform Support**: Currently only Windows is implemented. macOS and Linux support planned for future releases.

---

## Platform Support Status

| Platform | Status | Module |
|----------|--------|--------|
| Windows  | ✅ Fully supported | `WindowsPlatform` |
| macOS    | 🔲 Planned | `MacOSPlatform` |
| Linux    | 🔲 Planned | `LinuxPlatform` |

### Performance Notes

The platform abstraction uses **concrete types** (not protocol existentials) to ensure zero overhead:
- Direct function calls instead of witness table lookups
- Compiler can inline platform-specific code
- No `any` protocol boxing overhead

This architecture was chosen after benchmarking showed ~50% FPS regression with protocol existentials in hot paths.