import Testing
@testable import GameEngine

@Suite("Mat3d Tests")
struct Mat3dTests {
    
    let epsilon: Float32 = 0.0001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    func isClose(_ a: Mat3d, _ b: Mat3d) -> Bool {
        isClose(a.m00, b.m00) && isClose(a.m01, b.m01) && isClose(a.m02, b.m02) &&
        isClose(a.m10, b.m10) && isClose(a.m11, b.m11) && isClose(a.m12, b.m12) &&
        isClose(a.m20, b.m20) && isClose(a.m21, b.m21) && isClose(a.m22, b.m22)
    }
    
    @Test("Mat3d identity")
    func identity() {
        let i = Mat3d.identity
        #expect(i.m00 == 1 && i.m01 == 0 && i.m02 == 0)
        #expect(i.m10 == 0 && i.m11 == 1 && i.m12 == 0)
        #expect(i.m20 == 0 && i.m21 == 0 && i.m22 == 1)
    }
    
    @Test("Mat3d multiplication with identity")
    func multiplicationWithIdentity() {
        let m = Mat3d(m00: 1, m01: 2, m02: 3,
                      m10: 4, m11: 5, m12: 6,
                      m20: 7, m21: 8, m22: 9)
        let result = m * Mat3d.identity
        #expect(isClose(result, m))
    }
    
    @Test("Mat3d matrix multiplication")
    func matrixMultiplication() {
        let a = Mat3d(m00: 1, m01: 2, m02: 3,
                      m10: 4, m11: 5, m12: 6,
                      m20: 7, m21: 8, m22: 9)
        let b = Mat3d.identity
        
        // Multiplying by identity should give same matrix
        let result = a * b
        #expect(isClose(result, a))
    }
    
    @Test("Mat3d vector multiplication")
    func vectorMultiplication() {
        let scale = Mat3d.scale(sx: 2, sy: 3, sz: 4)
        let v = Vec3d(1, 1, 1)
        let result = scale * v
        
        #expect(isClose(result, Vec3d(2, 3, 4)))
    }
    
    @Test("Mat3d rotation X")
    func rotationX() {
        let rot = Mat3d.rotX(angle: .pi / 2)
        let v = Vec3d(0, 1, 0)
        let rotated = rot * v
        
        // 90 degree rotation around X of (0,1,0) should be (0,0,1)
        #expect(isClose(rotated, Vec3d(0, 0, 1)))
    }
    
    @Test("Mat3d rotation Y")
    func rotationY() {
        let rot = Mat3d.rotY(angle: .pi / 2)
        let v = Vec3d(0, 0, 1)
        let rotated = rot * v
        
        // 90 degree rotation around Y of (0,0,1) should be (1,0,0)
        #expect(isClose(rotated, Vec3d(1, 0, 0)))
    }
    
    @Test("Mat3d rotation Z")
    func rotationZ() {
        let rot = Mat3d.rotZ(angle: .pi / 2)
        let v = Vec3d(1, 0, 0)
        let rotated = rot * v
        
        // 90 degree rotation around Z of (1,0,0) should be (0,1,0)
        #expect(isClose(rotated, Vec3d(0, 1, 0)))
    }
    
    @Test("Mat3d scale")
    func scale() {
        let scale = Mat3d.scale(sx: 2, sy: 3, sz: 4)
        let v = Vec3d(1, 2, 3)
        let scaled = scale * v
        
        #expect(isClose(scaled, Vec3d(2, 6, 12)))
    }
    
    @Test("Mat3d transpose")
    func transpose() {
        let m = Mat3d(m00: 1, m01: 2, m02: 3,
                      m10: 4, m11: 5, m12: 6,
                      m20: 7, m21: 8, m22: 9)
        let t = m.transposed
        
        #expect(isClose(t.m00, 1) && isClose(t.m01, 4) && isClose(t.m02, 7))
        #expect(isClose(t.m10, 2) && isClose(t.m11, 5) && isClose(t.m12, 8))
        #expect(isClose(t.m20, 3) && isClose(t.m21, 6) && isClose(t.m22, 9))
    }
    
    @Test("Mat3d determinant")
    func determinant() {
        // Use a matrix with known determinant
        let m = Mat3d(m00: 1, m01: 2, m02: 3,
                      m10: 0, m11: 1, m12: 4,
                      m20: 5, m21: 6, m22: 0)
        // det = 1*(1*0-4*6) - 2*(0*0-4*5) + 3*(0*6-1*5)
        //     = 1*(-24) - 2*(-20) + 3*(-5)
        //     = -24 + 40 - 15 = 1
        #expect(isClose(m.determinant, 1))
    }
    
    @Test("Mat3d inverse")
    func inverse() {
        let m = Mat3d(m00: 1, m01: 2, m02: 3,
                      m10: 0, m11: 1, m12: 4,
                      m20: 5, m21: 6, m22: 0)
        guard let inv = m.inverse else {
            Issue.record("Matrix should be invertible")
            return
        }
        
        // M * M^-1 should equal identity
        let result = m * inv
        #expect(isClose(result, Mat3d.identity))
    }
    
    @Test("Mat3d fromEulerAngles")
    func fromEulerAngles() {
        // Test that rotation matrices compose correctly
        let combined = Mat3d.fromEulerAngles(rx: .pi/4, ry: .pi/4, rz: .pi/4)
        let separate = Mat3d.rotZ(angle: .pi/4) * Mat3d.rotY(angle: .pi/4) * Mat3d.rotX(angle: .pi/4)
        
        #expect(isClose(combined, separate))
    }
}
