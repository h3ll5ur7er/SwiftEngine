import Foundation

/// A mesh that can be loaded asynchronously from a file
@MainActor
public final class LoadableMesh: @preconcurrency Mesh {
    
    /// Loading state
    public enum LoadState: Sendable {
        case notLoaded
        case loading
        case loaded
        case failed(String)
    }
    
    /// Current load state
    public private(set) var loadState: LoadState = .notLoaded
    
    /// The file path to load from
    public let path: String
    
    /// The loaded vertices (empty until loaded)
    public private(set) var vertices: [Vertex] = []
    
    /// The loaded indices (empty until loaded)
    public private(set) var indices: [UInt32] = []
    
    /// The bounds (default until loaded)
    public private(set) var bounds: Bounds = Bounds()
    
    /// Callback when loading completes
    public var onLoaded: (() -> Void)?
    
    /// Callback when loading fails
    public var onFailed: ((String) -> Void)?
    
    /// Create a loadable mesh from a file path
    public init(path: String) {
        self.path = path
    }
    
    /// Start loading the mesh asynchronously
    public func load() {
        guard case .notLoaded = loadState else { return }
        loadState = .loading
        
        Task {
            let result = await AssetLoadingActor.shared.loadMesh(from: path)
            await MainActor.run {
                self.handleLoadResult(result)
            }
        }
    }
    
    /// Load the mesh and wait for completion
    public func loadAsync() async {
        guard case .notLoaded = loadState else { return }
        loadState = .loading
        
        let result = await AssetLoadingActor.shared.loadMesh(from: path)
        handleLoadResult(result)
    }
    
    private func handleLoadResult(_ result: AssetLoadResult<MeshData>) {
        switch result {
        case .success(let data):
            // Convert MeshData to engine Vertex format
            vertices = data.vertices.map { v in
                Vertex(position: v.position, normal: v.normal, uv: v.uv)
            }
            indices = data.indices
            bounds = Bounds(center: data.bounds.center, size: data.bounds.size)
            loadState = .loaded
            onLoaded?()
            
        case .failure(let error):
            let message: String
            switch error {
            case .fileNotFound(let path):
                message = "File not found: \(path)"
            case .invalidFormat(let format):
                message = "Invalid format: \(format)"
            case .decodingFailed(let reason):
                message = "Decoding failed: \(reason)"
            case .cancelled:
                message = "Loading cancelled"
            }
            loadState = .failed(message)
            onFailed?(message)
        }
    }
    
    /// Whether the mesh is ready to render
    public var isLoaded: Bool {
        if case .loaded = loadState { return true }
        return false
    }
}

/// Extension to preload multiple meshes
extension LoadableMesh {
    /// Preload multiple meshes from paths
    @MainActor
    public static func preloadAll(_ paths: [String]) async -> [String: LoadableMesh] {
        await AssetLoadingActor.shared.preloadMeshes(from: paths)
        
        var meshes: [String: LoadableMesh] = [:]
        for path in paths {
            let mesh = LoadableMesh(path: path)
            await mesh.loadAsync()
            meshes[path] = mesh
        }
        return meshes
    }
}
