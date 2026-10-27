import Foundation

/// Physics system that coordinates between MainActor objects and the physics simulation
/// This class runs on MainActor and handles:
/// - Tracking RigidBody components
/// - Creating snapshots of bodies and colliders
/// - Running the simulation (inline, or on PhysicsActor via updateAsync)
/// - Applying simulation results back to GameObjects and reporting collisions
@MainActor
public final class PhysicsSystem {

    /// Shared instance
    public static let shared = PhysicsSystem()

    /// Shared timer for performance measurement
    private let timer = sharedTimer

    /// All registered rigid bodies
    private var rigidBodies: [RigidBody] = []

    /// Mapping from GameUUID to RigidBody for fast lookup when applying results
    private var bodyLookup: [GameUUID: RigidBody] = [:]

    /// Fixed-timestep simulation used by the synchronous update
    private var simulation = PhysicsSimulation()

    /// Whether physics simulation is enabled
    public var isEnabled: Bool = true

    /// Simulation parameters (timestep, gravity, ...)
    public var settings: PhysicsSettings {
        get { simulation.settings }
        set { simulation.settings = newValue }
    }

    /// Gravity vector
    public var gravity: Vec3d {
        get { simulation.settings.gravity }
        set { simulation.settings.gravity = newValue }
    }

    // MARK: - Statistics

    /// Number of collisions detected this frame
    public private(set) var collisionsThisFrame: Int = 0

    /// Number of physics steps executed this frame
    public private(set) var stepsThisFrame: Int = 0

    /// Time spent waiting for physics (milliseconds)
    public private(set) var waitTimeMs: Double = 0

    private init() {}

    // MARK: - Body Registration

    /// Register a rigid body with the physics system
    public func register(_ rigidBody: RigidBody) {
        if !rigidBodies.contains(where: { $0 === rigidBody }) {
            rigidBodies.append(rigidBody)
            if let go = rigidBody.gameObject {
                bodyLookup[go.id] = rigidBody
            }
        }
    }

    /// Unregister a rigid body from the physics system
    public func unregister(_ rigidBody: RigidBody) {
        rigidBodies.removeAll { $0 === rigidBody }
        if let go = rigidBody.gameObject {
            bodyLookup.removeValue(forKey: go.id)
        }
    }

    // MARK: - Simulation

    /// Synchronous physics update - runs simulation inline on main thread
    /// For async simulation, use updateAsync() instead
    public func update(deltaTime: Float) {
        guard isEnabled else { return }

        let startTime = timer.currentTimeMillis()

        let (input, colliders) = createPhysicsInput(deltaTime: deltaTime)
        let result = simulation.simulate(input)
        apply(result, colliders: colliders)

        waitTimeMs = Double(timer.currentTimeMillis() - startTime)
    }

    /// Run physics simulation asynchronously on PhysicsActor
    /// Call this from an async context (e.g., the game loop)
    public func updateAsync(deltaTime: Float) async {
        guard isEnabled else { return }

        let startTime = timer.currentTimeMillis()

        let (input, colliders) = createPhysicsInput(deltaTime: deltaTime)
        let result = await PhysicsActor.shared.simulate(input: input)
        apply(result, colliders: colliders)

        waitTimeMs = Double(timer.currentTimeMillis() - startTime)
    }

