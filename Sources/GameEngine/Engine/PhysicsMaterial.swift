import Foundation

/// Defines the physical properties of a surface for collision response
/// This struct is Sendable so it can be safely passed between actors
public struct PhysicsMaterial: Sendable {
    
    /// Friction coefficient (0 = no friction, 1 = high friction)
    /// Controls how much objects resist sliding against each other
    public var friction: Float
    
    /// Bounciness/restitution (0 = no bounce, 1 = perfect bounce)
    /// Controls how much energy is preserved on collision
    public var bounciness: Float
    
    /// Density in kg/m³ (used to calculate mass from collider volume)
    /// Common values: Water ~1000, Wood ~600, Steel ~7800, Rubber ~1100
    public var density: Float
    
    /// How friction is combined between two colliding materials
    public var frictionCombine: CombineMode
    
    /// How bounciness is combined between two colliding materials
    public var bounceCombine: CombineMode
    
    /// How to combine material properties from two colliders
    public enum CombineMode: Sendable {
        case average    // (a + b) / 2
        case minimum    // min(a, b)
        case maximum    // max(a, b)
        case multiply   // a * b
    }
    
    public init(
        friction: Float = 0.4,
        bounciness: Float = 0.0,
        density: Float = 1000.0,
        frictionCombine: CombineMode = .average,
        bounceCombine: CombineMode = .average
    ) {
        self.friction = friction
        self.bounciness = bounciness
        self.density = density
        self.frictionCombine = frictionCombine
        self.bounceCombine = bounceCombine
    }
    
    // MARK: - Preset Materials
    
    /// Default material with moderate friction and no bounce
    public static let `default` = PhysicsMaterial(friction: 0.4, bounciness: 0.0, density: 1000.0)
    
    /// Bouncy rubber-like material
    public static let rubber = PhysicsMaterial(friction: 0.8, bounciness: 0.8, density: 1100.0)
    
    /// Slippery ice-like material
    public static let ice = PhysicsMaterial(friction: 0.05, bounciness: 0.1, density: 917.0)
    
    /// Heavy metal material
    public static let metal = PhysicsMaterial(friction: 0.3, bounciness: 0.2, density: 7800.0)
    
    /// Light wood material
    public static let wood = PhysicsMaterial(friction: 0.5, bounciness: 0.3, density: 600.0)
    
    /// Bouncy ball material (super bouncy)
    public static let bouncyBall = PhysicsMaterial(friction: 0.6, bounciness: 0.95, density: 500.0)
    
    /// Stone/concrete material
    public static let stone = PhysicsMaterial(friction: 0.6, bounciness: 0.1, density: 2400.0)
    
    // MARK: - Combination
    
    /// Combine two values using the specified mode
    public static func combine(_ a: Float, _ b: Float, mode: CombineMode) -> Float {
        switch mode {
        case .average:
            return (a + b) / 2.0
        case .minimum:
            return min(a, b)
        case .maximum:
            return max(a, b)
        case .multiply:
            return a * b
        }
    }
    
    /// Get combined friction between two materials
    public static func combinedFriction(_ a: PhysicsMaterial, _ b: PhysicsMaterial) -> Float {
        // Use the mode that results in lower friction (more conservative)
        let modeA = a.frictionCombine
        let modeB = b.frictionCombine
        let resultA = combine(a.friction, b.friction, mode: modeA)
        let resultB = combine(a.friction, b.friction, mode: modeB)
        return min(resultA, resultB)
    }
    
    /// Get combined bounciness between two materials
    public static func combinedBounciness(_ a: PhysicsMaterial, _ b: PhysicsMaterial) -> Float {
        // Use the mode that results in higher bounciness
        let modeA = a.bounceCombine
        let modeB = b.bounceCombine
        let resultA = combine(a.bounciness, b.bounciness, mode: modeA)
        let resultB = combine(a.bounciness, b.bounciness, mode: modeB)
        return max(resultA, resultB)
    }
}
