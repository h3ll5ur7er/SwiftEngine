# Asset Loading

GameEngine supports loading external assets like meshes and textures asynchronously.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Asset Loading System                                 │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  AssetLoadingActor (dedicated thread)                                │   │
│   │                                                                      │   │
│   │  loadMesh(from: path)      ──▶  Parse file                         │   │
│   │                            ──▶  Build vertex data                   │   │
│   │                            ──▶  Calculate bounds                    │   │
│   │                            ──▶  Return Mesh                         │   │
│   │                                                                      │   │
│   │  loadTexture(from: path)   ──▶  Read image file                    │   │
│   │                            ──▶  Decode pixels                       │   │
│   │                            ──▶  Return Texture                      │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   Benefits:                                                                  │
│   • Non-blocking - main thread stays responsive                             │
│   • Progress tracking - monitor load progress                               │
│   • Concurrent - load multiple assets in parallel                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## LoadableMesh Protocol

For meshes that can be loaded from files:

```swift
public protocol LoadableMesh: Mesh {
    /// Load mesh from file at path
    static func load(from path: String) async throws -> Self
    
    /// Load with progress callback
    static func load(from path: String, progress: @escaping (Float) -> Void) async throws -> Self
}
```

---

## Loading Meshes

### Basic Loading

```swift
// Load mesh asynchronously
do {
    let mesh = try await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")
    
    let renderer = gameObject.addComponent(MeshRenderer.self)
    renderer.mesh = mesh
} catch {
    print("Failed to load mesh: \(error)")
}
```

### With Progress Tracking

```swift
let mesh = try await AssetLoadingActor.shared.loadMesh(from: "models/large-world.obj") { progress in
    // progress is 0.0 to 1.0
    print("Loading: \(Int(progress * 100))%")
    updateLoadingBar(progress)
}
```

### Loading Multiple Assets

```swift
// Load concurrently using async let
async let mesh1 = AssetLoadingActor.shared.loadMesh(from: "models/player.obj")
async let mesh2 = AssetLoadingActor.shared.loadMesh(from: "models/enemy.obj")
async let mesh3 = AssetLoadingActor.shared.loadMesh(from: "models/props.obj")

// Wait for all to complete
let (playerMesh, enemyMesh, propsMesh) = try await (mesh1, mesh2, mesh3)
```

---

## Loading in Scenes

### Scene Setup

```swift
@MainActor
public final class GameScene: GameObjectScene {
    public override func setup() async {
        // Show loading indicator
        showLoadingScreen()
        
        // Load all required assets
        let characterMesh = try? await AssetLoadingActor.shared.loadMesh(
            from: "models/character.obj"
        )
        
        let environmentMesh = try? await AssetLoadingActor.shared.loadMesh(
            from: "models/environment.obj"
        )
        
        // Create game objects with loaded meshes
        if let mesh = characterMesh {
            let player = createGameObject(name: "Player")
            let renderer = player.addComponent(MeshRenderer.self)
            renderer.mesh = mesh
        }
        
        if let mesh = environmentMesh {
            let environment = createGameObject(name: "Environment")
            let renderer = environment.addComponent(MeshRenderer.self)
            renderer.mesh = mesh
        }
        
        // Hide loading indicator
        hideLoadingScreen()
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
    
    public override func setup() async {
        // Setup loading UI
        setupLoadingUI()
        
        // Define assets to load
        let assetPaths = [
            "models/player.obj",
            "models/enemy.obj",
            "models/world.obj",
            "models/props.obj"
        ]
        totalAssets = assetPaths.count
        
        // Load each asset
        var loadedMeshes: [String: Mesh] = [:]
        
        for path in assetPaths {
            do {
                let mesh = try await AssetLoadingActor.shared.loadMesh(from: path)
                loadedMeshes[path] = mesh
                loadedAssets += 1
                updateProgress()
            } catch {
                print("Failed to load \(path): \(error)")
            }
        }
        
        // Transition to game scene with loaded assets
        let gameScene = GameScene(preloadedMeshes: loadedMeshes)
        engine?.loadScene(gameScene)
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
| Custom | `.mesh` | ✅ Supported |

### OBJ File Support

```swift
// OBJ files support:
// - Vertices (v)
// - Texture coordinates (vt)
// - Normals (vn)
// - Faces (f) with vertex/uv/normal indices

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

```swift
// Load texture
let texture = try await AssetLoadingActor.shared.loadTexture(from: "textures/diffuse.bmp")

// Apply to material
material.mainTexture = texture
```

### Supported Texture Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| BMP | `.bmp` | Uncompressed bitmap |

---

## Error Handling

```swift
do {
    let mesh = try await AssetLoadingActor.shared.loadMesh(from: "models/character.obj")
    renderer.mesh = mesh
} catch AssetLoadError.fileNotFound(let path) {
    print("File not found: \(path)")
    renderer.mesh = CubeMesh.shared  // Fallback
} catch AssetLoadError.parseError(let message) {
    print("Parse error: \(message)")
    renderer.mesh = CubeMesh.shared  // Fallback
} catch {
    print("Unknown error: \(error)")
    renderer.mesh = CubeMesh.shared  // Fallback
}
```

### Error Types

```swift
public enum AssetLoadError: Error {
    case fileNotFound(String)
    case parseError(String)
    case invalidFormat(String)
    case ioError(Error)
}
```

---

## Built-in Primitive Meshes

For simple shapes, use built-in primitives instead of loading:

```swift
// No loading needed - instant
renderer.mesh = CubeMesh.shared
renderer.mesh = SphereMesh.shared
renderer.mesh = PlaneMesh(width: 10, depth: 10)
renderer.mesh = CylinderMesh(radius: 0.5, height: 2)
renderer.mesh = ConeMesh(radius: 0.5, height: 1)
```

See [Built-in Meshes](meshes.md) for more details.

---

## Best Practices

1. **Load during scene setup** - Use `async setup()` for loading
2. **Show progress** - Give feedback during long loads
3. **Handle errors gracefully** - Provide fallback meshes
4. **Load concurrently** - Use `async let` for parallel loading
5. **Preload common assets** - Load shared assets once, reuse
6. **Use built-in meshes** for simple shapes - Avoid unnecessary file I/O

```swift
// Good - preload and share
class AssetCache {
    static var characterMesh: Mesh?
    
    static func preload() async {
        characterMesh = try? await AssetLoadingActor.shared.loadMesh(
            from: "models/character.obj"
        )
    }
}

// Usage
renderer.mesh = AssetCache.characterMesh ?? CubeMesh.shared
```
