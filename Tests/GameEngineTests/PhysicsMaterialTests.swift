import Testing
@testable import GameEngine

@Suite("PhysicsMaterial Tests")
struct PhysicsMaterialTests {
    
    let epsilon: Float = 0.0001
    
    func isClose(_ a: Float, _ b: Float) -> Bool {
        abs(a - b) < epsilon
    }
    
    // MARK: - Initialization
    
    @Test("Default initialization")
    func defaultInit() {
        let mat = PhysicsMaterial()
        #expect(isClose(mat.friction, 0.4))
        #expect(isClose(mat.bounciness, 0.0))
        #expect(isClose(mat.density, 1000.0))
        #expect(mat.frictionCombine == .average)
        #expect(mat.bounceCombine == .average)
    }
    
    @Test("Custom initialization")
    func customInit() {
        let mat = PhysicsMaterial(
            friction: 0.7,
            bounciness: 0.5,
            density: 500.0,
            frictionCombine: .minimum,
            bounceCombine: .maximum
        )
        #expect(isClose(mat.friction, 0.7))
        #expect(isClose(mat.bounciness, 0.5))
        #expect(isClose(mat.density, 500.0))
        #expect(mat.frictionCombine == .minimum)
        #expect(mat.bounceCombine == .maximum)
    }
    
    // MARK: - Presets
    
    @Test("Default preset")
    func defaultPreset() {
        let mat = PhysicsMaterial.default
        #expect(isClose(mat.friction, 0.4))
        #expect(isClose(mat.bounciness, 0.0))
        #expect(isClose(mat.density, 1000.0))
    }
    
    @Test("Rubber preset")
    func rubberPreset() {
        let mat = PhysicsMaterial.rubber
        #expect(isClose(mat.friction, 0.8))
        #expect(isClose(mat.bounciness, 0.8))
        #expect(isClose(mat.density, 1100.0))
    }
    
    @Test("Ice preset")
    func icePreset() {
        let mat = PhysicsMaterial.ice
        #expect(isClose(mat.friction, 0.05))
        #expect(isClose(mat.bounciness, 0.1))
        #expect(isClose(mat.density, 917.0))
    }
    
    @Test("Metal preset")
    func metalPreset() {
        let mat = PhysicsMaterial.metal
        #expect(isClose(mat.friction, 0.3))
        #expect(isClose(mat.bounciness, 0.2))
        #expect(isClose(mat.density, 7800.0))
    }
    
    @Test("Wood preset")
    func woodPreset() {
        let mat = PhysicsMaterial.wood
        #expect(isClose(mat.friction, 0.5))
        #expect(isClose(mat.bounciness, 0.3))
        #expect(isClose(mat.density, 600.0))
    }
    
    @Test("Bouncy ball preset")
    func bouncyBallPreset() {
        let mat = PhysicsMaterial.bouncyBall
        #expect(isClose(mat.friction, 0.6))
        #expect(isClose(mat.bounciness, 0.95))
        #expect(isClose(mat.density, 500.0))
    }
    
    @Test("Stone preset")
    func stonePreset() {
        let mat = PhysicsMaterial.stone
        #expect(isClose(mat.friction, 0.6))
        #expect(isClose(mat.bounciness, 0.1))
        #expect(isClose(mat.density, 2400.0))
    }
    
    // MARK: - Combine Modes
    
    @Test("Combine mode: average")
    func combineAverage() {
        let result = PhysicsMaterial.combine(0.4, 0.8, mode: .average)
        #expect(isClose(result, 0.6))
    }
    
    @Test("Combine mode: minimum")
    func combineMinimum() {
        let result = PhysicsMaterial.combine(0.4, 0.8, mode: .minimum)
        #expect(isClose(result, 0.4))
    }
    
    @Test("Combine mode: maximum")
    func combineMaximum() {
        let result = PhysicsMaterial.combine(0.4, 0.8, mode: .maximum)
        #expect(isClose(result, 0.8))
    }
    
    @Test("Combine mode: multiply")
    func combineMultiply() {
        let result = PhysicsMaterial.combine(0.4, 0.8, mode: .multiply)
        #expect(isClose(result, 0.32))
    }
    
