import Testing
@testable import GameEngine

@Suite("Rect Tests")
struct RectTests {
    
    @Test("Rect initialization")
    func initialization() {
        let r1 = Rect(x: 10, y: 20, width: 100, height: 50)
        #expect(r1.x == 10)
        #expect(r1.y == 20)
        #expect(r1.width == 100)
        #expect(r1.height == 50)
        
        let r2 = Rect(origin: Vec2(5, 15), size: Vec2(200, 100))
        #expect(r2.x == 5)
        #expect(r2.y == 15)
        #expect(r2.width == 200)
        #expect(r2.height == 100)
        
        #expect(Rect.zero.x == 0)
        #expect(Rect.zero.width == 0)
    }
    
    @Test("Rect edge properties")
    func edgeProperties() {
        let r = Rect(x: 10, y: 20, width: 100, height: 50)
        #expect(r.left == 10)
        #expect(r.top == 20)
        #expect(r.right == 110)
        #expect(r.bottom == 70)
    }
    
    @Test("Rect corner properties")
    func cornerProperties() {
        let r = Rect(x: 10, y: 20, width: 100, height: 50)
        #expect(r.topLeft == Vec2(10, 20))
        #expect(r.topRight == Vec2(110, 20))
        #expect(r.bottomLeft == Vec2(10, 70))
        #expect(r.bottomRight == Vec2(110, 70))
    }
    
    @Test("Rect center")
    func center() {
        let r = Rect(x: 0, y: 0, width: 100, height: 50)
        #expect(r.center == Vec2(50, 25))
    }
    
    @Test("Rect area")
    func area() {
        let r = Rect(x: 0, y: 0, width: 10, height: 5)
        #expect(r.area == 50)
    }
    
    @Test("Rect isEmpty")
    func isEmpty() {
        #expect(Rect(x: 0, y: 0, width: 0, height: 10).isEmpty)
        #expect(Rect(x: 0, y: 0, width: 10, height: 0).isEmpty)
        #expect(Rect(x: 0, y: 0, width: -1, height: 10).isEmpty)
        #expect(!Rect(x: 0, y: 0, width: 10, height: 10).isEmpty)
    }
    
    @Test("Rect contains point")
    func containsPoint() {
        let r = Rect(x: 10, y: 20, width: 100, height: 50)
        
        // Inside
        #expect(r.contains(Vec2(50, 40)))
        
        // On edges (left/top inclusive)
        #expect(r.contains(Vec2(10, 20)))
        
        // On edges (right/bottom exclusive)
        #expect(!r.contains(Vec2(110, 20)))
        #expect(!r.contains(Vec2(10, 70)))
        
        // Outside
        #expect(!r.contains(Vec2(0, 0)))
        #expect(!r.contains(Vec2(200, 200)))
    }
    
    @Test("Rect intersects")
    func intersects() {
        let r1 = Rect(x: 0, y: 0, width: 100, height: 100)
        let r2 = Rect(x: 50, y: 50, width: 100, height: 100)  // Overlapping
        let r3 = Rect(x: 200, y: 200, width: 50, height: 50)  // Non-overlapping
        let r4 = Rect(x: 100, y: 0, width: 50, height: 50)    // Adjacent (not overlapping)
        
        #expect(r1.intersects(r2))
        #expect(!r1.intersects(r3))
        #expect(!r1.intersects(r4))
    }
    
    @Test("Rect intersection")
    func intersection() {
        let r1 = Rect(x: 0, y: 0, width: 100, height: 100)
        let r2 = Rect(x: 50, y: 50, width: 100, height: 100)
        
        let intersection = r1.intersection(with: r2)
        #expect(intersection != nil)
        #expect(intersection?.x == 50)
        #expect(intersection?.y == 50)
        #expect(intersection?.width == 50)
        #expect(intersection?.height == 50)
        
        // Non-overlapping
        let r3 = Rect(x: 200, y: 200, width: 50, height: 50)
        #expect(r1.intersection(with: r3) == nil)
    }
    
    @Test("Rect union")
    func union() {
        let r1 = Rect(x: 0, y: 0, width: 50, height: 50)
        let r2 = Rect(x: 100, y: 100, width: 50, height: 50)
        
        let union = r1.union(with: r2)
        #expect(union.x == 0)
        #expect(union.y == 0)
        #expect(union.right == 150)
        #expect(union.bottom == 150)
    }
    
    @Test("Rect inset")
    func inset() {
        let r = Rect(x: 10, y: 20, width: 100, height: 50)
        let inset = r.inset(by: 5)
        #expect(inset.x == 15)
        #expect(inset.y == 25)
        #expect(inset.width == 90)
        #expect(inset.height == 40)
    }
    
    @Test("Rect offset")
    func offset() {
        let r = Rect(x: 10, y: 20, width: 100, height: 50)
        let offset = r.offset(by: Vec2(5, -5))
        #expect(offset.x == 15)
        #expect(offset.y == 15)
        #expect(offset.width == 100)
        #expect(offset.height == 50)
    }
    
    @Test("Rect equality")
    func equality() {
        let a = Rect(x: 10, y: 20, width: 100, height: 50)
        let b = Rect(x: 10, y: 20, width: 100, height: 50)
        let c = Rect(x: 10, y: 20, width: 100, height: 51)
        #expect(a == b)
        #expect(a != c)
    }
}
