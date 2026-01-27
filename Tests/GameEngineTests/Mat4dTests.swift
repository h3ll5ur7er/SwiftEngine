import Testing
@testable import GameEngine

@Suite("Mat4d Tests")
struct Mat4dTests {
    
    let epsilon: Float32 = 0.001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    func isClose(_ a: Vec4d, _ b: Vec4d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z) && isClose(a.w, b.w)
    }
    
    func isClose(_ a: Mat4d, _ b: Mat4d) -> Bool {
        isClose(a.m00, b.m00) && isClose(a.m01, b.m01) && isClose(a.m02, b.m02) && isClose(a.m03, b.m03) &&
        isClose(a.m10, b.m10) && isClose(a.m11, b.m11) && isClose(a.m12, b.m12) && isClose(a.m13, b.m13) &&
        isClose(a.m20, b.m20) && isClose(a.m21, b.m21) && isClose(a.m22, b.m22) && isClose(a.m23, b.m23) &&
        isClose(a.m30, b.m30) && isClose(a.m31, b.m31) && isClose(a.m32, b.m32) && isClose(a.m33, b.m33)
    }
    
    @Test("Mat4d identity")
    func identity() {
        let i = Mat4d.identity
        #expect(i.m00 == 1 && i.m11 == 1 && i.m22 == 1 && i.m33 == 1)
    }
    
    @Test("Mat4d multiplication with identity")
    func multiplicationWithIdentity() {
        let m = Mat4d(m00: 1, m01: 2, m02: 3, m03: 4,
                      m10: 5, m11: 6, m12: 7, m13: 8,
                      m20: 9, m21: 10, m22: 11, m23: 12,
                      m30: 13, m31: 14, m32: 15, m33: 16)
        let result = m * Mat4d.identity
        #expect(isClose(result, m))
    }
    
    @Test("Mat4d vector multiplication")
    func vectorMultiplication() {
        let scale = Mat4d.scale(sx: 2, sy: 3, sz: 4)
        let v = Vec4d(1, 1, 1, 1)
        let result = scale * v
        
        #expect(isClose(result, Vec4d(2, 3, 4, 1)))
    }
    
    @Test("Mat4d translation")
    func translation() {
        let trans = Mat4d.translate(x: 10, y: 20, z: 30)
        let point = Vec3d(1, 2, 3)
        let translated = trans.transformPoint(point)
        
        #expect(isClose(translated, Vec3d(11, 22, 33)))
    }
    
    @Test("Mat4d rotation X")
    func rotationX() {
        let rot = Mat4d.rotX(angle: .pi / 2)
        let v = Vec3d(0, 1, 0)
        let rotated = rot.transformDirection(v)
        
        // 90 degree rotation around X of (0,1,0) should be (0,0,1)
        #expect(isClose(rotated, Vec3d(0, 0, 1)))
    }
    
    @Test("Mat4d rotation Y")
    func rotationY() {
        let rot = Mat4d.rotY(angle: .pi / 2)
        let v = Vec3d(0, 0, 1)
        let rotated = rot.transformDirection(v)
        
        // 90 degree rotation around Y of (0,0,1) should be (1,0,0)
        #expect(isClose(rotated, Vec3d(1, 0, 0)))
    }
    
    @Test("Mat4d rotation Z")
    func rotationZ() {
        let rot = Mat4d.rotZ(angle: .pi / 2)
        let v = Vec3d(1, 0, 0)
        let rotated = rot.transformDirection(v)
        
        // 90 degree rotation around Z of (1,0,0) should be (0,1,0)
        #expect(isClose(rotated, Vec3d(0, 1, 0)))
    }
    
    @Test("Mat4d scale")
    func scale() {
        let scale = Mat4d.scale(sx: 2, sy: 3, sz: 4)
        let v = Vec3d(1, 2, 3)
        let scaled = scale.transformPoint(v)
        
        #expect(isClose(scaled, Vec3d(2, 6, 12)))
    }
    
    @Test("Mat4d transpose")
    func transpose() {
        let m = Mat4d(m00: 1, m01: 2, m02: 3, m03: 4,
                      m10: 5, m11: 6, m12: 7, m13: 8,
                      m20: 9, m21: 10, m22: 11, m23: 12,
                      m30: 13, m31: 14, m32: 15, m33: 16)
        let t = m.transposed
        
        #expect(isClose(t.m00, 1) && isClose(t.m01, 5) && isClose(t.m02, 9) && isClose(t.m03, 13))
        #expect(isClose(t.m10, 2) && isClose(t.m11, 6) && isClose(t.m12, 10) && isClose(t.m13, 14))
    }
    
    @Test("Mat4d determinant")
    func determinant() {
        // Identity matrix has determinant 1
        #expect(isClose(Mat4d.identity.determinant, 1))
        
        // Scale matrix determinant = product of scales
        let scale = Mat4d.scale(sx: 2, sy: 3, sz: 4)
        #expect(isClose(scale.determinant, 24))
    }
    
    @Test("Mat4d inverse")
    func inverse() {
        let m = Mat4d.translate(x: 5, y: 10, z: 15) * Mat4d.rotZ(angle: .pi / 4) * Mat4d.scale(sx: 2, sy: 2, sz: 2)
        guard let inv = m.inverse else {
            Issue.record("Matrix should be invertible")
            return
        }
        
        // M * M^-1 should equal identity
        let result = m * inv
        #expect(isClose(result, Mat4d.identity))
    }
    
    @Test("Mat4d transformPoint vs transformDirection")
    func transformPointVsDirection() {
        let m = Mat4d.translate(x: 10, y: 0, z: 0)
        let v = Vec3d(1, 0, 0)
        
        // transformPoint should apply translation
        let point = m.transformPoint(v)
        #expect(isClose(point, Vec3d(11, 0, 0)))
        
        // transformDirection should ignore translation
        let dir = m.transformDirection(v)
        #expect(isClose(dir, Vec3d(1, 0, 0)))
    }
    
    @Test("Mat4d lookAt")
    func lookAt() {
        let eye = Vec3d(0, 0, 5)
        let target = Vec3d(0, 0, 0)
        let up = Vec3d(0, 1, 0)
        
        let view = Mat4d.lookAt(eye: eye, target: target, up: up)
        
        // Camera at (0,0,5) looking at origin should transform origin to (0,0,-5) in view space
        let originInView = view.transformPoint(Vec3d.zero)
        #expect(isClose(originInView.z, -5))
    }
    
    @Test("Mat4d perspective")
    func perspective() {
        let proj = Mat4d.perspective(fovY: .pi / 4, aspect: 16.0 / 9.0, near: 0.1, far: 100)
        
        // Point at near plane should map to z close to -1 (after perspective divide)
        let nearPoint = proj * Vec4d(0, 0, -0.1, 1)
        let nearNDC = nearPoint.z / nearPoint.w
        #expect(isClose(nearNDC, -1))
    }
    
    @Test("Mat4d orthographic")
    func orthographic() {
        let ortho = Mat4d.orthographic(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
        
        // Point at center should stay at center
        let center = ortho.transformPoint(Vec3d.zero)
        #expect(isClose(center, Vec3d.zero))
    }
    
    @Test("Mat4d mat3 extraction")
    func mat3Extraction() {
        let m = Mat4d.rotX(angle: .pi / 4)
        let m3 = m.mat3
        
        // Upper left 3x3 should match
        #expect(isClose(m3.m00, m.m00))
        #expect(isClose(m3.m11, m.m11))
        #expect(isClose(m3.m22, m.m22))
    }
    
    @Test("Mat4d combined transformations")
    func combinedTransformations() {
        // Create a transformation: translate, then rotate, then scale
        let t = Mat4d.translate(x: 1, y: 0, z: 0)
        let r = Mat4d.rotZ(angle: .pi / 2)
        let s = Mat4d.scale(sx: 2, sy: 2, sz: 2)
        
        // Order matters! Applied right to left
        let combined = t * r * s  // First scale, then rotate, then translate
        
        // Point (1,0,0) -> scaled to (2,0,0) -> rotated to (0,2,0) -> translated to (1,2,0)
        let result = combined.transformPoint(Vec3d(1, 0, 0))
        #expect(isClose(result, Vec3d(1, 2, 0)))
    }
}
