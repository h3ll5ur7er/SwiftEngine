import Testing
@testable import GameEngine

@Suite("Mat2d Tests")
struct Mat2dTests {
    
    let epsilon: Float32 = 0.0001
    
    func isClose(_ a: Float32, _ b: Float32) -> Bool {
        abs(a - b) < epsilon
    }
    
    func isClose(_ a: Mat2d, _ b: Mat2d) -> Bool {
        isClose(a.m00, b.m00) && isClose(a.m01, b.m01) &&
        isClose(a.m10, b.m10) && isClose(a.m11, b.m11)
    }
    
    func isClose(_ a: Vec2d, _ b: Vec2d) -> Bool {
        isClose(a.x, b.x) && isClose(a.y, b.y)
    }
    
    @Test("Mat2d identity")
    func identity() {
        let i = Mat2d.identity
        #expect(i.m00 == 1 && i.m01 == 0)
        #expect(i.m10 == 0 && i.m11 == 1)
    }
    
    @Test("Mat2d matrix multiplication with identity")
    func multiplicationWithIdentity() {
        let m = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let result = m * Mat2d.identity
        #expect(isClose(result, m))
        
        let result2 = Mat2d.identity * m
        #expect(isClose(result2, m))
    }
    
    @Test("Mat2d matrix multiplication")
    func matrixMultiplication() {
        let a = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let b = Mat2d(m00: 5, m01: 6, m10: 7, m11: 8)
        let result = a * b
        
        // [1 2] * [5 6] = [1*5+2*7  1*6+2*8] = [19 22]
        // [3 4]   [7 8]   [3*5+4*7  3*6+4*8]   [43 50]
        #expect(isClose(result.m00, 19))
        #expect(isClose(result.m01, 22))
        #expect(isClose(result.m10, 43))
        #expect(isClose(result.m11, 50))
    }
    
    @Test("Mat2d vector multiplication")
    func vectorMultiplication() {
        let m = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let v = Vec2d(5, 6)
        let result = m * v
        
        // [1 2] * [5] = [1*5+2*6] = [17]
        // [3 4]   [6]   [3*5+4*6]   [39]
        #expect(isClose(result, Vec2d(17, 39)))
    }
    
    @Test("Mat2d rotation")
    func rotation() {
        let rot90 = Mat2d.rotation(angle: .pi / 2)
        let v = Vec2d(1, 0)
        let rotated = rot90 * v
        
        // 90 degree rotation of (1,0) should be (0,1)
        #expect(isClose(rotated, Vec2d(0, 1)))
    }
    
    @Test("Mat2d scale")
    func scale() {
        let scale = Mat2d.scale(sx: 2, sy: 3)
        let v = Vec2d(4, 5)
        let scaled = scale * v
        
        #expect(isClose(scaled, Vec2d(8, 15)))
    }
    
    @Test("Mat2d transpose")
    func transpose() {
        let m = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let t = m.transposed
        
        #expect(isClose(t.m00, 1))
        #expect(isClose(t.m01, 3))
        #expect(isClose(t.m10, 2))
        #expect(isClose(t.m11, 4))
    }
    
    @Test("Mat2d determinant")
    func determinant() {
        let m = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        // det = 1*4 - 2*3 = -2
        #expect(isClose(m.determinant, -2))
    }
    
    @Test("Mat2d inverse")
    func inverse() {
        let m = Mat2d(m00: 4, m01: 7, m10: 2, m11: 6)
        guard let inv = m.inverse else {
            Issue.record("Matrix should be invertible")
            return
        }
        
        // M * M^-1 should equal identity
        let result = m * inv
        #expect(isClose(result, Mat2d.identity))
    }
    
    @Test("Mat2d singular matrix inverse")
    func singularInverse() {
        // Singular matrix (determinant = 0)
        let m = Mat2d(m00: 1, m01: 2, m10: 2, m11: 4)
        #expect(m.inverse == nil)
    }
    
    @Test("Mat2d addition and subtraction")
    func additionSubtraction() {
        let a = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let b = Mat2d(m00: 5, m01: 6, m10: 7, m11: 8)
        
        let sum = a + b
        #expect(isClose(sum, Mat2d(m00: 6, m01: 8, m10: 10, m11: 12)))
        
        let diff = a - b
        #expect(isClose(diff, Mat2d(m00: -4, m01: -4, m10: -4, m11: -4)))
    }
    
    @Test("Mat2d scalar multiplication")
    func scalarMultiplication() {
        let m = Mat2d(m00: 1, m01: 2, m10: 3, m11: 4)
        let result = m * 2
        #expect(isClose(result, Mat2d(m00: 2, m01: 4, m10: 6, m11: 8)))
    }
}
