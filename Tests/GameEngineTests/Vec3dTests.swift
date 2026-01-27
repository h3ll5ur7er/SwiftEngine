import Testing
@testable import GameEngine

@Suite("Vec3d Tests")
struct Vec3dTests {
    
    let epsilon: Float32 = 0.0001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    @Test("Vec3d initialization")
    func initialization() {
        let v1 = Vec3d(x: 1.5, y: 2.5, z: 3.5)
        #expect(v1.x == 1.5)
        #expect(v1.y == 2.5)
        #expect(v1.z == 3.5)
        
        let v2 = Vec3d(1.0, 2.0, 3.0)
        #expect(v2.x == 1.0)
        #expect(v2.y == 2.0)
        #expect(v2.z == 3.0)
        
        #expect(Vec3d.zero == Vec3d(0, 0, 0))
        #expect(Vec3d.one == Vec3d(1, 1, 1))
        #expect(Vec3d.unitX == Vec3d(1, 0, 0))
        #expect(Vec3d.unitY == Vec3d(0, 1, 0))
        #expect(Vec3d.unitZ == Vec3d(0, 0, 1))
    }
    
    @Test("Vec3d addition")
    func addition() {
        let a = Vec3d(1.5, 2.5, 3.5)
        let b = Vec3d(0.5, 1.5, 2.5)
        let result = a + b
        #expect(isClose(result, Vec3d(2, 4, 6)))
    }
    
    @Test("Vec3d subtraction")
    func subtraction() {
        let a = Vec3d(3.0, 4.0, 5.0)
        let b = Vec3d(1.0, 1.5, 2.0)
        let result = a - b
        #expect(isClose(result, Vec3d(2, 2.5, 3)))
    }
    
    @Test("Vec3d scalar multiplication")
    func scalarMultiplication() {
        let v = Vec3d(2, 3, 4)
        let result = v * 2.5
        #expect(isClose(result, Vec3d(5, 7.5, 10)))
        
        let result2 = 0.5 * v
        #expect(isClose(result2, Vec3d(1, 1.5, 2)))
    }
    
    @Test("Vec3d scalar division")
    func scalarDivision() {
        let v = Vec3d(6, 9, 12)
        let result = v / 3
        #expect(isClose(result, Vec3d(2, 3, 4)))
    }
    
    @Test("Vec3d negation")
    func negation() {
        let v = Vec3d(1.5, -2.5, 3.5)
        let result = -v
        #expect(isClose(result, Vec3d(-1.5, 2.5, -3.5)))
    }
    
    @Test("Vec3d dot product")
    func dotProduct() {
        let a = Vec3d(1, 2, 3)
        let b = Vec3d(4, 5, 6)
        #expect(isClose(a.dot(b), 32)) // 1*4 + 2*5 + 3*6 = 32
        
        // Perpendicular vectors have dot product = 0
        let x = Vec3d.unitX
        let y = Vec3d.unitY
        #expect(isClose(x.dot(y), 0))
    }
    
    @Test("Vec3d cross product")
    func crossProduct() {
        let x = Vec3d.unitX
        let y = Vec3d.unitY
        let z = x.cross(y)
        #expect(isClose(z, Vec3d.unitZ))
        
        // Cross product is anti-commutative
        let negZ = y.cross(x)
        #expect(isClose(negZ, -Vec3d.unitZ))
        
        // Cross product of parallel vectors is zero
        let parallel = Vec3d(2, 0, 0)
        #expect(isClose(x.cross(parallel), Vec3d.zero))
    }
    
    @Test("Vec3d length")
    func length() {
        let v = Vec3d(3, 4, 0)
        #expect(isClose(v.length, 5))
        #expect(isClose(v.squaredLength, 25))
        
        let unit = Vec3d.unitX
        #expect(isClose(unit.length, 1))
    }
    
    @Test("Vec3d normalized")
    func normalized() {
        let v = Vec3d(3, 4, 0)
        let norm = v.normalized
        #expect(isClose(norm.length, 1))
        #expect(isClose(norm, Vec3d(0.6, 0.8, 0)))
        
        // Zero vector normalization should return zero
        let zero = Vec3d.zero.normalized
        #expect(zero == Vec3d.zero)
    }
    
    @Test("Vec3d distance")
    func distance() {
        let a = Vec3d(0, 0, 0)
        let b = Vec3d(3, 4, 0)
        #expect(isClose(a.distance(to: b), 5))
        #expect(isClose(a.squaredDistance(to: b), 25))
    }
    
    @Test("Vec3d lerp")
    func lerp() {
        let a = Vec3d(0, 0, 0)
        let b = Vec3d(10, 20, 30)
        
        #expect(isClose(a.lerp(to: b, t: 0), a))
        #expect(isClose(a.lerp(to: b, t: 1), b))
        #expect(isClose(a.lerp(to: b, t: 0.5), Vec3d(5, 10, 15)))
    }
    
    @Test("Vec3d reflect")
    func reflect() {
        // Reflect a vector going down-right off a vertical surface
        let incident = Vec3d(1, -1, 0).normalized
        let normal = Vec3d(-1, 0, 0) // Surface facing left
        let reflected = incident.reflect(normal: normal)
        
        // Should reflect back going down-left
        let expected = Vec3d(-1, -1, 0).normalized
        #expect(isClose(reflected, expected))
    }
}
