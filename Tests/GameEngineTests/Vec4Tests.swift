import Testing
@testable import GameEngine

@Suite("Vec4 Tests")
struct Vec4Tests {
    
    @Test("Vec4 initialization")
    func initialization() {
        let v1 = Vec4(x: 10, y: 20, z: 30, w: 40)
        #expect(v1.x == 10)
        #expect(v1.y == 20)
        #expect(v1.z == 30)
        #expect(v1.w == 40)
        
        let v2 = Vec4(5, 15, 25, 35)
        #expect(v2.x == 5)
        #expect(v2.y == 15)
        #expect(v2.z == 25)
        #expect(v2.w == 35)
        
        #expect(Vec4.zero == Vec4(0, 0, 0, 0))
    }
    
    @Test("Vec4 addition")
    func addition() {
        let a = Vec4(10, 20, 30, 40)
        let b = Vec4(5, 15, 25, 35)
        let result = a + b
        #expect(result == Vec4(15, 35, 55, 75))
    }
    
    @Test("Vec4 subtraction")
    func subtraction() {
        let a = Vec4(10, 20, 30, 40)
        let b = Vec4(3, 7, 11, 15)
        let result = a - b
        #expect(result == Vec4(7, 13, 19, 25))
    }
    
    @Test("Vec4 scalar multiplication")
    func scalarMultiplication() {
        let v = Vec4(4, 6, 8, 10)
        let result = v * 3
        #expect(result == Vec4(12, 18, 24, 30))
        
        let result2 = 2 * v
        #expect(result2 == Vec4(8, 12, 16, 20))
    }
    
    @Test("Vec4 scalar division")
    func scalarDivision() {
        let v = Vec4(12, 18, 24, 30)
        let result = v / 3
        #expect(result == Vec4(4, 6, 8, 10))
    }
    
    @Test("Vec4 negation")
    func negation() {
        let v = Vec4(5, -3, 7, -9)
        let result = -v
        #expect(result == Vec4(-5, 3, -7, 9))
    }
    
    @Test("Vec4 dot product")
    func dotProduct() {
        let a = Vec4(1, 2, 3, 4)
        let b = Vec4(5, 6, 7, 8)
        #expect(a.dot(b) == 70) // 1*5 + 2*6 + 3*7 + 4*8 = 5 + 12 + 21 + 32 = 70
    }
    
    @Test("Vec4 squared length")
    func squaredLength() {
        let v = Vec4(1, 2, 2, 0)
        #expect(v.squaredLength == 9) // 1 + 4 + 4 = 9
    }
    
    @Test("Vec4 manhattan distance")
    func manhattanDistance() {
        let a = Vec4(0, 0, 0, 0)
        let b = Vec4(1, 2, 3, 4)
        #expect(a.manhattanDistance(to: b) == 10)
    }
}
