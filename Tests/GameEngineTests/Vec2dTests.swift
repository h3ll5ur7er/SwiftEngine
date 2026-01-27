import Foundation
import Testing
@testable import GameEngine

@Suite("Vec2d Tests")
struct Vec2dTests {
    
    let epsilon: Float32 = 0.0001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec2d, _ b: Vec2d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y)
    }
    
    @Test("Vec2d initialization")
    func initialization() {
        let v1 = Vec2d(x: 1.5, y: 2.5)
        #expect(v1.x == 1.5)
        #expect(v1.y == 2.5)
        
        #expect(Vec2d.zero == Vec2d(0, 0))
        #expect(Vec2d.one == Vec2d(1, 1))
        #expect(Vec2d.unitX == Vec2d(1, 0))
        #expect(Vec2d.unitY == Vec2d(0, 1))
    }
    
    @Test("Vec2d arithmetic operations")
    func arithmeticOperations() {
        let a = Vec2d(3, 4)
        let b = Vec2d(1, 2)
        
        #expect(isClose(a + b, Vec2d(4, 6)))
        #expect(isClose(a - b, Vec2d(2, 2)))
        #expect(isClose(a * 2, Vec2d(6, 8)))
        #expect(isClose(a / 2, Vec2d(1.5, 2)))
        #expect(isClose(-a, Vec2d(-3, -4)))
    }
    
    @Test("Vec2d dot product")
    func dotProduct() {
        let a = Vec2d(1, 0)
        let b = Vec2d(0, 1)
        #expect(isClose(a.dot(b), 0)) // Perpendicular
        
        let c = Vec2d(3, 4)
        let d = Vec2d(2, 1)
        #expect(isClose(c.dot(d), 10)) // 3*2 + 4*1 = 10
    }
    
    @Test("Vec2d cross product")
    func crossProduct() {
        let a = Vec2d(1, 0)
        let b = Vec2d(0, 1)
        #expect(isClose(a.cross(b), 1)) // Counter-clockwise, positive
        #expect(isClose(b.cross(a), -1)) // Clockwise, negative
    }
    
    @Test("Vec2d length")
    func length() {
        let v = Vec2d(3, 4)
        #expect(isClose(v.squaredLength, 25))
        #expect(isClose(v.length, 5))
    }
    
    @Test("Vec2d normalized")
    func normalized() {
        let v = Vec2d(3, 4)
        let norm = v.normalized
        #expect(isClose(norm.length, 1))
        #expect(isClose(norm, Vec2d(0.6, 0.8)))
    }
    
    @Test("Vec2d distance")
    func distance() {
        let a = Vec2d(0, 0)
        let b = Vec2d(3, 4)
        #expect(isClose(a.distance(to: b), 5))
        #expect(isClose(a.squaredDistance(to: b), 25))
    }
    
    @Test("Vec2d lerp")
    func lerp() {
        let a = Vec2d(0, 0)
        let b = Vec2d(10, 20)
        
        #expect(isClose(a.lerp(to: b, t: 0), a))
        #expect(isClose(a.lerp(to: b, t: 1), b))
        #expect(isClose(a.lerp(to: b, t: 0.5), Vec2d(5, 10)))
    }
    
    @Test("Vec2d perpendicular")
    func perpendicular() {
        let v = Vec2d(1, 0)
        let perp = v.perpendicular
        #expect(isClose(perp, Vec2d(0, 1)))
        #expect(isClose(v.dot(perp), 0)) // Should be perpendicular
    }
    
    @Test("Vec2d angle")
    func angle() {
        let right = Vec2d(1, 0)
        let up = Vec2d(0, 1)
        let left = Vec2d(-1, 0)
        let down = Vec2d(0, -1)
        
        #expect(isClose(right.angle, 0))
        #expect(isClose(up.angle, .pi / 2))
        #expect(isClose(left.angle, .pi))
        #expect(isClose(down.angle, -.pi / 2))
    }
    
    @Test("Vec2d fromAngle")
    func fromAngle() {
        let v0 = Vec2d.fromAngle(0)
        #expect(isClose(v0, Vec2d(1, 0)))
        
        let v90 = Vec2d.fromAngle(.pi / 2)
        #expect(isClose(v90, Vec2d(0, 1)))
        
        let v45Length2 = Vec2d.fromAngle(.pi / 4, length: 2)
        let expected = Vec2d(sqrt(2), sqrt(2))
        #expect(isClose(v45Length2, expected))
    }
}
