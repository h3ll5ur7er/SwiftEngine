import Testing
@testable import GameEngine

@Suite("Primitive Mesh Tests")
struct PrimitiveMeshTests {

    /// Every triangle's winding (counter-clockwise = front) must face the same way as its vertex normals,
    /// otherwise back-face culling removes the visible side
    func expectWindingMatchesNormals(_ mesh: any Mesh, _ name: String) {
        let v = mesh.vertices
        let idx = mesh.indices.map(Int.init)
        #expect(idx.count % 3 == 0)
        for t in stride(from: 0, to: idx.count, by: 3) {
            let a = v[idx[t]], b = v[idx[t + 1]], c = v[idx[t + 2]]
            let faceNormal = (b.position - a.position).cross(c.position - a.position)
            let vertexNormal = a.normal + b.normal + c.normal
            #expect(faceNormal.dot(vertexNormal) > 0, "\(name) triangle \(t / 3) is wound against its normals")
        }
    }
    
    @Test("CubeMesh winding matches normals")
    func cube() { expectWindingMatchesNormals(CubeMesh.shared, "CubeMesh") }
    
    @Test("PlaneMesh winding matches normals")
    func plane() { expectWindingMatchesNormals(PlaneMesh(width: 4, depth: 2), "PlaneMesh") }
    
    @Test("QuadMesh winding matches normals")
    func quad() { expectWindingMatchesNormals(QuadMesh(width: 2, height: 3), "QuadMesh") }
}
