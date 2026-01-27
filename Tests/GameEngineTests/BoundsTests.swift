import Testing
@testable import GameEngine

@Suite("Bounds Tests")
struct BoundsTests {
    
    let epsilon: Float = 0.0001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    // MARK: - Initialization
    
    @Test("Default initialization")
    func defaultInit() {
        let bounds = Bounds()
        #expect(isClose(bounds.center, .zero))
        #expect(isClose(bounds.size, .one))
    }
    
    @Test("Custom initialization")
    func customInit() {
        let bounds = Bounds(center: Vec3d(1, 2, 3), size: Vec3d(4, 6, 8))
        #expect(isClose(bounds.center, Vec3d(1, 2, 3)))
        #expect(isClose(bounds.size, Vec3d(4, 6, 8)))
    }
    
    // MARK: - Computed Properties
    
    @Test("Min and max from center and size")
    func minMax() {
        let bounds = Bounds(center: Vec3d(5, 5, 5), size: Vec3d(4, 6, 8))
        
        // min = center - size/2
        #expect(isClose(bounds.min, Vec3d(3, 2, 1)))
        
        // max = center + size/2
        #expect(isClose(bounds.max, Vec3d(7, 8, 9)))
    }
    
    @Test("Extents is half size")
    func extents() {
        let bounds = Bounds(center: .zero, size: Vec3d(4, 6, 8))
        #expect(isClose(bounds.extents, Vec3d(2, 3, 4)))
    }
    
    @Test("Unit bounds at origin")
    func unitBoundsAtOrigin() {
        let bounds = Bounds(center: .zero, size: .one)
        #expect(isClose(bounds.min, Vec3d(-0.5, -0.5, -0.5)))
        #expect(isClose(bounds.max, Vec3d(0.5, 0.5, 0.5)))
        #expect(isClose(bounds.extents, Vec3d(0.5, 0.5, 0.5)))
    }
    
    // MARK: - fromMinMax
    
    @Test("Create from min and max")
    func fromMinMax() {
        let bounds = Bounds.fromMinMax(
            min: Vec3d(0, 0, 0),
            max: Vec3d(10, 20, 30)
        )
        
        #expect(isClose(bounds.center, Vec3d(5, 10, 15)))
        #expect(isClose(bounds.size, Vec3d(10, 20, 30)))
    }
    
    @Test("Create from negative min")
    func fromMinMaxNegative() {
        let bounds = Bounds.fromMinMax(
            min: Vec3d(-5, -5, -5),
            max: Vec3d(5, 5, 5)
        )
        
        #expect(isClose(bounds.center, .zero))
        #expect(isClose(bounds.size, Vec3d(10, 10, 10)))
    }
    
    // MARK: - Contains Point
    
    @Test("Contains point inside")
    func containsPointInside() {
        let bounds = Bounds(center: .zero, size: Vec3d(10, 10, 10))
        
        #expect(bounds.contains(Vec3d(0, 0, 0)))
        #expect(bounds.contains(Vec3d(1, 2, 3)))
        #expect(bounds.contains(Vec3d(-1, -2, -3)))
    }
    
    @Test("Contains point on boundary")
    func containsPointOnBoundary() {
        let bounds = Bounds(center: .zero, size: Vec3d(10, 10, 10))
        
        // Points exactly on the boundary should be included
        #expect(bounds.contains(Vec3d(5, 0, 0)))
        #expect(bounds.contains(Vec3d(-5, 0, 0)))
        #expect(bounds.contains(Vec3d(0, 5, 0)))
        #expect(bounds.contains(Vec3d(0, 0, 5)))
    }
    
