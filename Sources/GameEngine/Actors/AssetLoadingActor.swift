import Foundation

/// Result of an async asset load operation
public enum AssetLoadResult<T: Sendable>: Sendable {
    case success(T)
    case failure(AssetLoadError)
}

/// Errors that can occur during asset loading
public enum AssetLoadError: Error, Sendable {
    case fileNotFound(String)
    case invalidFormat(String)
    case decodingFailed(String)
    case cancelled
}

/// Actor responsible for loading assets asynchronously
/// This keeps the main thread free for rendering while loading resources
public actor AssetLoadingActor {
    
    /// Shared instance for convenience
    public static let shared = AssetLoadingActor()
    
    /// Cache of loaded mesh data (keyed by path)
    private var meshCache: [String: MeshData] = [:]
    
    /// Pending load operations
    private var pendingLoads: Set<String> = []
    
    /// Initialize the asset loading actor
    public init() {}
    
    // MARK: - Mesh Loading
    
    /// Load mesh data asynchronously from a file path
    public func loadMesh(from path: String) async -> AssetLoadResult<MeshData> {
        // Check cache first
        if let cached = meshCache[path] {
            return .success(cached)
        }
        
        // Check if already loading
        if pendingLoads.contains(path) {
            // Wait a bit and try again (simple retry for concurrent requests)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return await loadMesh(from: path)
        }
        
        pendingLoads.insert(path)
        defer { pendingLoads.remove(path) }
        
        // Perform the actual loading
        do {
            let meshData = try await performMeshLoad(from: path)
            meshCache[path] = meshData
            return .success(meshData)
        } catch let error as AssetLoadError {
            return .failure(error)
        } catch {
            return .failure(.decodingFailed(error.localizedDescription))
        }
    }
    
    /// Load multiple meshes concurrently
    public func loadMeshes(from paths: [String]) async -> [String: AssetLoadResult<MeshData>] {
        await withTaskGroup(of: (String, AssetLoadResult<MeshData>).self) { group in
            for path in paths {
                group.addTask {
                    let result = await self.loadMesh(from: path)
                    return (path, result)
                }
            }
            
            var results: [String: AssetLoadResult<MeshData>] = [:]
            for await (path, result) in group {
                results[path] = result
            }
            return results
        }
    }
    
    /// Preload meshes into cache without returning them
    public func preloadMeshes(from paths: [String]) async {
        _ = await loadMeshes(from: paths)
    }
    
    /// Clear the mesh cache
    public func clearMeshCache() {
        meshCache.removeAll()
    }
    
    /// Remove a specific mesh from cache
    public func evictMesh(path: String) {
        meshCache.removeValue(forKey: path)
    }
    
    /// Get cache statistics
    public func getCacheStats() -> (count: Int, paths: [String]) {
        (meshCache.count, Array(meshCache.keys))
    }
    
    // MARK: - Private Loading Implementation
    
    private func performMeshLoad(from path: String) async throws -> MeshData {
        // Check if file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            throw AssetLoadError.fileNotFound(path)
        }
        
        // Read file data
        guard let fileData = fileManager.contents(atPath: path) else {
            throw AssetLoadError.fileNotFound(path)
        }
        
        // Determine format from extension
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "obj":
            return try parseOBJ(data: fileData)
        case "stl":
            return try parseSTL(data: fileData)
        default:
            throw AssetLoadError.invalidFormat("Unsupported format: \(ext)")
        }
    }
    
    // MARK: - OBJ Parser
    
    private func parseOBJ(data: Data) throws -> MeshData {
        guard let content = String(data: data, encoding: .utf8) else {
            throw AssetLoadError.decodingFailed("Failed to decode OBJ as UTF-8")
        }
        
        var positions: [Vec3d] = []
        var normals: [Vec3d] = []
        var uvs: [Vec2d] = []
        var vertices: [MeshData.Vertex] = []
        var indices: [UInt32] = []
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            guard !parts.isEmpty else { continue }
            
            switch parts[0] {
            case "v" where parts.count >= 4:
                // Vertex position
                if let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]) {
                    positions.append(Vec3d(x, y, z))
                }
                
            case "vn" where parts.count >= 4:
                // Vertex normal
                if let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]) {
                    normals.append(Vec3d(x, y, z))
                }
                
            case "vt" where parts.count >= 3:
                // Texture coordinate
                if let u = Float(parts[1]), let v = Float(parts[2]) {
                    uvs.append(Vec2d(u, v))
                }
                
            case "f" where parts.count >= 4:
                // Face (triangulate if needed)
                var faceIndices: [(pos: Int, uv: Int?, normal: Int?)] = []
                
                for i in 1..<parts.count {
                    let components = parts[i].components(separatedBy: "/")
                    if let posIdx = Int(components[0]) {
                        let uvIdx = components.count > 1 ? Int(components[1]) : nil
                        let normalIdx = components.count > 2 ? Int(components[2]) : nil
                        faceIndices.append((posIdx, uvIdx, normalIdx))
                    }
                }
                
                // Triangulate face (fan triangulation)
                for i in 1..<(faceIndices.count - 1) {
                    for idx in [0, i, i + 1] {
                        let face = faceIndices[idx]
                        let posIdx = face.pos > 0 ? face.pos - 1 : positions.count + face.pos
                        
                        let pos = posIdx < positions.count ? positions[posIdx] : .zero
                        
                        var normal = Vec3d.up
                        if let nIdx = face.normal {
                            let normalIdx = nIdx > 0 ? nIdx - 1 : normals.count + nIdx
                            if normalIdx < normals.count {
                                normal = normals[normalIdx]
                            }
                        }
                        
                        var uv = Vec2d.zero
                        if let uvIdx = face.uv {
                            let texIdx = uvIdx > 0 ? uvIdx - 1 : uvs.count + uvIdx
                            if texIdx < uvs.count {
                                uv = uvs[texIdx]
                            }
                        }
                        
                        indices.append(UInt32(vertices.count))
                        vertices.append(MeshData.Vertex(position: pos, normal: normal, uv: uv))
                    }
                }
                
            default:
                break
            }
        }
        
        // Calculate bounds
        var minBound = Vec3d(Float.infinity, Float.infinity, Float.infinity)
        var maxBound = Vec3d(-Float.infinity, -Float.infinity, -Float.infinity)
        
        for vertex in vertices {
            minBound = Vec3d(
                min(minBound.x, vertex.position.x),
                min(minBound.y, vertex.position.y),
                min(minBound.z, vertex.position.z)
            )
            maxBound = Vec3d(
                max(maxBound.x, vertex.position.x),
                max(maxBound.y, vertex.position.y),
                max(maxBound.z, vertex.position.z)
            )
        }
        
        let center = Vec3d(
            (minBound.x + maxBound.x) / 2,
            (minBound.y + maxBound.y) / 2,
            (minBound.z + maxBound.z) / 2
        )
        let size = Vec3d(
            maxBound.x - minBound.x,
            maxBound.y - minBound.y,
            maxBound.z - minBound.z
        )
        
        return MeshData(
            vertices: vertices,
            indices: indices,
            bounds: MeshData.BoundsData(center: center, size: size)
        )
    }
    
    // MARK: - STL Parser (Binary)
    
    private func parseSTL(data: Data) throws -> MeshData {
        // Try binary STL first
        guard data.count > 84 else {
            throw AssetLoadError.decodingFailed("STL file too small")
        }
        
        // Read triangle count (bytes 80-83)
        let triangleCount = data.withUnsafeBytes { ptr -> UInt32 in
            ptr.load(fromByteOffset: 80, as: UInt32.self)
        }
        
        let expectedSize = 84 + Int(triangleCount) * 50
        guard data.count >= expectedSize else {
            throw AssetLoadError.decodingFailed("STL file truncated")
        }
        
        var vertices: [MeshData.Vertex] = []
        var indices: [UInt32] = []
        
        var minBound = Vec3d(Float.infinity, Float.infinity, Float.infinity)
        var maxBound = Vec3d(-Float.infinity, -Float.infinity, -Float.infinity)
        
        data.withUnsafeBytes { ptr in
            var offset = 84
            
            for _ in 0..<triangleCount {
                // Read normal
                let nx = ptr.load(fromByteOffset: offset, as: Float.self)
                let ny = ptr.load(fromByteOffset: offset + 4, as: Float.self)
                let nz = ptr.load(fromByteOffset: offset + 8, as: Float.self)
                let normal = Vec3d(nx, ny, nz)
                offset += 12
                
                // Read 3 vertices
                for _ in 0..<3 {
                    let x = ptr.load(fromByteOffset: offset, as: Float.self)
                    let y = ptr.load(fromByteOffset: offset + 4, as: Float.self)
                    let z = ptr.load(fromByteOffset: offset + 8, as: Float.self)
                    let pos = Vec3d(x, y, z)
                    offset += 12
                    
                    minBound = Vec3d(min(minBound.x, x), min(minBound.y, y), min(minBound.z, z))
                    maxBound = Vec3d(max(maxBound.x, x), max(maxBound.y, y), max(maxBound.z, z))
                    
                    indices.append(UInt32(vertices.count))
                    vertices.append(MeshData.Vertex(position: pos, normal: normal, uv: .zero))
                }
                
                // Skip attribute byte count
                offset += 2
            }
        }
        
        let center = Vec3d(
            (minBound.x + maxBound.x) / 2,
            (minBound.y + maxBound.y) / 2,
            (minBound.z + maxBound.z) / 2
        )
        let size = Vec3d(
            maxBound.x - minBound.x,
            maxBound.y - minBound.y,
            maxBound.z - minBound.z
        )
        
        return MeshData(
            vertices: vertices,
            indices: indices,
            bounds: MeshData.BoundsData(center: center, size: size)
        )
    }
}

// MARK: - Sendable Mesh Data

/// Thread-safe mesh data that can be passed between actors
public struct MeshData: Sendable {
    public struct Vertex: Sendable {
        public let position: Vec3d
        public let normal: Vec3d
        public let uv: Vec2d
        
        public init(position: Vec3d, normal: Vec3d, uv: Vec2d) {
            self.position = position
            self.normal = normal
            self.uv = uv
        }
    }
    
    public struct BoundsData: Sendable {
        public let center: Vec3d
        public let size: Vec3d
        
        public init(center: Vec3d, size: Vec3d) {
            self.center = center
            self.size = size
        }
    }
    
    public let vertices: [Vertex]
    public let indices: [UInt32]
    public let bounds: BoundsData
    
    public var triangleCount: Int { indices.count / 3 }
    
    public init(vertices: [Vertex], indices: [UInt32], bounds: BoundsData) {
        self.vertices = vertices
        self.indices = indices
        self.bounds = bounds
    }
}
