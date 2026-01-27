import Testing
@testable import GameEngine

@Suite("Vec3 Tests")
struct Vec3Tests {
    
    @Test("Vec3 initialization")
    func initialization() {
        let v1 = Vec3(x: 10, y: 20, z: 30)
        #expect(v1.x == 10)
        #expect(v1.y == 20)
        #expect(v1.z == 30)
        
        let v2 = Vec3(5, 15, 25)
        #expect(v2.x == 5)
        #expect(v2.y == 15)
        #expect(v2.z == 25)
        
        #expect(Vec3.zero == Vec3(0, 0, 0))
    }
    
    @Test("Vec3 addition")
    func addition() {
        let a = Vec3(10, 20, 30)
        let b = Vec3(5, 15, 25)
        let result = a + b
        #expect(result == Vec3(15, 35, 55))
    }
    
    @Test("Vec3 subtraction")
    func subtraction() {
        let a = Vec3(10, 20, 30)
        let b = Vec3(3, 7, 11)
        let result = a - b
        #expect(result == Vec3(7, 13, 19))
    }
    
    @Test("Vec3 scalar multiplication")
    func scalarMultiplication() {
        let v = Vec3(4, 6, 8)
        let result = v * 3
        #expect(result == Vec3(12, 18, 24))
        
        let result2 = 2 * v
        #expect(result2 == Vec3(8, 12, 16))
    }
    
    @Test("Vec3 scalar division")
    func scalarDivision() {
        let v = Vec3(12, 18, 24)
        let result = v / 3
        #expect(result == Vec3(4, 6, 8))
    }
    
    @Test("Vec3 negation")
    func negation() {
        let v = Vec3(5, -3, 7)
        let result = -v
        #expect(result == Vec3(-5, 3, -7))
    }
    
    @Test("Vec3 dot product")
    func dotProduct() {
        let a = Vec3(1, 2, 3)
        let b = Vec3(4, 5, 6)
        #expect(a.dot(b) == 32) // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    }
    
    @Test("Vec3 cross product")
    func crossProduct() {
        let x = Vec3(1, 0, 0)
        let y = Vec3(0, 1, 0)
        let z = x.cross(y)
        #expect(z == Vec3(0, 0, 1))
        
        // Cross product is anti-commutative
        let negZ = y.cross(x)
        #expect(negZ == Vec3(0, 0, -1))
    }
    
    @Test("Vec3 squared length")
    func squaredLength() {
        let v = Vec3(3, 4, 0)
        #expect(v.squaredLength == 25) // 9 + 16 = 25
    }
    
    @Test("Vec3 manhattan distance")
    func manhattanDistance() {
        let a = Vec3(0, 0, 0)
        let b = Vec3(3, 4, 5)
        #expect(a.manhattanDistance(to: b) == 12)
    }
    
    @Test("Vec3 squared distance")
    func squaredDistance() {
        let a = Vec3(0, 0, 0)
        let b = Vec3(3, 4, 0)
        #expect(a.squaredDistance(to: b) == 25) // 3² + 4² = 25
    }
}
