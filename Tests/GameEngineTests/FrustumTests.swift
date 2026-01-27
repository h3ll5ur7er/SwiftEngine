import Testing
@testable import GameEngine

@Suite("Frustum Tests")
struct FrustumTests {
    
    let epsilon: Float = 0.0001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    /// Create a simple box-like frustum for testing
    func makeBoxFrustum(halfSize: Float = 10) -> Frustum {
        let planes = [
            Plane.fromPointNormal(point: Vec3d(-halfSize, 0, 0), normal: Vec3d(1, 0, 0)),   // Left
            Plane.fromPointNormal(point: Vec3d(halfSize, 0, 0), normal: Vec3d(-1, 0, 0)),   // Right
            Plane.fromPointNormal(point: Vec3d(0, -halfSize, 0), normal: Vec3d(0, 1, 0)),   // Bottom
            Plane.fromPointNormal(point: Vec3d(0, halfSize, 0), normal: Vec3d(0, -1, 0)),   // Top
            Plane.fromPointNormal(point: Vec3d(0, 0, -halfSize), normal: Vec3d(0, 0, 1)),   // Near
            Plane.fromPointNormal(point: Vec3d(0, 0, halfSize), normal: Vec3d(0, 0, -1)),   // Far
        ]
        return Frustum(planes: planes)
    }
    
    // MARK: - Contains Point
    
    @Test("Contains point at origin")
    func containsOrigin() {
        let frustum = makeBoxFrustum()
        #expect(frustum.containsPoint(.zero))
    }
    
    @Test("Contains point inside")
    func containsPointInside() {
        let frustum = makeBoxFrustum()
        #expect(frustum.containsPoint(Vec3d(5, 5, 5)))
        #expect(frustum.containsPoint(Vec3d(-5, -5, -5)))
        #expect(frustum.containsPoint(Vec3d(9, 0, 0)))
    }
    
    @Test("Does not contain point outside")
    func doesNotContainPointOutside() {
        let frustum = makeBoxFrustum()
        #expect(!frustum.containsPoint(Vec3d(15, 0, 0)))
        #expect(!frustum.containsPoint(Vec3d(-15, 0, 0)))
        #expect(!frustum.containsPoint(Vec3d(0, 15, 0)))
        #expect(!frustum.containsPoint(Vec3d(0, 0, 15)))
    }
    
    @Test("Point exactly on boundary")
    func pointOnBoundary() {
        let frustum = makeBoxFrustum()
        // Points exactly on the plane should be excluded (distance = 0 is not > 0)
        // Our containsPoint uses plane.distanceToPoint(point) < 0 for exclusion
        // So distance = 0 is NOT excluded
        #expect(frustum.containsPoint(Vec3d(10, 0, 0)))
    }
    
    // MARK: - Intersects Sphere
    
    @Test("Sphere fully inside")
    func sphereFullyInside() {
        let frustum = makeBoxFrustum()
        #expect(frustum.intersectsSphere(center: .zero, radius: 5))
        #expect(frustum.intersectsSphere(center: Vec3d(5, 0, 0), radius: 2))
    }
    
    @Test("Sphere fully outside")
    func sphereFullyOutside() {
        let frustum = makeBoxFrustum()
        #expect(!frustum.intersectsSphere(center: Vec3d(20, 0, 0), radius: 5))
        #expect(!frustum.intersectsSphere(center: Vec3d(0, 20, 0), radius: 5))
        #expect(!frustum.intersectsSphere(center: Vec3d(0, 0, 20), radius: 5))
    }
    
    @Test("Sphere intersecting boundary")
    func sphereIntersectingBoundary() {
        let frustum = makeBoxFrustum()
        // Center outside, but radius reaches inside
        #expect(frustum.intersectsSphere(center: Vec3d(12, 0, 0), radius: 5))
    }
    
    @Test("Sphere touching boundary")
    func sphereTouchingBoundary() {
        let frustum = makeBoxFrustum()
        // Center at 15, radius 5, touches plane at 10
        #expect(frustum.intersectsSphere(center: Vec3d(15, 0, 0), radius: 5))
    }
    
