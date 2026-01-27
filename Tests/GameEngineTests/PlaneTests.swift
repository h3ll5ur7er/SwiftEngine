import Testing
@testable import GameEngine

@Suite("Plane Tests")
struct PlaneTests {
    
    let epsilon: Float = 0.0001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    // MARK: - Initialization
    
    @Test("Direct initialization")
    func directInit() {
        let plane = Plane(normal: Vec3d(0, 1, 0), distance: -5)
        #expect(isClose(plane.normal, Vec3d(0, 1, 0)))
        #expect(isClose(plane.distance, -5))
    }
    
    // MARK: - From Points
    
    @Test("Create plane from three points - XZ plane")
    func fromPointsXZ() {
        // Three points on the XZ plane (Y = 0)
        let p0 = Vec3d(0, 0, 0)
        let p1 = Vec3d(1, 0, 0)
        let p2 = Vec3d(0, 0, 1)
        
        let plane = Plane.fromPoints(p0, p1, p2)
        
        // Normal should point up (Y+) for counter-clockwise winding
        #expect(isClose(plane.normal.y, 1.0) || isClose(plane.normal.y, -1.0))
        #expect(isClose(plane.normal.x, 0))
        #expect(isClose(plane.normal.z, 0))
    }
    
    @Test("Create plane from three points - XY plane")
    func fromPointsXY() {
        let p0 = Vec3d(0, 0, 0)
        let p1 = Vec3d(1, 0, 0)
        let p2 = Vec3d(0, 1, 0)
        
        let plane = Plane.fromPoints(p0, p1, p2)
        
        // Normal should point in Z direction
        #expect(isClose(abs(plane.normal.z), 1.0))
        #expect(isClose(plane.normal.x, 0))
        #expect(isClose(plane.normal.y, 0))
    }
    
    // MARK: - From Point and Normal
    
    @Test("Create plane from point and normal")
    func fromPointNormal() {
        let point = Vec3d(0, 5, 0)
        let normal = Vec3d(0, 1, 0)
        
        let plane = Plane.fromPointNormal(point: point, normal: normal)
        
        #expect(isClose(plane.normal, Vec3d(0, 1, 0)))
        // The point should lie on the plane (distance to point = 0)
        #expect(isClose(plane.distanceToPoint(point), 0))
    }
    
    @Test("From point normal normalizes direction")
    func fromPointNormalNormalizes() {
        let point = Vec3d(0, 0, 0)
        let normal = Vec3d(0, 10, 0)  // Not unit length
        
        let plane = Plane.fromPointNormal(point: point, normal: normal)
        
        // Normal should be normalized
        #expect(isClose(plane.normal.length, 1.0))
        #expect(isClose(plane.normal, Vec3d(0, 1, 0)))
    }
    
    // MARK: - Distance to Point
    
    @Test("Distance to point in front")
    func distanceToPointInFront() {
        // Horizontal plane at Y = 0, normal pointing up
        let plane = Plane.fromPointNormal(point: Vec3d(0, 0, 0), normal: Vec3d(0, 1, 0))
        
        // Point above the plane
        let distance = plane.distanceToPoint(Vec3d(0, 5, 0))
        #expect(isClose(distance, 5))
    }
    
    @Test("Distance to point behind")
    func distanceToPointBehind() {
        // Horizontal plane at Y = 0, normal pointing up
        let plane = Plane.fromPointNormal(point: Vec3d(0, 0, 0), normal: Vec3d(0, 1, 0))
        
        // Point below the plane
        let distance = plane.distanceToPoint(Vec3d(0, -3, 0))
        #expect(isClose(distance, -3))
    }
    
    @Test("Distance to point on plane")
    func distanceToPointOnPlane() {
        let plane = Plane.fromPointNormal(point: Vec3d(0, 5, 0), normal: Vec3d(0, 1, 0))
        
        // Point exactly on the plane
        let distance = plane.distanceToPoint(Vec3d(10, 5, -20))
        #expect(isClose(distance, 0))
    }
    
    // MARK: - Is In Front
    
    @Test("Point is in front of plane")
    func isInFront() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        #expect(plane.isInFront(Vec3d(0, 1, 0)))
        #expect(plane.isInFront(Vec3d(0, 100, 0)))
    }
    
    @Test("Point is behind plane")
    func isBehind() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        #expect(!plane.isInFront(Vec3d(0, -1, 0)))
        #expect(!plane.isInFront(Vec3d(0, -100, 0)))
    }
    
    @Test("Point on plane is not in front")
    func onPlaneNotInFront() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Point exactly on plane (distance = 0) is not strictly "in front"
        #expect(!plane.isInFront(Vec3d(5, 0, 5)))
    }
    
    // MARK: - Normalized
    
    @Test("Normalize plane")
    func normalizePlane() {
        // Create a plane with non-unit normal
        let plane = Plane(normal: Vec3d(0, 2, 0), distance: -10)
        let normalized = plane.normalized
        
        #expect(isClose(normalized.normal.length, 1.0))
        #expect(isClose(normalized.normal, Vec3d(0, 1, 0)))
        #expect(isClose(normalized.distance, -5))
    }
    
    @Test("Normalize already normalized plane")
    func normalizeAlreadyNormalized() {
        let plane = Plane(normal: Vec3d(0, 1, 0), distance: -5)
        let normalized = plane.normalized
        
        #expect(isClose(normalized.normal, plane.normal))
        #expect(isClose(normalized.distance, plane.distance))
    }
    
    // MARK: - Different Orientations
    
    @Test("Vertical plane facing X")
    func verticalPlaneFacingX() {
        let plane = Plane.fromPointNormal(point: Vec3d(5, 0, 0), normal: Vec3d(1, 0, 0))
        
        #expect(plane.isInFront(Vec3d(10, 0, 0)))
        #expect(!plane.isInFront(Vec3d(0, 0, 0)))
        #expect(isClose(plane.distanceToPoint(Vec3d(8, 0, 0)), 3))
    }
    
    @Test("Diagonal plane")
    func diagonalPlane() {
        // 45-degree plane
        let normal = Vec3d(1, 1, 0).normalized
        let plane = Plane.fromPointNormal(point: .zero, normal: normal)
        
        // Point in front of the diagonal
        let dist = plane.distanceToPoint(Vec3d(1, 1, 0))
        #expect(dist > 0)
    }
}
