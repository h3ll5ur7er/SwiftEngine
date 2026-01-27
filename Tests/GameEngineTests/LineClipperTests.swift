import Testing
@testable import GameEngine

@Suite("LineClipper Tests")
struct LineClipperTests {
    
    let epsilon: Float = 0.0001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    func isClose(_ a: Vec4d, _ b: Vec4d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z) && isClose(a.w, b.w)
    }
    
    // MARK: - Clip Line to Plane
    
    @Test("Line fully inside")
    func lineFullyInside() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Both points above the plane
        let result = LineClipper.clipLineToPlane(
            start: Vec3d(0, 5, 0),
            end: Vec3d(10, 3, 0),
            plane: plane
        )
        
        if case .fullyInside = result {
            // Expected
        } else {
            Issue.record("Expected fullyInside, got \(result)")
        }
    }
    
    @Test("Line fully outside")
    func lineFullyOutside() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Both points below the plane
        let result = LineClipper.clipLineToPlane(
            start: Vec3d(0, -5, 0),
            end: Vec3d(10, -3, 0),
            plane: plane
        )
        
        if case .fullyOutside = result {
            // Expected
        } else {
            Issue.record("Expected fullyOutside, got \(result)")
        }
    }
    
    @Test("Line clipped - start inside")
    func lineClippedStartInside() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Start above plane, end below
        let result = LineClipper.clipLineToPlane(
            start: Vec3d(0, 5, 0),
            end: Vec3d(0, -5, 0),
            plane: plane
        )
        
        if case .clipped(let newStart, let newEnd) = result {
            #expect(isClose(newStart, Vec3d(0, 5, 0)))
            #expect(isClose(newEnd, Vec3d(0, 0, 0)))  // Intersection at Y = 0
        } else {
            Issue.record("Expected clipped, got \(result)")
        }
    }
    
    @Test("Line clipped - end inside")
    func lineClippedEndInside() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Start below plane, end above
        let result = LineClipper.clipLineToPlane(
            start: Vec3d(0, -5, 0),
            end: Vec3d(0, 5, 0),
            plane: plane
        )
        
        if case .clipped(let newStart, let newEnd) = result {
            #expect(isClose(newStart, Vec3d(0, 0, 0)))  // Intersection at Y = 0
            #expect(isClose(newEnd, Vec3d(0, 5, 0)))
        } else {
            Issue.record("Expected clipped, got \(result)")
        }
    }
    
    @Test("Line clipped at angle")
    func lineClippedAtAngle() {
        let plane = Plane.fromPointNormal(point: .zero, normal: Vec3d(0, 1, 0))
        
        // Diagonal line crossing the plane
        let result = LineClipper.clipLineToPlane(
            start: Vec3d(0, 2, 0),
            end: Vec3d(4, -2, 0),
            plane: plane
        )
        
        if case .clipped(let newStart, let newEnd) = result {
            #expect(isClose(newStart, Vec3d(0, 2, 0)))
            // Intersection: t = 2/(2+2) = 0.5, so x = 2, y = 0
            #expect(isClose(newEnd, Vec3d(2, 0, 0)))
        } else {
            Issue.record("Expected clipped, got \(result)")
        }
    }
    
    // MARK: - Clip Line to Frustum
    
    @Test("Line fully inside frustum")
    func lineFullyInsideFrustum() {
        // Create a simple frustum (box-like for testing)
        let planes = [
            Plane.fromPointNormal(point: Vec3d(-10, 0, 0), normal: Vec3d(1, 0, 0)),   // Left
            Plane.fromPointNormal(point: Vec3d(10, 0, 0), normal: Vec3d(-1, 0, 0)),   // Right
            Plane.fromPointNormal(point: Vec3d(0, -10, 0), normal: Vec3d(0, 1, 0)),   // Bottom
            Plane.fromPointNormal(point: Vec3d(0, 10, 0), normal: Vec3d(0, -1, 0)),   // Top
            Plane.fromPointNormal(point: Vec3d(0, 0, -10), normal: Vec3d(0, 0, 1)),   // Near
            Plane.fromPointNormal(point: Vec3d(0, 0, 10), normal: Vec3d(0, 0, -1)),   // Far
        ]
        let frustum = Frustum(planes: planes)
        
        let result = LineClipper.clipLineToFrustum(
            start: Vec3d(0, 0, 0),
            end: Vec3d(5, 5, 5),
            frustum: frustum
        )
        
        if case .fullyInside = result {
            // Expected
        } else {
            Issue.record("Expected fullyInside, got \(result)")
        }
    }
    
    @Test("Line fully outside frustum")
    func lineFullyOutsideFrustum() {
        let planes = [
            Plane.fromPointNormal(point: Vec3d(-10, 0, 0), normal: Vec3d(1, 0, 0)),
            Plane.fromPointNormal(point: Vec3d(10, 0, 0), normal: Vec3d(-1, 0, 0)),
            Plane.fromPointNormal(point: Vec3d(0, -10, 0), normal: Vec3d(0, 1, 0)),
            Plane.fromPointNormal(point: Vec3d(0, 10, 0), normal: Vec3d(0, -1, 0)),
            Plane.fromPointNormal(point: Vec3d(0, 0, -10), normal: Vec3d(0, 0, 1)),
            Plane.fromPointNormal(point: Vec3d(0, 0, 10), normal: Vec3d(0, 0, -1)),
        ]
        let frustum = Frustum(planes: planes)
        
        // Line completely outside on the right
        let result = LineClipper.clipLineToFrustum(
            start: Vec3d(20, 0, 0),
            end: Vec3d(30, 0, 0),
            frustum: frustum
        )
        
        if case .fullyOutside = result {
            // Expected
        } else {
            Issue.record("Expected fullyOutside, got \(result)")
        }
    }
    
    // MARK: - Clip Line to Near Plane (Homogeneous Coordinates)
    
    @Test("Both vertices in front of near plane")
    func bothVerticesInFront() {
        let v0 = Vec4d(0, 0, -1, 1)
        let v1 = Vec4d(1, 1, -2, 2)
        
        let (_, _, visible) = LineClipper.clipLineToNearPlane(v0: v0, v1: v1)
        #expect(visible)
    }
    
    @Test("Both vertices behind near plane")
    func bothVerticesBehind() {
        let v0 = Vec4d(0, 0, 0, 0.0001)
        let v1 = Vec4d(1, 1, 0, 0.00005)
        
        let (_, _, visible) = LineClipper.clipLineToNearPlane(v0: v0, v1: v1)
        #expect(!visible)
    }
    
    @Test("One vertex behind near plane - v0 behind")
    func oneVertexBehindV0() {
        let v0 = Vec4d(0, 0, 0, 0.0001)  // Behind (w < nearW)
        let v1 = Vec4d(1, 1, -1, 1)       // In front
        
        let (clippedV0, clippedV1, visible) = LineClipper.clipLineToNearPlane(v0: v0, v1: v1)
        
        #expect(visible)
        #expect(isClose(clippedV0.w, 0.001))  // Should be clipped to nearW
        #expect(isClose(clippedV1, v1))        // v1 unchanged
    }
    
    @Test("One vertex behind near plane - v1 behind")
    func oneVertexBehindV1() {
        let v0 = Vec4d(1, 1, -1, 1)       // In front
        let v1 = Vec4d(0, 0, 0, 0.0001)   // Behind (w < nearW)
        
        let (clippedV0, clippedV1, visible) = LineClipper.clipLineToNearPlane(v0: v0, v1: v1)
        
        #expect(visible)
        #expect(isClose(clippedV0, v0))        // v0 unchanged
        #expect(isClose(clippedV1.w, 0.001))   // Should be clipped to nearW
    }
    
    @Test("Custom near plane threshold")
    func customNearPlane() {
        let v0 = Vec4d(0, 0, 0, 0.5)  // In front if nearW = 0.1
        let v1 = Vec4d(1, 1, -1, 1)
        
        let (_, _, visible) = LineClipper.clipLineToNearPlane(v0: v0, v1: v1, nearW: 0.1)
        #expect(visible)
    }
}
