import Testing
@testable import GameEngine

@Suite("Vec2 Tests")
struct Vec2Tests {
    
    @Test("Vec2 initialization")
    func initialization() {
        let v1 = Vec2(x: 10, y: 20)
        #expect(v1.x == 10)
        #expect(v1.y == 20)
        
        let v2 = Vec2(5, 15)
        #expect(v2.x == 5)
        #expect(v2.y == 15)
        
        #expect(Vec2.zero.x == 0)
        #expect(Vec2.zero.y == 0)
    }
    
    @Test("Vec2 addition")
    func addition() {
        let a = Vec2(10, 20)
        let b = Vec2(5, 15)
        let result = a + b
        #expect(result.x == 15)
        #expect(result.y == 35)
    }
    
    @Test("Vec2 subtraction")
    func subtraction() {
        let a = Vec2(10, 20)
        let b = Vec2(3, 7)
        let result = a - b
        #expect(result.x == 7)
        #expect(result.y == 13)
    }
    
    @Test("Vec2 scalar multiplication")
    func scalarMultiplication() {
        let v = Vec2(4, 6)
        let result = v * 3
        #expect(result.x == 12)
        #expect(result.y == 18)
        
        let result2 = 2 * v
        #expect(result2.x == 8)
        #expect(result2.y == 12)
    }
    
    @Test("Vec2 scalar division")
    func scalarDivision() {
        let v = Vec2(12, 18)
        let result = v / 3
        #expect(result.x == 4)
        #expect(result.y == 6)
    }
    
    @Test("Vec2 negation")
    func negation() {
        let v = Vec2(5, -3)
        let result = -v
        #expect(result.x == -5)
        #expect(result.y == 3)
    }
    
    @Test("Vec2 compound assignment")
    func compoundAssignment() {
        var v = Vec2(10, 20)
        v += Vec2(5, 5)
        #expect(v.x == 15)
        #expect(v.y == 25)
        
        v -= Vec2(3, 3)
        #expect(v.x == 12)
        #expect(v.y == 22)
        
        v *= 2
        #expect(v.x == 24)
        #expect(v.y == 44)
    }
    
    @Test("Vec2 manhattan distance")
    func manhattanDistance() {
        let a = Vec2(0, 0)
        let b = Vec2(3, 4)
        #expect(a.manhattanDistance(to: b) == 7)
    }
    
    @Test("Vec2 squared distance")
    func squaredDistance() {
        let a = Vec2(0, 0)
        let b = Vec2(3, 4)
        #expect(a.squaredDistance(to: b) == 25) // 3² + 4² = 9 + 16 = 25
    }
    
    @Test("Vec2 equality")
    func equality() {
        let a = Vec2(10, 20)
        let b = Vec2(10, 20)
        let c = Vec2(10, 21)
        #expect(a == b)
        #expect(a != c)
    }
}
