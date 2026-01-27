import Testing
@testable import GameEngine

@Suite("Vec4d Tests")
struct Vec4dTests {
    
    let epsilon: Float32 = 0.0001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec4d, _ b: Vec4d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z) && isClose(a.w, b.w)
    }
    
    @Test("Vec4d initialization")
    func initialization() {
        let v1 = Vec4d(x: 1.5, y: 2.5, z: 3.5, w: 4.5)
        #expect(v1.x == 1.5)
        #expect(v1.y == 2.5)
        #expect(v1.z == 3.5)
        #expect(v1.w == 4.5)
        
        #expect(Vec4d.zero == Vec4d(0, 0, 0, 0))
        #expect(Vec4d.one == Vec4d(1, 1, 1, 1))
        #expect(Vec4d.unitX == Vec4d(1, 0, 0, 0))
        #expect(Vec4d.unitY == Vec4d(0, 1, 0, 0))
        #expect(Vec4d.unitZ == Vec4d(0, 0, 1, 0))
        #expect(Vec4d.unitW == Vec4d(0, 0, 0, 1))
    }
    
    @Test("Vec4d arithmetic operations")
    func arithmeticOperations() {
        let a = Vec4d(1, 2, 3, 4)
        let b = Vec4d(5, 6, 7, 8)
        
        #expect(isClose(a + b, Vec4d(6, 8, 10, 12)))
        #expect(isClose(a - b, Vec4d(-4, -4, -4, -4)))
        #expect(isClose(a * 2, Vec4d(2, 4, 6, 8)))
        #expect(isClose(a / 2, Vec4d(0.5, 1, 1.5, 2)))
        #expect(isClose(-a, Vec4d(-1, -2, -3, -4)))
    }
    
    @Test("Vec4d dot product")
    func dotProduct() {
        let a = Vec4d(1, 2, 3, 4)
        let b = Vec4d(5, 6, 7, 8)
        #expect(isClose(a.dot(b), 70)) // 5 + 12 + 21 + 32 = 70
    }
    
    @Test("Vec4d length")
    func length() {
        let v = Vec4d(1, 2, 2, 0)
        #expect(isClose(v.squaredLength, 9))
        #expect(isClose(v.length, 3))
    }
    
    @Test("Vec4d normalized")
    func normalized() {
        let v = Vec4d(0, 3, 4, 0)
        let norm = v.normalized
        #expect(isClose(norm.length, 1))
        #expect(isClose(norm, Vec4d(0, 0.6, 0.8, 0)))
    }
    
    @Test("Vec4d lerp")
    func lerp() {
        let a = Vec4d(0, 0, 0, 0)
        let b = Vec4d(10, 20, 30, 40)
        
        #expect(isClose(a.lerp(to: b, t: 0), a))
        #expect(isClose(a.lerp(to: b, t: 1), b))
        #expect(isClose(a.lerp(to: b, t: 0.5), Vec4d(5, 10, 15, 20)))
    }
    
    @Test("Vec4d xyz extraction")
    func xyzExtraction() {
        let v = Vec4d(1, 2, 3, 4)
        let xyz = v.xyz
        #expect(xyz == Vec3d(1, 2, 3))
    }
}
