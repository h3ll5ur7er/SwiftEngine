import Foundation
import Testing
@testable import GameEngine

@Suite("Quaternion Tests")
struct QuaternionTests {
    
    let epsilon: Float32 = 0.001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z)
    }
    
    func isClose(_ a: Quaternion, _ b: Quaternion) -> Bool {
        // Quaternions q and -q represent the same rotation
        let same = isClose(a.x, b.x) && isClose(a.y, b.y) && isClose(a.z, b.z) && isClose(a.w, b.w)
        let opposite = isClose(a.x, -b.x) && isClose(a.y, -b.y) && isClose(a.z, -b.z) && isClose(a.w, -b.w)
        return same || opposite
    }
    
    @Test("Quaternion identity")
    func identity() {
        let q = Quaternion.identity
        #expect(q.x == 0 && q.y == 0 && q.z == 0 && q.w == 1)
        
        // Identity should not rotate
        let v = Vec3d(1, 2, 3)
        let rotated = q * v
        #expect(isClose(rotated, v))
    }
    
    @Test("Quaternion from axis angle")
    func fromAxisAngle() {
        // 90 degree rotation around Z axis
        let q = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: .pi / 2)
        let v = Vec3d(1, 0, 0)
        let rotated = q * v
        
        // Should rotate (1,0,0) to (0,1,0)
        #expect(isClose(rotated, Vec3d(0, 1, 0)))
    }
    
    @Test("Quaternion multiplication")
    func multiplication() {
        // Two 90 degree rotations around Z should equal one 180 degree rotation
        let q90 = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: .pi / 2)
        let q180 = q90 * q90
        
        let v = Vec3d(1, 0, 0)
        let rotated = q180 * v
        
        // 180 degrees around Z: (1,0,0) -> (-1,0,0)
        #expect(isClose(rotated, Vec3d(-1, 0, 0)))
    }
    
    @Test("Quaternion length and normalized")
    func lengthAndNormalized() {
        let q = Quaternion(1, 2, 3, 4)
        let len = q.length
        #expect(isClose(len, sqrt(30))) // 1+4+9+16 = 30
        
        let norm = q.normalized
        #expect(isClose(norm.length, 1))
    }
    
    @Test("Quaternion conjugate")
    func conjugate() {
        let q = Quaternion(1, 2, 3, 4)
        let conj = q.conjugate
        
        #expect(conj.x == -1)
        #expect(conj.y == -2)
        #expect(conj.z == -3)
        #expect(conj.w == 4)
    }
    
    @Test("Quaternion inverse")
    func inverse() {
        let q = Quaternion.fromAxisAngle(axis: Vec3d.unitY, angle: .pi / 3)
        let inv = q.inverse
        
        // q * q^-1 should equal identity
        let result = q * inv
        #expect(isClose(result, Quaternion.identity))
    }
    
    @Test("Quaternion to matrix")
    func toMatrix() {
        let q = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: .pi / 2)
        let mat = q.toMat4d
        
        // Test that matrix rotation matches quaternion rotation
        let v = Vec3d(1, 0, 0)
        let qRotated = q * v
        let mRotated = mat.transformDirection(v)
        
        #expect(isClose(qRotated, mRotated))
    }
    
    @Test("Quaternion slerp")
    func slerp() {
        let q0 = Quaternion.identity
        let q1 = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: .pi / 2)
        
        // At t=0, should equal q0
        let t0 = q0.slerp(to: q1, t: 0)
        #expect(isClose(t0, q0))
        
        // At t=1, should equal q1
        let t1 = q0.slerp(to: q1, t: 1)
        #expect(isClose(t1, q1))
        
        // At t=0.5, should be half rotation (45 degrees)
        let tHalf = q0.slerp(to: q1, t: 0.5)
        let v = Vec3d(1, 0, 0)
        let rotated = tHalf * v
        
        // 45 degrees: (1,0,0) -> (cos45, sin45, 0) ≈ (0.707, 0.707, 0)
        let expected = Vec3d(sqrt(2)/2, sqrt(2)/2, 0)
        #expect(isClose(rotated, expected))
    }
    
    @Test("Quaternion from euler angles")
    func fromEulerAngles() {
        // Test that Euler angles create consistent rotations
        let q = Quaternion.fromEulerAngles(pitch: .pi / 2, yaw: 0, roll: 0)
        let v = Vec3d(1, 0, 0)
        let rotated = q * v
        
        // The rotation should move the vector from the X axis
        // After pitch rotation, the X component should be near zero
        #expect(isClose(rotated.x, 0))
    }
    
    @Test("Quaternion euler angles roundtrip")
    func eulerAnglesRoundtrip() {
        let pitch: Float32 = 0.3
        let yaw: Float32 = 0.5
        let roll: Float32 = 0.2
        
        let q = Quaternion.fromEulerAngles(pitch: pitch, yaw: yaw, roll: roll)
        let (p, y, r) = q.eulerAngles
        
        #expect(isClose(p, pitch))
        #expect(isClose(y, yaw))
        #expect(isClose(r, roll))
    }
    
    @Test("Quaternion axis and angle")
    func axisAndAngle() {
        let originalAxis = Vec3d(1, 1, 0).normalized
        let originalAngle: Float32 = .pi / 3
        
        let q = Quaternion.fromAxisAngle(axis: originalAxis, angle: originalAngle)
        
        #expect(isClose(q.axis, originalAxis))
        #expect(isClose(q.angle, originalAngle))
    }
    
    @Test("Quaternion fromTo")
    func fromTo() {
        let from = Vec3d.unitX
        let to = Vec3d.unitY
        
        let q = Quaternion.fromTo(from: from, to: to)
        let rotated = q * from
        
        #expect(isClose(rotated, to))
    }
    
    @Test("Quaternion fromTo same direction")
    func fromToSameDirection() {
        let v = Vec3d(1, 2, 3).normalized
        let q = Quaternion.fromTo(from: v, to: v)
        
        #expect(isClose(q, Quaternion.identity))
    }
    
    @Test("Quaternion fromTo opposite direction")
    func fromToOppositeDirection() {
        let from = Vec3d.unitX
        let to = -Vec3d.unitX
        
        let q = Quaternion.fromTo(from: from, to: to)
        let rotated = q * from
        
        #expect(isClose(rotated, to))
    }
    
    @Test("Quaternion dot product")
    func dotProduct() {
        let q1 = Quaternion.identity
        let q2 = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: .pi)
        
        // Identity and 180 degree rotation should have dot = 0 (w components cancel)
        // Actually identity is (0,0,0,1) and 180 around Z is (0,0,1,0)
        let dot = q1.dot(q2)
        #expect(isClose(dot, 0))
    }
    
    @Test("Quaternion lookRotation")
    func lookRotation() {
        let forward = Vec3d(0, 0, -1)
        let up = Vec3d.unitY
        
        let q = Quaternion.lookRotation(forward: forward, up: up)
        
        // Should rotate unitZ to forward direction
        let result = q * Vec3d.unitZ
        #expect(isClose(result, forward))
    }
    
    @Test("Quaternion combined rotations match matrix")
    func combinedRotationsMatchMatrix() {
        let qx = Quaternion.fromAxisAngle(axis: Vec3d.unitX, angle: 0.3)
        let qy = Quaternion.fromAxisAngle(axis: Vec3d.unitY, angle: 0.5)
        let qz = Quaternion.fromAxisAngle(axis: Vec3d.unitZ, angle: 0.2)
        
        let qCombined = qz * qy * qx
        let mCombined = Mat4d.rotZ(angle: 0.2) * Mat4d.rotY(angle: 0.5) * Mat4d.rotX(angle: 0.3)
        
        let v = Vec3d(1, 2, 3).normalized
        let qRotated = qCombined * v
        let mRotated = mCombined.transformDirection(v)
        
        #expect(isClose(qRotated, mRotated))
    }
}
