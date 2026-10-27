# Asset Loading

GameEngine supports loading external meshes (OBJ and binary STL) asynchronously. BMP images can be loaded into a `Texture` synchronously, but the 3D renderer doesn't sample textures yet.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Asset Loading System                                 │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  AssetLoadingActor (Swift actor)                                     │   │
│   │                                                                      │   │
│   │  loadMesh(from: path)      ──▶  Check cache                         │   │
│   │                            ──▶  Parse file (.obj / .stl)            │   │
│   │                            ──▶  Build vertex data + bounds          │   │
│   │                            ──▶  Return AssetLoadResult<MeshData>    │   │
│   │                                                                      │   │
│   │  loadMeshes(from: paths)   ──▶  [path: AssetLoadResult<MeshData>]   │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   Benefits:                                                                  │
│   • Non-blocking - parsing runs off the main actor                          │
│   • Cached - loading the same path again returns the cached data            │
│   • Batch - loadMeshes(from:) loads a list of paths in one call             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## LoadableMesh

`AssetLoadingActor` returns plain `MeshData`, which is not a `Mesh`. `LoadableMesh` is a `Mesh` class that loads its file through the actor, so you can assign it to a `MeshRenderer` right away (it renders nothing until loaded):

```swift
@MainActor
public final class LoadableMesh: Mesh {
    public enum LoadState { case notLoaded, loading, loaded, failed(String) }
    
    public let path: String
    public private(set) var loadState: LoadState
    public var isLoaded: Bool { get }
    
    public var onLoaded: (() -> Void)?
    public var onFailed: ((String) -> Void)?
    
    public init(path: String)
    
    /// Start loading in a Task and return immediately
    public func load()
    
    /// Load and wait for completion
    public func loadAsync() async
    
    /// Load several meshes; returns one LoadableMesh per path
    public static func preloadAll(_ paths: [String]) async -> [String: LoadableMesh]
}
```

---

## Loading Meshes

### Basic Loading

```swift
// LoadableMesh - assign now, loads in the background
let mesh = LoadableMesh(path: "models/character.obj")

let renderer = gameObject.addComponent(MeshRenderer.self)
renderer.mesh = mesh
mesh.load()

// Or get the raw mesh data (non-throwing)
let result = await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")
if case .failure(let error) = result {
    print("Failed to load mesh: \(error)")
}
```

### Completion Callbacks

There is no per-file progress reporting; use the callbacks or `loadState` to react when a load finishes:

```swift
mesh.onLoaded = { print("Loaded \(mesh.triangleCount) triangles") }
mesh.onFailed = { message in print("Failed: \(message)") }
```

### Loading Multiple Assets

```swift
// Load several files and get renderable meshes back
let meshes = await LoadableMesh.preloadAll([
    "models/player.obj",
    "models/enemy.obj",
    "models/props.obj"
])
let playerMesh = meshes["models/player.obj"]  // check isLoaded before relying on it

// Or get raw mesh data for each path
let results = await AssetLoadingActor.shared.loadMeshes(from: [
    "models/player.obj", "models/enemy.obj", "models/props.obj"
])  // [String: AssetLoadResult<MeshData>]
```

---

## Loading in Scenes

### Scene Setup

```swift
@MainActor
public final class GameScene: GameObjectScene {
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Show loading indicator
        showLoadingScreen()
        
        Task {
            // Load all required assets
            let meshes = await LoadableMesh.preloadAll([
                "models/character.obj",
                "models/environment.obj"
            ])
            
            // Create game objects with loaded meshes
            if let mesh = meshes["models/character.obj"], mesh.isLoaded {
                let player = createGameObject(name: "Player")
                let renderer = player.addComponent(MeshRenderer.self)
                renderer.mesh = mesh
            }
            
            if let mesh = meshes["models/environment.obj"], mesh.isLoaded {
                let environment = createGameObject(name: "Environment")
                let renderer = environment.addComponent(MeshRenderer.self)
                renderer.mesh = mesh
            }
            
            // Hide loading indicator
            hideLoadingScreen()
        }
    }
}
```

### Loading Screen Pattern

