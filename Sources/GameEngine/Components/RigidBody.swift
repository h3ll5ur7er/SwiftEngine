import Foundation

/// Component that enables physics simulation for a GameObject
/// Uses the PhysicsSystem for synchronous physics processing
@MainActor
public final class RigidBody: Component {
    
    /// Mass of the body (in kg)
    public var mass: Float = 1.0 {
        didSet { updatePhysicsBody() }
    }
    
    /// Whether the body is kinematic (not affected by forces)
    public var isKinematic: Bool = false {
        didSet { updatePhysicsBody() }
    }
    
    /// Current linear velocity
    public private(set) var velocity: Vec3d = .zero
    
    /// Current angular velocity (radians per second around each axis)
    public private(set) var angularVelocity: Vec3d = .zero
    
    /// Angular drag (0 = no drag, 1 = full drag)
    public var angularDrag: Float = 0.05
    
    /// Maximum linear velocity magnitude (prevents explosion)
    public var maxVelocity: Float = 50.0
    
    /// Maximum angular velocity magnitude (radians per second)
    public var maxAngularVelocity: Float = 20.0
    
    /// Accumulated forces to be applied next physics step
    public private(set) var accumulatedForce: Vec3d = .zero
    
    /// Accumulated torques to be applied next physics step
    public private(set) var accumulatedTorque: Vec3d = .zero
    
    /// Whether the body is registered with physics
    private var isRegistered: Bool = false
    
    // MARK: - Initialization
    
    public required init() {
        super.init()
    }
    
    public convenience init(mass: Float, isKinematic: Bool = false) {
        self.init()
        self.mass = mass
        self.isKinematic = isKinematic
    }
    
    // MARK: - Lifecycle
    
    public override func onEnable() {
        registerWithPhysics()
    }
    
    public override func onDisable() {
        unregisterFromPhysics()
    }
    
    public override func onDestroy() {
        unregisterFromPhysics()
    }
    
    // MARK: - Physics Registration
    
    private func registerWithPhysics() {
        guard !isRegistered else { return }
        isRegistered = true
        
        // Register with synchronous PhysicsSystem
        PhysicsSystem.shared.register(self)
    }
    
    private func unregisterFromPhysics() {
        guard isRegistered else { return }
        isRegistered = false
        
        // Unregister from PhysicsSystem
        PhysicsSystem.shared.unregister(self)
    }
    
    private func updatePhysicsBody() {
        // No-op for now - PhysicsSystem reads directly from component
    }
    
    // MARK: - Forces
    
    /// Apply a force to the body (will be applied next physics step)
    public func addForce(_ force: Vec3d) {
        guard !isKinematic else { return }
        accumulatedForce = Vec3d(
            accumulatedForce.x + force.x,
            accumulatedForce.y + force.y,
            accumulatedForce.z + force.z
        )
    }
    
    /// Apply a torque to the body (will be applied next physics step)
    public func addTorque(_ torque: Vec3d) {
        guard !isKinematic else { return }
        accumulatedTorque = Vec3d(
            accumulatedTorque.x + torque.x,
            accumulatedTorque.y + torque.y,
            accumulatedTorque.z + torque.z
        )
    }
    
    /// Apply an impulse to the body (instant velocity change)
    public func addImpulse(_ impulse: Vec3d) {
        guard !isKinematic else { return }
        let scaledImpulse = Vec3d(impulse.x / mass, impulse.y / mass, impulse.z / mass)
        let newVel = Vec3d(velocity.x + scaledImpulse.x, velocity.y + scaledImpulse.y, velocity.z + scaledImpulse.z)
        velocity = clampVelocity(newVel, maxMagnitude: maxVelocity)
    }
    
    /// Apply an angular impulse to the body (instant angular velocity change)
    public func addAngularImpulse(_ impulse: Vec3d) {
        guard !isKinematic else { return }
        // Simplified: assume uniform inertia = mass
        let scaledImpulse = Vec3d(impulse.x / mass, impulse.y / mass, impulse.z / mass)
        let newAngVel = Vec3d(
            angularVelocity.x + scaledImpulse.x,
            angularVelocity.y + scaledImpulse.y,
            angularVelocity.z + scaledImpulse.z
        )
        angularVelocity = clampVelocity(newAngVel, maxMagnitude: maxAngularVelocity)
    }
    
    /// Clear accumulated forces (called by PhysicsSystem after integration)
    public func clearForces() {
        accumulatedForce = .zero
        accumulatedTorque = .zero
    }
    
    /// Set the velocity directly (with clamping)
    public func setVelocity(_ newVelocity: Vec3d) {
        velocity = clampVelocity(newVelocity, maxMagnitude: maxVelocity)
    }
    
    /// Set the angular velocity directly (with clamping)
    public func setAngularVelocity(_ newAngularVelocity: Vec3d) {
        angularVelocity = clampVelocity(newAngularVelocity, maxMagnitude: maxAngularVelocity)
    }
    
    /// Clamp a velocity vector to a maximum magnitude
    private func clampVelocity(_ v: Vec3d, maxMagnitude: Float) -> Vec3d {
        let magSq = v.x * v.x + v.y * v.y + v.z * v.z
        if magSq > maxMagnitude * maxMagnitude {
            let mag = sqrt(magSq)
            let scale = maxMagnitude / mag
            return Vec3d(v.x * scale, v.y * scale, v.z * scale)
        }
        return v
    }
    
    /// Set velocity and sync to physics actor (deprecated - use setVelocity)
    public func setVelocityAndSync(_ newVelocity: Vec3d) {
        velocity = newVelocity
    }
    
    // MARK: - State Sync
    
    /// Called by the engine to sync physics state back to this component
    internal func syncFromPhysics(state: PhysicsBodyState) {
        velocity = state.velocity
    }
}
