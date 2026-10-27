import Foundation

// MARK: - Physics Actor

/// Actor that runs the physics simulation off the main actor.
/// Uses the same PhysicsSimulation as PhysicsSystem, so results are identical.
public actor PhysicsActor {

    /// Shared instance
    public static let shared = PhysicsActor()

    /// Shared timer for performance measurement
    private let timer = sharedTimer

    /// The underlying fixed-timestep simulation
    private var simulation = PhysicsSimulation()

    /// Simulation parameters
    public var settings: PhysicsSettings {
        get { simulation.settings }
        set { simulation.settings = newValue }
    }

    /// Fixed timestep for physics (default: 60Hz)
    public var fixedDeltaTime: Float { simulation.settings.fixedDeltaTime }

    /// Maximum delta time to prevent explosion (caps to 33ms)
    public var maxDeltaTime: Float { simulation.settings.maxDeltaTime }

    /// Maximum physics steps per frame to prevent spiral of death
    public var maxStepsPerFrame: Int { simulation.settings.maxStepsPerFrame }

    /// Gravity vector
    public var gravity: Vec3d { simulation.settings.gravity }

    /// Whether simulation is enabled
    public var isEnabled: Bool = true

    /// Statistics tracking
    private var totalStepsProcessed: UInt64 = 0
    private var totalProcessingTimeMs: Double = 0
    private var lastFrameSteps: Int = 0

    public init() {}

    // MARK: - Configuration

    /// Replace the simulation parameters
    public func configure(_ settings: PhysicsSettings) {
        simulation.settings = settings
    }

    /// Enable or disable the simulation
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Simulation

    /// Run physics simulation for a frame
    /// Takes snapshots of bodies and colliders, simulates, returns updated states
    public func simulate(input: PhysicsFrameInput) async -> PhysicsStepResult {
        guard isEnabled else {
            return PhysicsStepResult(updatedBodies: input.bodies, collisions: [], simulatedTime: 0, stepsExecuted: 0)
        }

        let startTime = timer.currentTimeMillis()
        let result = simulation.simulate(input)

        // Update statistics
        totalStepsProcessed += UInt64(result.stepsExecuted)
        totalProcessingTimeMs += Double(timer.currentTimeMillis() - startTime)
        lastFrameSteps = result.stepsExecuted

        return result
    }

    // MARK: - Utilities

    /// Reset accumulator (use when simulation is paused/resumed)
    public func resetAccumulator() {
        simulation.resetAccumulator()
    }

    /// Get interpolation alpha for rendering between physics steps
    public func getInterpolationAlpha() -> Float {
        simulation.interpolationAlpha
    }

    /// Get processing statistics
    public func getStatistics() -> (totalSteps: UInt64, totalTimeMs: Double, lastFrameSteps: Int) {
        return (totalStepsProcessed, totalProcessingTimeMs, lastFrameSteps)
    }

    /// Reset statistics
    public func resetStatistics() {
        totalStepsProcessed = 0
        totalProcessingTimeMs = 0
    }
}