    // MARK: - Combined Friction
    
    @Test("Combined friction with same mode")
    func combinedFrictionSameMode() {
        let a = PhysicsMaterial(friction: 0.4, frictionCombine: .average)
        let b = PhysicsMaterial(friction: 0.8, frictionCombine: .average)
        let combined = PhysicsMaterial.combinedFriction(a, b)
        #expect(isClose(combined, 0.6))
    }
    
    @Test("Combined friction takes minimum result")
    func combinedFrictionTakesMinimum() {
        // One uses average (0.6), one uses minimum (0.4)
        // Should return the lower result (0.4)
        let a = PhysicsMaterial(friction: 0.4, frictionCombine: .average)
        let b = PhysicsMaterial(friction: 0.8, frictionCombine: .minimum)
        let combined = PhysicsMaterial.combinedFriction(a, b)
        #expect(isClose(combined, 0.4))
    }
    
    @Test("Combined friction rubber on ice")
    func combinedFrictionRubberOnIce() {
        // Rubber (0.8) on ice (0.05) - should be very slippery
        let combined = PhysicsMaterial.combinedFriction(.rubber, .ice)
        // Average mode: (0.8 + 0.05) / 2 = 0.425
        // Result should be low due to ice
        #expect(combined < 0.5)
    }
    
    // MARK: - Combined Bounciness
    
    @Test("Combined bounciness with same mode")
    func combinedBouncinessSameMode() {
        let a = PhysicsMaterial(bounciness: 0.3, bounceCombine: .average)
        let b = PhysicsMaterial(bounciness: 0.7, bounceCombine: .average)
        let combined = PhysicsMaterial.combinedBounciness(a, b)
        #expect(isClose(combined, 0.5))
    }
    
    @Test("Combined bounciness takes maximum result")
    func combinedBouncinessTakesMaximum() {
        // One uses average (0.5), one uses maximum (0.7)
        // Should return the higher result (0.7)
        let a = PhysicsMaterial(bounciness: 0.3, bounceCombine: .average)
        let b = PhysicsMaterial(bounciness: 0.7, bounceCombine: .maximum)
        let combined = PhysicsMaterial.combinedBounciness(a, b)
        #expect(isClose(combined, 0.7))
    }
    
    @Test("Combined bounciness bouncy ball on stone")
    func combinedBouncinessBallOnStone() {
        // Bouncy ball (0.95) on stone (0.1) - ball should still bounce
        let combined = PhysicsMaterial.combinedBounciness(.bouncyBall, .stone)
        // Should be relatively bouncy due to the ball
        #expect(combined > 0.4)
    }
    
    // MARK: - Edge Cases
    
    @Test("Combine zero values")
    func combineZeroValues() {
        #expect(isClose(PhysicsMaterial.combine(0, 0, mode: .average), 0))
        #expect(isClose(PhysicsMaterial.combine(0, 0, mode: .minimum), 0))
        #expect(isClose(PhysicsMaterial.combine(0, 0, mode: .maximum), 0))
        #expect(isClose(PhysicsMaterial.combine(0, 0, mode: .multiply), 0))
    }
    
    @Test("Combine one values")
    func combineOneValues() {
        #expect(isClose(PhysicsMaterial.combine(1, 1, mode: .average), 1))
        #expect(isClose(PhysicsMaterial.combine(1, 1, mode: .minimum), 1))
        #expect(isClose(PhysicsMaterial.combine(1, 1, mode: .maximum), 1))
        #expect(isClose(PhysicsMaterial.combine(1, 1, mode: .multiply), 1))
    }
    
    @Test("Combine with zero")
    func combineWithZero() {
        #expect(isClose(PhysicsMaterial.combine(0.5, 0, mode: .average), 0.25))
        #expect(isClose(PhysicsMaterial.combine(0.5, 0, mode: .minimum), 0))
        #expect(isClose(PhysicsMaterial.combine(0.5, 0, mode: .maximum), 0.5))
        #expect(isClose(PhysicsMaterial.combine(0.5, 0, mode: .multiply), 0))
    }
}