```swift
@MainActor
public final class LoadingScene: GameObjectScene {
    private var loadingProgress: Float = 0
    private var totalAssets: Int = 0
    private var loadedAssets: Int = 0
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Setup loading UI
        setupLoadingUI()
        
        Task {
            // Define assets to load
            let assetPaths = [
                "models/player.obj",
                "models/enemy.obj",
                "models/world.obj",
                "models/props.obj"
            ]
            totalAssets = assetPaths.count
            
            // Load each asset (progress is counted per asset)
            var loadedMeshes: [String: LoadableMesh] = [:]
            
            for path in assetPaths {
                let mesh = LoadableMesh(path: path)
                await mesh.loadAsync()
                if case .failed(let message) = mesh.loadState {
                    print("Failed to load \(path): \(message)")
                } else {
                    loadedMeshes[path] = mesh
                }
                loadedAssets += 1
                updateProgress()
            }
            
            // Transition to game scene with loaded assets
            let gameScene = GameScene(preloadedMeshes: loadedMeshes)
            self.engine?.loadScene(gameScene)
        }
    }
    
    private func updateProgress() {
        loadingProgress = Float(loadedAssets) / Float(totalAssets)
        // Update UI with progress
    }
}
```

---

## Supported Formats

### Mesh Formats

| Format | Extension | Status |
|--------|-----------|--------|
| OBJ | `.obj` | ✅ Supported |
| STL (binary) | `.stl` | ✅ Supported |

Any other extension fails with `AssetLoadError.invalidFormat`.

### OBJ File Support

```swift
// OBJ files support:
// - Vertices (v)
// - Texture coordinates (vt)
// - Normals (vn)
// - Faces (f) with vertex/uv/normal indices (polygons are fan-triangulated)

// Example OBJ content:
// v 0.0 0.0 0.0
// v 1.0 0.0 0.0
// v 0.5 1.0 0.0
// vn 0.0 0.0 1.0
// f 1//1 2//1 3//1
```

---

## Texture Loading

### Basic Texture Loading

There is no asynchronous texture loader. `BMPLoader` loads a BMP synchronously and returns `nil` on failure:

```swift
// Load texture
if let texture = BMPLoader.load(from: "textures/diffuse.bmp") {
    // Stored on the material, but the 3D renderer doesn't sample textures yet
    material.mainTexture = texture
}
```

### Supported Texture Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| BMP | `.bmp` | Uncompressed 24-bit or 32-bit bitmap |

---

## Error Handling

Asset loading never throws. `AssetLoadingActor.loadMesh(from:)` returns an `AssetLoadResult`:

```swift
let result = await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")
switch result {
case .success(let data):
    print("Loaded \(data.triangleCount) triangles")
case .failure(.fileNotFound(let path)):
    print("File not found: \(path)")
case .failure(.invalidFormat(let message)), .failure(.decodingFailed(let message)):
    print("Could not load: \(message)")
case .failure(.cancelled):
    print("Loading cancelled")
}
```

`LoadableMesh` reports the same failures as a message in `loadState` / `onFailed`:

```swift
let mesh = LoadableMesh(path: "models/character.obj")
await mesh.loadAsync()
if mesh.isLoaded {
    renderer.mesh = mesh
} else {
    renderer.mesh = CubeMesh.shared  // Fallback
}
```

### Error Types

```swift
public enum AssetLoadError: Error, Sendable {
    case fileNotFound(String)    // Missing or unreadable file
    case invalidFormat(String)   // Unsupported file extension
    case decodingFailed(String)  // File contents couldn't be parsed
    case cancelled
}
```

---

## Built-in Primitive Meshes

For simple shapes, use built-in primitives instead of loading:

```swift
// No loading needed - instant
renderer.mesh = CubeMesh.shared
renderer.mesh = PlaneMesh(width: 10, depth: 10)
renderer.mesh = QuadMesh(width: 2, height: 3)
```

See [Built-in Meshes](meshes.md) for more details.

---

## Best Practices

1. **Start loading in `onLoad`** - Call `LoadableMesh.load()`, or `await` loads inside a `Task`
2. **Show feedback** - Count completed assets (there is no per-file progress)
3. **Handle errors gracefully** - Provide fallback meshes
4. **Batch loads** - Use `loadMeshes(from:)` or `LoadableMesh.preloadAll`
5. **Preload common assets** - Load shared assets once, reuse (the actor also caches by path)
6. **Use built-in meshes** for simple shapes - Avoid unnecessary file I/O

```swift
// Good - preload and share
@MainActor
class AssetCache {
    static var characterMesh: LoadableMesh?
    
    static func preload() async {
        let mesh = LoadableMesh(path: "models/character.obj")
        await mesh.loadAsync()
        characterMesh = mesh.isLoaded ? mesh : nil
    }
}

// Usage
renderer.mesh = AssetCache.characterMesh ?? CubeMesh.shared
```
