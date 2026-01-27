import Testing
@testable import GameEngine

@Suite("Transform Tests")
struct TransformTests {
    
    let epsilon: Float = 0.001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    func isClose(_ a: Quaternion, _ b: Quaternion) -> Bool {
        let same = isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z) && isClose(a.w, b.w)
        let opposite = isClose(a.x, -b.x) && isClose(a.y, -b.y) && isClose(a.z, -b.z) && isClose(a.w, -b.w)
        return same || opposite
    }
    
    // MARK: - Initialization
    
    @Test("Default initialization")
    func defaultInit() {
        let t = Transform()
        #expect(isClose(t.localPosition, .zero))
        #expect(isClose(t.localRotation, .identity))
        #expect(isClose(t.localScale, .one))
    }
    
    @Test("Custom initialization")
    func customInit() {
        let pos = Vec3d(1, 2, 3)
        let rot = Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2)
        let scale = Vec3d(2, 2, 2)
        
        let t = Transform(position: pos, rotation: rot, scale: scale)
        
        #expect(isClose(t.localPosition, pos))
        #expect(isClose(t.localRotation, rot))
        #expect(isClose(t.localScale, scale))
    }
    
    // MARK: - Direction Vectors
    
    @Test("Forward direction - no rotation")
    func forwardNoRotation() {
        let t = Transform()
        // Forward is -Z in our coordinate system
        #expect(isClose(t.forward, Vec3d(0, 0, -1)))
    }
    
    @Test("Right direction - no rotation")
    func rightNoRotation() {
        let t = Transform()
        #expect(isClose(t.right, Vec3d(1, 0, 0)))
    }
    
    @Test("Up direction - no rotation")
    func upNoRotation() {
        let t = Transform()
        #expect(isClose(t.up, Vec3d(0, 1, 0)))
    }
    
    @Test("Forward direction - rotated 90 degrees around Y")
    func forwardRotated90Y() {
        let t = Transform(rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2))
        // After rotating 90° around Y, forward (-Z) becomes (-X)
        #expect(isClose(t.forward, Vec3d(-1, 0, 0)))
    }
    
    @Test("Right direction - rotated 90 degrees around Y")
    func rightRotated90Y() {
        let t = Transform(rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2))
        // After rotating 90° around Y, right (+X) becomes (-Z)
        #expect(isClose(t.right, Vec3d(0, 0, -1)))
    }
    
    // MARK: - Local Matrix
    
    @Test("Local matrix - identity transform")
    func localMatrixIdentity() {
        let t = Transform()
        let m = t.localMatrix
        
        // Should be identity matrix
        #expect(isClose(m.m00, 1) && isClose(m.m11, 1) && isClose(m.m22, 1) && isClose(m.m33, 1))
        #expect(isClose(m.m03, 0) && isClose(m.m13, 0) && isClose(m.m23, 0))
    }
    
    @Test("Local matrix - translation only")
    func localMatrixTranslation() {
        let t = Transform(position: Vec3d(5, 10, 15))
        let m = t.localMatrix
        
        // Translation should be in the last column
        #expect(isClose(m.m03, 5))
        #expect(isClose(m.m13, 10))
        #expect(isClose(m.m23, 15))
    }
    
    @Test("Local matrix - scale only")
    func localMatrixScale() {
        let t = Transform(scale: Vec3d(2, 3, 4))
        let m = t.localMatrix
        
        // Scale should be on the diagonal
        #expect(isClose(m.m00, 2))
        #expect(isClose(m.m11, 3))
        #expect(isClose(m.m22, 4))
    }
    
    // MARK: - Hierarchy
    
    @Test("World position without parent")
    func worldPositionNoParent() {
        let t = Transform(position: Vec3d(5, 10, 15))
        #expect(isClose(t.position, Vec3d(5, 10, 15)))
    }
    
    @Test("World position with parent")
    func worldPositionWithParent() {
        let parent = Transform(position: Vec3d(100, 0, 0))
        let child = Transform(position: Vec3d(10, 0, 0))
        parent.addChild(child)
        
        // Child's world position = parent position + child local position
        #expect(isClose(child.position, Vec3d(110, 0, 0)))
    }
    
    @Test("World position with rotated parent")
    func worldPositionWithRotatedParent() {
        let parent = Transform(rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2))
        let child = Transform(position: Vec3d(10, 0, 0))
        parent.addChild(child)
        
        // Child at local (10, 0, 0), parent rotated 90° around Y
        // Should place child at world (0, 0, -10)
        #expect(isClose(child.position, Vec3d(0, 0, -10)))
    }
    
    @Test("World rotation with parent")
    func worldRotationWithParent() {
        let parent = Transform(rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2))
        let child = Transform(rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2))
        parent.addChild(child)
        
        // Combined rotation should be 180° around Y
        let expected = Quaternion.fromAxisAngle(axis: .unitY, angle: .pi)
        #expect(isClose(child.rotation, expected))
    }
    
    @Test("Lossy scale with parent")
    func lossyScaleWithParent() {
        let parent = Transform(scale: Vec3d(2, 2, 2))
        let child = Transform(scale: Vec3d(3, 3, 3))
        parent.addChild(child)
        
        // Combined scale
        #expect(isClose(child.lossyScale, Vec3d(6, 6, 6)))
    }
    
    @Test("Add and remove child")
    func addRemoveChild() {
        let parent = Transform()
        let child = Transform()
        
        parent.addChild(child)
        #expect(parent.children.count == 1)
        #expect(child.parent === parent)
        
        parent.removeChild(child)
        #expect(parent.children.count == 0)
        #expect(child.parent == nil)
    }
    
    @Test("Remove from parent")
    func removeFromParent() {
        let parent = Transform()
        let child = Transform()
        
        parent.addChild(child)
        child.removeFromParent()
        
        #expect(parent.children.count == 0)
        #expect(child.parent == nil)
    }
    
    @Test("Reparenting")
    func reparenting() {
        let parent1 = Transform()
        let parent2 = Transform()
        let child = Transform()
        
        parent1.addChild(child)
        #expect(parent1.children.count == 1)
        
        parent2.addChild(child)
        #expect(parent1.children.count == 0)
        #expect(parent2.children.count == 1)
        #expect(child.parent === parent2)
    }
    
    // MARK: - Transform Methods
    
    @Test("Translate in local space")
    func translateLocal() {
        let t = Transform(
            position: Vec3d(0, 0, 0),
            rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2)
        )
        
        t.translate(Vec3d(10, 0, 0), relativeTo: .local)
        
        // Local X after 90° Y rotation becomes world -Z
        #expect(isClose(t.localPosition, Vec3d(0, 0, -10)))
    }
    
    @Test("Translate in world space")
    func translateWorld() {
        let t = Transform(
            position: Vec3d(0, 0, 0),
            rotation: Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2)
        )
        
        t.translate(Vec3d(10, 0, 0), relativeTo: .world)
        
        // World X is always world X regardless of rotation
        #expect(isClose(t.position, Vec3d(10, 0, 0)))
    }
    
    @Test("Rotate in local space")
    func rotateLocal() {
        let t = Transform()
        let rot = Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2)
        
        t.rotate(rot, relativeTo: .local)
        
        #expect(isClose(t.localRotation, rot))
    }
    
    @Test("Rotate by axis and angle")
    func rotateByAxisAngle() {
        let t = Transform()
        t.rotate(axis: .unitY, angle: .pi / 2)
        
        let expected = Quaternion.fromAxisAngle(axis: .unitY, angle: .pi / 2)
        #expect(isClose(t.localRotation, expected))
    }
    
    // MARK: - Look At
    
    @Test("Look at target in front")
    func lookAtFront() {
        let t = Transform(position: Vec3d(0, 0, 0))
        t.lookAt(Vec3d(0, 0, -10))
        
        // After lookAt, the transform's +Z axis points at target
        // The direction from transform to target should match the transform's +Z axis
        let toTarget = Vec3d(0, 0, -10).normalized
        let positiveZ = t.rotation * Vec3d(0, 0, 1)
        #expect(isClose(positiveZ, toTarget))
    }
    
    @Test("Look at target on right")
    func lookAtRight() {
        let t = Transform(position: Vec3d(0, 0, 0))
        t.lookAt(Vec3d(10, 0, 0))
        
        // After lookAt, the transform's +Z axis should point toward +X
        let toTarget = Vec3d(10, 0, 0).normalized
        let positiveZ = t.rotation * Vec3d(0, 0, 1)
        #expect(isClose(positiveZ, toTarget))
    }
    
    // MARK: - Transform Point
    
    @Test("Transform point - translation")
    func transformPointTranslation() {
        let t = Transform(position: Vec3d(10, 20, 30))
        let local = Vec3d(1, 2, 3)
        let world = t.transformPoint(local)
        
        #expect(isClose(world, Vec3d(11, 22, 33)))
    }
    
    @Test("Transform point - scale")
    func transformPointScale() {
        let t = Transform(scale: Vec3d(2, 2, 2))
        let local = Vec3d(1, 2, 3)
        let world = t.transformPoint(local)
        
        #expect(isClose(world, Vec3d(2, 4, 6)))
    }
    
    @Test("Transform direction - ignores translation")
    func transformDirectionIgnoresTranslation() {
        let t = Transform(position: Vec3d(100, 100, 100))
        let localDir = Vec3d(1, 0, 0)
        let worldDir = t.transformDirection(localDir)
        
        #expect(isClose(worldDir, Vec3d(1, 0, 0)))
    }
    
    @Test("Inverse transform point")
    func inverseTransformPoint() {
        let t = Transform(position: Vec3d(10, 20, 30))
        let world = Vec3d(15, 25, 35)
        let local = t.inverseTransformPoint(world)
        
        #expect(isClose(local, Vec3d(5, 5, 5)))
    }
    
    // MARK: - Cache Invalidation
    
    @Test("Position change invalidates cache")
    func positionChangeInvalidatesCache() {
        let t = Transform(position: Vec3d(0, 0, 0))
        
        // Access matrix to cache it
        _ = t.worldMatrix
        
        // Change position
        t.localPosition = Vec3d(10, 0, 0)
        
        // Matrix should reflect new position
        let m = t.worldMatrix
        #expect(isClose(m.m03, 10))
    }
    
    @Test("Parent change invalidates child cache")
    func parentChangeInvalidatesChildCache() {
        let parent = Transform(position: Vec3d(100, 0, 0))
        let child = Transform(position: Vec3d(10, 0, 0))
        parent.addChild(child)
        
        // Access to cache
        _ = child.worldMatrix
        
        // Move parent
        parent.localPosition = Vec3d(200, 0, 0)
        
        // Child's world position should update
        #expect(isClose(child.position, Vec3d(210, 0, 0)))
    }
}