    @Test("Sphere just outside")
    func sphereJustOutside() {
        let frustum = makeBoxFrustum()
        // Center at 16, radius 5, doesn't quite reach plane at 10
        #expect(!frustum.intersectsSphere(center: Vec3d(16, 0, 0), radius: 5))
    }
    
    @Test("Large sphere containing frustum")
    func largeSphereContainingFrustum() {
        let frustum = makeBoxFrustum()
        #expect(frustum.intersectsSphere(center: .zero, radius: 100))
    }
    
    // MARK: - Intersects Bounds
    
    @Test("Bounds fully inside")
    func boundsFullyInside() {
        let frustum = makeBoxFrustum()
        let bounds = Bounds(center: .zero, size: Vec3d(5, 5, 5))
        #expect(frustum.intersectsBounds(bounds))
    }
    
    @Test("Bounds fully outside")
    func boundsFullyOutside() {
        let frustum = makeBoxFrustum()
        let bounds = Bounds(center: Vec3d(20, 0, 0), size: Vec3d(5, 5, 5))
        #expect(!frustum.intersectsBounds(bounds))
    }
    
    @Test("Bounds intersecting boundary")
    func boundsIntersectingBoundary() {
        let frustum = makeBoxFrustum()
        // Bounds that straddle the frustum boundary
        let bounds = Bounds(center: Vec3d(10, 0, 0), size: Vec3d(5, 5, 5))
        #expect(frustum.intersectsBounds(bounds))
    }
    
    @Test("Bounds containing frustum")
    func boundsContainingFrustum() {
        let frustum = makeBoxFrustum()
        let bounds = Bounds(center: .zero, size: Vec3d(100, 100, 100))
        #expect(frustum.intersectsBounds(bounds))
    }
    
    @Test("Bounds outside on each axis")
    func boundsOutsideEachAxis() {
        let frustum = makeBoxFrustum()
        
        // Outside on +X
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(20, 0, 0), size: Vec3d(5, 5, 5))))
        // Outside on -X
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(-20, 0, 0), size: Vec3d(5, 5, 5))))
        // Outside on +Y
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(0, 20, 0), size: Vec3d(5, 5, 5))))
        // Outside on -Y
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(0, -20, 0), size: Vec3d(5, 5, 5))))
        // Outside on +Z
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(0, 0, 20), size: Vec3d(5, 5, 5))))
        // Outside on -Z
        #expect(!frustum.intersectsBounds(Bounds(center: Vec3d(0, 0, -20), size: Vec3d(5, 5, 5))))
    }
    
    // MARK: - From View Projection Matrix
    
    @Test("Extract frustum from identity matrix")
    func fromIdentityMatrix() {
        // Identity matrix creates a frustum in NDC space (-1 to 1)
        let frustum = Frustum.fromViewProjection(.identity)
        
        // Point at origin should be inside
        #expect(frustum.containsPoint(.zero))
    }
    
    @Test("Extract frustum from perspective matrix")
    func fromPerspectiveMatrix() {
        // Create a simple perspective projection
        let fov: Float = .pi / 4  // 45 degrees
        let aspect: Float = 16.0 / 9.0
        let near: Float = 0.1
        let far: Float = 100.0
        
        let proj = Mat4d.perspective(fovY: fov, aspect: aspect, near: near, far: far)
        let frustum = Frustum.fromViewProjection(proj)
        
        // Point at center of view (looking down -Z) should be inside
        #expect(frustum.containsPoint(Vec3d(0, 0, -10)))
        
        // Point behind camera should be outside
        #expect(!frustum.containsPoint(Vec3d(0, 0, 10)))
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty frustum")
    func emptyFrustum() {
        let frustum = Frustum(planes: [])
        // With no planes, everything should be "inside"
        #expect(frustum.containsPoint(Vec3d(1000, 1000, 1000)))
    }
    
    @Test("Single plane frustum")
    func singlePlaneFrustum() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        let frustum = Frustum(planes: [plane])
        
        #expect(frustum.containsPoint(Vec3d(0, 5, 0)))
        #expect(!frustum.containsPoint(Vec3d(0, -5, 0)))
    }
}