    /// Create physics input from current state, plus the colliders matching each snapshot
    private func createPhysicsInput(deltaTime: Float) -> (PhysicsFrameInput, [Collider]) {
        // Gather body states
        var bodies: [GameUUID: PhysicsBodyState] = [:]

        for rigidBody in rigidBodies {
            guard let gameObject = rigidBody.gameObject, gameObject.isActive else { continue }

            let state = PhysicsBodyState(
                id: gameObject.id,
                position: gameObject.transform.position,
                velocity: rigidBody.velocity,
                rotation: gameObject.transform.rotation,
                angularVelocity: rigidBody.angularVelocity,
                mass: rigidBody.mass,
                isKinematic: rigidBody.isKinematic,
                angularDrag: rigidBody.angularDrag,
                maxVelocity: rigidBody.maxVelocity,
                maxAngularVelocity: rigidBody.maxAngularVelocity,
                accumulatedForce: rigidBody.accumulatedForce,
                accumulatedTorque: rigidBody.accumulatedTorque
            )
            bodies[gameObject.id] = state
        }

        // Gather collider snapshots
        var colliders: [ColliderSnapshot] = []
        var sourceColliders: [Collider] = []

        for collider in CollisionManager.shared.allColliders {
            guard collider.isEnabled, let gameObject = collider.gameObject, gameObject.isActive else { continue }

            let colliderType: ColliderSnapshot.ColliderType

            if let boxCollider = collider as? BoxCollider {
                colliderType = .box(halfExtents: boxCollider.halfExtents)
            } else if let sphereCollider = collider as? SphereCollider {
                colliderType = .sphere(radius: sphereCollider.radius)
            } else if let planeCollider = collider as? PlaneCollider {
                // Plane uses world-space normal and the distance from origin
                let worldNormal = planeCollider.worldNormal
                let worldPoint = planeCollider.worldCenter
                // Plane equation: normal · point = offset
                let offset = worldNormal.x * worldPoint.x + worldNormal.y * worldPoint.y + worldNormal.z * worldPoint.z
                colliderType = .plane(normal: worldNormal, offset: offset)
            } else {
                continue  // Unknown collider type
            }

            let snapshot = ColliderSnapshot(
                bodyId: gameObject.id,
                type: colliderType,
                worldCenter: collider.worldCenter,
                worldRotation: gameObject.transform.rotation,
                isTrigger: collider.isTrigger,
                layer: collider.layer,
                material: collider.material,
                boundingSphereRadius: collider.boundingSphereRadius
            )
            colliders.append(snapshot)
            sourceColliders.append(collider)
        }

        return (PhysicsFrameInput(bodies: bodies, colliders: colliders, deltaTime: deltaTime), sourceColliders)
    }

    /// Apply physics results back to GameObjects and report collisions
    private func apply(_ result: PhysicsStepResult, colliders: [Collider]) {
        collisionsThisFrame = result.collisions.count
        stepsThisFrame = result.stepsExecuted

        // Nothing moved; keep pending forces for the next step
        guard result.stepsExecuted > 0 else { return }

        for (id, bodyState) in result.updatedBodies {
            guard let rigidBody = bodyLookup[id], !rigidBody.isKinematic else { continue }
            guard let gameObject = rigidBody.gameObject else { continue }

            // Update transform
            gameObject.transform.position = bodyState.position
            gameObject.transform.rotation = bodyState.rotation

            // Update rigid body state
            rigidBody.setVelocity(bodyState.velocity)
            rigidBody.setAngularVelocity(bodyState.angularVelocity)
            rigidBody.clearForces()
        }

        reportCollisions(result.collisions, colliders: colliders)
    }

    /// Report each colliding pair once per frame through CollisionManager.onCollision
    private func reportCollisions(_ collisions: [CollisionPair], colliders: [Collider]) {
        guard let onCollision = CollisionManager.shared.onCollision else { return }

        // Keep the latest contact for each pair (pairs can collide in several steps)
        var latest: [Int: CollisionPair] = [:]
        var order: [Int] = []
        for pair in collisions {
            let key = pair.colliderIndexA * colliders.count + pair.colliderIndexB
            if latest.updateValue(pair, forKey: key) == nil {
                order.append(key)
            }
        }

        for key in order {
            let pair = latest[key]!
            let a = colliders[pair.colliderIndexA]
            let b = colliders[pair.colliderIndexB]
            let info = CollisionInfo(
                other: b,
                contactPoint: pair.contactPoint,
                normal: pair.normal,
                penetrationDepth: pair.penetrationDepth
            )
            onCollision(a, b, info)
        }
    }

    // MARK: - Utilities

    /// Clear all registered bodies
    public func clear() {
        rigidBodies.removeAll()
        bodyLookup.removeAll()
        simulation.resetAccumulator()
    }

    /// Get count of registered bodies
    public var bodyCount: Int {
        rigidBodies.count
    }

    /// Get count of active (non-kinematic) bodies
    public var activeBodyCount: Int {
        rigidBodies.filter { !$0.isKinematic }.count
    }
}