    @Test("Does not contain point outside")
    func doesNotContainPointOutside() {
        let bounds = Bounds(center: .zero, size: Vec3d(10, 10, 10))
        
        #expect(!bounds.contains(Vec3d(6, 0, 0)))
        #expect(!bounds.contains(Vec3d(-6, 0, 0)))
        #expect(!bounds.contains(Vec3d(0, 6, 0)))
        #expect(!bounds.contains(Vec3d(0, 0, 6)))
        #expect(!bounds.contains(Vec3d(10, 10, 10)))
    }
    
    @Test("Contains with offset center")
    func containsWithOffsetCenter() {
        let bounds = Bounds(center: Vec3d(100, 100, 100), size: Vec3d(10, 10, 10))
        
        #expect(bounds.contains(Vec3d(100, 100, 100)))
        #expect(bounds.contains(Vec3d(95, 100, 100)))
        #expect(!bounds.contains(Vec3d(0, 0, 0)))
    }
    
    // MARK: - Intersects
    
    @Test("Intersects overlapping bounds")
    func intersectsOverlapping() {
        let a = Bounds(center: Vec3d(0, 0, 0), size: Vec3d(10, 10, 10))
        let b = Bounds(center: Vec3d(5, 5, 5), size: Vec3d(10, 10, 10))
        
        #expect(a.intersects(b))
        #expect(b.intersects(a))
    }
    
    @Test("Intersects touching bounds")
    func intersectsTouching() {
        let a = Bounds(center: Vec3d(0, 0, 0), size: Vec3d(10, 10, 10))
        let b = Bounds(center: Vec3d(10, 0, 0), size: Vec3d(10, 10, 10))
        
        // Bounds that touch at edges should intersect
        #expect(a.intersects(b))
    }
    
    @Test("Does not intersect separate bounds")
    func doesNotIntersectSeparate() {
        let a = Bounds(center: Vec3d(0, 0, 0), size: Vec3d(10, 10, 10))
        let b = Bounds(center: Vec3d(20, 0, 0), size: Vec3d(10, 10, 10))
        
        #expect(!a.intersects(b))
        #expect(!b.intersects(a))
    }
    
    @Test("Intersects self")
    func intersectsSelf() {
        let bounds = Bounds(center: .zero, size: Vec3d(10, 10, 10))
        #expect(bounds.intersects(bounds))
    }
    
    @Test("Intersects contained bounds")
    func intersectsContained() {
        let outer = Bounds(center: .zero, size: Vec3d(10, 10, 10))
        let inner = Bounds(center: .zero, size: Vec3d(2, 2, 2))
        
        #expect(outer.intersects(inner))
        #expect(inner.intersects(outer))
    }
    
    @Test("Does not intersect on different axes")
    func doesNotIntersectDifferentAxes() {
        let a = Bounds(center: Vec3d(0, 0, 0), size: Vec3d(10, 10, 10))
        
        // Separated on Y axis only
        let b = Bounds(center: Vec3d(0, 20, 0), size: Vec3d(10, 10, 10))
        #expect(!a.intersects(b))
        
        // Separated on Z axis only
        let c = Bounds(center: Vec3d(0, 0, 20), size: Vec3d(10, 10, 10))
        #expect(!a.intersects(c))
    }
    
    // MARK: - Edge Cases
    
    @Test("Zero size bounds")
    func zeroSizeBounds() {
        let bounds = Bounds(center: Vec3d(5, 5, 5), size: .zero)
        
        // A point-sized bounds
        #expect(isClose(bounds.min, Vec3d(5, 5, 5)))
        #expect(isClose(bounds.max, Vec3d(5, 5, 5)))
        #expect(bounds.contains(Vec3d(5, 5, 5)))
        #expect(!bounds.contains(Vec3d(5.1, 5, 5)))
    }
    
    @Test("Very large bounds")
    func veryLargeBounds() {
        let bounds = Bounds(center: .zero, size: Vec3d(1000000, 1000000, 1000000))
        
        #expect(bounds.contains(Vec3d(100000, -100000, 50000)))
        #expect(!bounds.contains(Vec3d(600000, 0, 0)))
    }
}
