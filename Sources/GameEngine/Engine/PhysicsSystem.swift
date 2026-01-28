import Foundation

/// Physics system that coordinates between MainActor objects and the PhysicsActor
/// This class runs on MainActor and handles:
/// - Tracking RigidBody components
/// - Creating snapshots to send to PhysicsActor
/// - Applying simulation results back to GameObjects
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
    
    /// Whether physics simulation is enabled
    public var isEnabled: Bool = true
    
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
    
    // MARK: - Async Simulation
    
    /// Run physics simulation asynchronously
    /// Call this from an async context (e.g., the game loop)
    public func updateAsync(deltaTime: Float) async {
        guard isEnabled else { return }
        
        let startTime = timer.currentTimeMillis()
        
        // Step 1: Create snapshots of all bodies and colliders
        let input = createPhysicsInput(deltaTime: deltaTime)
        
        // Step 2: Run simulation on PhysicsActor (off main thread)
        let result = await PhysicsActor.shared.simulate(input: input)
        
        // Step 3: Apply results back to GameObjects
        applyPhysicsResult(result)
        
        // Update statistics
        waitTimeMs = Double(timer.currentTimeMillis() - startTime)
        collisionsThisFrame = result.collisions.count
        stepsThisFrame = result.stepsExecuted
    }
    
    /// Create physics input from current state
    private func createPhysicsInput(deltaTime: Float) -> PhysicsFrameInput {
        // Gather body states
        var bodies: [GameUUID: PhysicsBodyState] = [:]
        
        for rigidBody in rigidBodies {
            guard let gameObject = rigidBody.gameObject else { continue }
            
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
        }
        
        return PhysicsFrameInput(bodies: bodies, colliders: colliders, deltaTime: deltaTime)
    }
    
    /// Apply physics results back to GameObjects
    private func applyPhysicsResult(_ result: PhysicsStepResult) {
        for (id, bodyState) in result.updatedBodies {
            guard let rigidBody = bodyLookup[id] else { continue }
            guard let gameObject = rigidBody.gameObject else { continue }
            
            // Update transform
            gameObject.transform.position = bodyState.position
            gameObject.transform.rotation = bodyState.rotation
            
            // Update rigid body state
            rigidBody.setVelocity(bodyState.velocity)
            rigidBody.setAngularVelocity(bodyState.angularVelocity)
            rigidBody.clearForces()
        }
    }
    
    // MARK: - Synchronous Update
    
    /// Accumulated time for fixed timestep
    private var accumulator: Float = 0
    
    /// Fixed timestep for physics (60Hz)
    private let fixedDeltaTime: Float = 1.0 / 60.0
    
    /// Maximum delta time to prevent explosion
    private let maxDeltaTime: Float = 1.0 / 30.0
    
    /// Maximum steps per frame to prevent spiral of death
    private let maxStepsPerFrame: Int = 4
    
    /// Gravity vector
    public var gravity: Vec3d = Vec3d(0, -9.81, 0)
    
    /// Synchronous physics update - runs simulation inline on main thread
    /// For async simulation, use updateAsync() instead
    public func update(deltaTime: Float) {
        guard isEnabled else { return }
        
        let startTime = timer.currentTimeMillis()
        
        // Clamp delta time
        let clampedDt = min(deltaTime, maxDeltaTime)
        accumulator += clampedDt
        
        // Create physics input
        let input = createPhysicsInput(deltaTime: clampedDt)
        
        var allCollisions: [CollisionPair] = []
        var totalSteps = 0
        var bodies = input.bodies
        
        // Run fixed timestep simulation
        while accumulator >= fixedDeltaTime && totalSteps < maxStepsPerFrame {
            // Integrate velocities
            bodies = integrateVelocities(bodies: bodies, dt: fixedDeltaTime)
            
            // Integrate positions
            bodies = integratePositions(bodies: bodies, dt: fixedDeltaTime)
            
            // Detect collisions
            let collisions = detectCollisions(bodies: bodies, colliders: input.colliders)
            
            // Resolve collisions
            bodies = resolveCollisions(bodies: bodies, collisions: collisions)
            
            allCollisions.append(contentsOf: collisions)
            accumulator -= fixedDeltaTime
            totalSteps += 1
        }
        
        // Prevent spiral of death
        if accumulator > fixedDeltaTime * Float(maxStepsPerFrame) {
            accumulator = 0
        }
        
        // Apply results
        let result = PhysicsStepResult(
            updatedBodies: bodies,
            collisions: allCollisions,
            simulatedTime: Float(totalSteps) * fixedDeltaTime,
            stepsExecuted: totalSteps
        )
        applyPhysicsResult(result)
        
        // Update statistics
        waitTimeMs = Double(timer.currentTimeMillis() - startTime)
        collisionsThisFrame = allCollisions.count
        stepsThisFrame = totalSteps
    }
    
    // MARK: - Physics Simulation (Inline)
    
    private func integrateVelocities(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for (id, body) in bodies {
            guard !body.isKinematic else { continue }
            
            var vel = body.velocity
            var angVel = body.angularVelocity
            
            // Apply gravity
            vel = Vec3d(vel.x + gravity.x * dt, vel.y + gravity.y * dt, vel.z + gravity.z * dt)
            
            // Apply accumulated forces
            let forceAccel = body.accumulatedForce / body.mass
            vel = Vec3d(vel.x + forceAccel.x * dt, vel.y + forceAccel.y * dt, vel.z + forceAccel.z * dt)
            
            // Apply accumulated torques
            let torqueAccel = body.accumulatedTorque / body.mass
            angVel = Vec3d(angVel.x + torqueAccel.x * dt, angVel.y + torqueAccel.y * dt, angVel.z + torqueAccel.z * dt)
            
            // Apply angular drag
            let damping = 1.0 - body.angularDrag
            angVel = Vec3d(angVel.x * damping, angVel.y * damping, angVel.z * damping)
            
            // Clamp velocities
            let velMag = sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z)
            if velMag > body.maxVelocity {
                let scale = body.maxVelocity / velMag
                vel = Vec3d(vel.x * scale, vel.y * scale, vel.z * scale)
            }
            
            let angVelMag = sqrt(angVel.x * angVel.x + angVel.y * angVel.y + angVel.z * angVel.z)
            if angVelMag > body.maxAngularVelocity {
                let scale = body.maxAngularVelocity / angVelMag
                angVel = Vec3d(angVel.x * scale, angVel.y * scale, angVel.z * scale)
            }
            
            var updated = body
            updated.velocity = vel
            updated.angularVelocity = angVel
            updated.accumulatedForce = .zero
            updated.accumulatedTorque = .zero
            result[id] = updated
        }
        
        return result
    }
    
    private func integratePositions(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for (id, body) in bodies {
            guard !body.isKinematic else { continue }
            
            let newPos = Vec3d(
                body.position.x + body.velocity.x * dt,
                body.position.y + body.velocity.y * dt,
                body.position.z + body.velocity.z * dt
            )
            
            var newRot = body.rotation
            let angSpeed = sqrt(body.angularVelocity.x * body.angularVelocity.x +
                               body.angularVelocity.y * body.angularVelocity.y +
                               body.angularVelocity.z * body.angularVelocity.z)
            if angSpeed > 0.0001 {
                let axis = Vec3d(
                    body.angularVelocity.x / angSpeed,
                    body.angularVelocity.y / angSpeed,
                    body.angularVelocity.z / angSpeed
                )
                let deltaRotation = Quaternion.fromAxisAngle(axis: axis, angle: angSpeed * dt)
                newRot = deltaRotation * body.rotation
            }
            
            var updated = body
            updated.position = newPos
            updated.rotation = newRot
            result[id] = updated
        }
        
        return result
    }
    
    private func detectCollisions(bodies: [GameUUID: PhysicsBodyState], colliders: [ColliderSnapshot]) -> [CollisionPair] {
        var collisions: [CollisionPair] = []
        
        // Update collider positions based on body positions
        var updatedColliders: [(ColliderSnapshot, Vec3d)] = []
        for collider in colliders {
            if let body = bodies[collider.bodyId] {
                updatedColliders.append((collider, body.position))
            } else {
                updatedColliders.append((collider, collider.worldCenter))
            }
        }
        
        // O(n²) collision detection
        for i in 0..<updatedColliders.count {
            for j in (i + 1)..<updatedColliders.count {
                let (colliderA, posA) = updatedColliders[i]
                let (colliderB, posB) = updatedColliders[j]
                
                if colliderA.isTrigger && colliderB.isTrigger { continue }
                if colliderA.layer != 0 && colliderB.layer != 0 && colliderA.layer != colliderB.layer { continue }
                
                // Broad phase
                let radiusA = colliderA.boundingSphereRadius
                let radiusB = colliderB.boundingSphereRadius
                if !radiusA.isInfinite && !radiusB.isInfinite {
                    let dx = posB.x - posA.x
                    let dy = posB.y - posA.y
                    let dz = posB.z - posA.z
                    let distSq = dx * dx + dy * dy + dz * dz
                    let radiusSum = radiusA + radiusB
                    if distSq > radiusSum * radiusSum { continue }
                }
                
                // Narrow phase
                if let collision = narrowPhaseCollision(colliderA: colliderA, posA: posA, indexA: i,
                                                        colliderB: colliderB, posB: posB, indexB: j) {
                    collisions.append(collision)
                }
            }
        }
        
        return collisions
    }
    
    private func narrowPhaseCollision(colliderA: ColliderSnapshot, posA: Vec3d, indexA: Int,
                                      colliderB: ColliderSnapshot, posB: Vec3d, indexB: Int) -> CollisionPair? {
        switch (colliderA.type, colliderB.type) {
        case (.box(let halfA), .box(let halfB)):
            return boxVsBox(colliderA: colliderA, posA: posA, halfA: halfA, indexA: indexA,
                           colliderB: colliderB, posB: posB, halfB: halfB, indexB: indexB)
        case (.plane(let normal, let offset), .box(let half)):
            return planeVsBox(planeCollider: colliderA, normal: normal, offset: offset, planeIndex: indexA,
                             boxCollider: colliderB, boxPos: posB, half: half, boxIndex: indexB, planeIsA: true)
        case (.box(let half), .plane(let normal, let offset)):
            return planeVsBox(planeCollider: colliderB, normal: normal, offset: offset, planeIndex: indexB,
                             boxCollider: colliderA, boxPos: posA, half: half, boxIndex: indexA, planeIsA: false)
        case (.sphere(let rA), .sphere(let rB)):
            return sphereVsSphere(colliderA: colliderA, posA: posA, rA: rA, indexA: indexA,
                                 colliderB: colliderB, posB: posB, rB: rB, indexB: indexB)
        case (.plane(let normal, let offset), .sphere(let r)):
            return planeVsSphere(planeCollider: colliderA, normal: normal, offset: offset, planeIndex: indexA,
                                sphereCollider: colliderB, spherePos: posB, radius: r, sphereIndex: indexB, planeIsA: true)
        case (.sphere(let r), .plane(let normal, let offset)):
            return planeVsSphere(planeCollider: colliderB, normal: normal, offset: offset, planeIndex: indexB,
                                sphereCollider: colliderA, spherePos: posA, radius: r, sphereIndex: indexA, planeIsA: false)
        case (.box(let half), .sphere(let r)):
            return boxVsSphere(boxCollider: colliderA, boxPos: posA, half: half, boxIndex: indexA,
                              sphereCollider: colliderB, spherePos: posB, radius: r, sphereIndex: indexB, boxIsA: true)
        case (.sphere(let r), .box(let half)):
            return boxVsSphere(boxCollider: colliderB, boxPos: posB, half: half, boxIndex: indexB,
                              sphereCollider: colliderA, spherePos: posA, radius: r, sphereIndex: indexA, boxIsA: false)
        case (.plane, .plane):
            return nil
        }
    }
    
    private func boxVsBox(colliderA: ColliderSnapshot, posA: Vec3d, halfA: Vec3d, indexA: Int,
                          colliderB: ColliderSnapshot, posB: Vec3d, halfB: Vec3d, indexB: Int) -> CollisionPair? {
        let minA = Vec3d(posA.x - halfA.x, posA.y - halfA.y, posA.z - halfA.z)
        let maxA = Vec3d(posA.x + halfA.x, posA.y + halfA.y, posA.z + halfA.z)
        let minB = Vec3d(posB.x - halfB.x, posB.y - halfB.y, posB.z - halfB.z)
        let maxB = Vec3d(posB.x + halfB.x, posB.y + halfB.y, posB.z + halfB.z)
        
        if maxA.x < minB.x || minA.x > maxB.x { return nil }
        if maxA.y < minB.y || minA.y > maxB.y { return nil }
        if maxA.z < minB.z || minA.z > maxB.z { return nil }
        
        let overlapX = min(maxA.x - minB.x, maxB.x - minA.x)
        let overlapY = min(maxA.y - minB.y, maxB.y - minA.y)
        let overlapZ = min(maxA.z - minB.z, maxB.z - minA.z)
        
        var normal: Vec3d
        var penetration: Float
        
        if overlapX <= overlapY && overlapX <= overlapZ {
            penetration = overlapX
            normal = posB.x > posA.x ? Vec3d(1, 0, 0) : Vec3d(-1, 0, 0)
        } else if overlapY <= overlapX && overlapY <= overlapZ {
            penetration = overlapY
            normal = posB.y > posA.y ? Vec3d(0, 1, 0) : Vec3d(0, -1, 0)
        } else {
            penetration = overlapZ
            normal = posB.z > posA.z ? Vec3d(0, 0, 1) : Vec3d(0, 0, -1)
        }
        
        let contact = Vec3d(
            (max(minA.x, minB.x) + min(maxA.x, maxB.x)) / 2,
            (max(minA.y, minB.y) + min(maxA.y, maxB.y)) / 2,
            (max(minA.z, minB.z) + min(maxA.z, maxB.z)) / 2
        )
        
        return CollisionPair(bodyIdA: colliderA.bodyId, bodyIdB: colliderB.bodyId,
                            colliderIndexA: indexA, colliderIndexB: indexB,
                            contactPoint: contact, normal: normal, penetrationDepth: penetration,
                            materialA: colliderA.material, materialB: colliderB.material)
    }
    
    private func planeVsBox(planeCollider: ColliderSnapshot, normal: Vec3d, offset: Float, planeIndex: Int,
                           boxCollider: ColliderSnapshot, boxPos: Vec3d, half: Vec3d, boxIndex: Int,
                           planeIsA: Bool) -> CollisionPair? {
        let corners = [
            Vec3d(boxPos.x - half.x, boxPos.y - half.y, boxPos.z - half.z),
            Vec3d(boxPos.x + half.x, boxPos.y - half.y, boxPos.z - half.z),
            Vec3d(boxPos.x - half.x, boxPos.y + half.y, boxPos.z - half.z),
            Vec3d(boxPos.x + half.x, boxPos.y + half.y, boxPos.z - half.z),
            Vec3d(boxPos.x - half.x, boxPos.y - half.y, boxPos.z + half.z),
            Vec3d(boxPos.x + half.x, boxPos.y - half.y, boxPos.z + half.z),
            Vec3d(boxPos.x - half.x, boxPos.y + half.y, boxPos.z + half.z),
            Vec3d(boxPos.x + half.x, boxPos.y + half.y, boxPos.z + half.z)
        ]
        
        var deepest: Float = 0
        var deepestPoint = corners[0]
        
        for corner in corners {
            let dist = normal.x * corner.x + normal.y * corner.y + normal.z * corner.z - offset
            if dist < deepest {
                deepest = dist
                deepestPoint = corner
            }
        }
        
        if deepest >= 0 { return nil }
        
        var n = normal
        if !planeIsA { n = Vec3d(-n.x, -n.y, -n.z) }
        
        return CollisionPair(
            bodyIdA: planeIsA ? planeCollider.bodyId : boxCollider.bodyId,
            bodyIdB: planeIsA ? boxCollider.bodyId : planeCollider.bodyId,
            colliderIndexA: planeIsA ? planeIndex : boxIndex,
            colliderIndexB: planeIsA ? boxIndex : planeIndex,
            contactPoint: deepestPoint, normal: n, penetrationDepth: -deepest,
            materialA: planeIsA ? planeCollider.material : boxCollider.material,
            materialB: planeIsA ? boxCollider.material : planeCollider.material
        )
    }
    
    private func sphereVsSphere(colliderA: ColliderSnapshot, posA: Vec3d, rA: Float, indexA: Int,
                                colliderB: ColliderSnapshot, posB: Vec3d, rB: Float, indexB: Int) -> CollisionPair? {
        let dx = posB.x - posA.x, dy = posB.y - posA.y, dz = posB.z - posA.z
        let distSq = dx * dx + dy * dy + dz * dz
        let radiusSum = rA + rB
        if distSq >= radiusSum * radiusSum { return nil }
        
        let dist = sqrt(distSq)
        let normal = dist > 0.0001 ? Vec3d(dx / dist, dy / dist, dz / dist) : Vec3d(0, 1, 0)
        let contact = Vec3d(posA.x + normal.x * rA, posA.y + normal.y * rA, posA.z + normal.z * rA)
        
        return CollisionPair(bodyIdA: colliderA.bodyId, bodyIdB: colliderB.bodyId,
                            colliderIndexA: indexA, colliderIndexB: indexB,
                            contactPoint: contact, normal: normal, penetrationDepth: radiusSum - dist,
                            materialA: colliderA.material, materialB: colliderB.material)
    }
    
    private func planeVsSphere(planeCollider: ColliderSnapshot, normal: Vec3d, offset: Float, planeIndex: Int,
                               sphereCollider: ColliderSnapshot, spherePos: Vec3d, radius: Float, sphereIndex: Int,
                               planeIsA: Bool) -> CollisionPair? {
        let dist = normal.x * spherePos.x + normal.y * spherePos.y + normal.z * spherePos.z - offset
        if dist >= radius { return nil }
        
        let contact = Vec3d(spherePos.x - normal.x * radius, spherePos.y - normal.y * radius, spherePos.z - normal.z * radius)
        var n = normal
        if !planeIsA { n = Vec3d(-n.x, -n.y, -n.z) }
        
        return CollisionPair(
            bodyIdA: planeIsA ? planeCollider.bodyId : sphereCollider.bodyId,
            bodyIdB: planeIsA ? sphereCollider.bodyId : planeCollider.bodyId,
            colliderIndexA: planeIsA ? planeIndex : sphereIndex,
            colliderIndexB: planeIsA ? sphereIndex : planeIndex,
            contactPoint: contact, normal: n, penetrationDepth: radius - dist,
            materialA: planeIsA ? planeCollider.material : sphereCollider.material,
            materialB: planeIsA ? sphereCollider.material : planeCollider.material
        )
    }
    
    private func boxVsSphere(boxCollider: ColliderSnapshot, boxPos: Vec3d, half: Vec3d, boxIndex: Int,
                            sphereCollider: ColliderSnapshot, spherePos: Vec3d, radius: Float, sphereIndex: Int,
                            boxIsA: Bool) -> CollisionPair? {
        let closest = Vec3d(
            max(boxPos.x - half.x, min(spherePos.x, boxPos.x + half.x)),
            max(boxPos.y - half.y, min(spherePos.y, boxPos.y + half.y)),
            max(boxPos.z - half.z, min(spherePos.z, boxPos.z + half.z))
        )
        
        let dx = spherePos.x - closest.x, dy = spherePos.y - closest.y, dz = spherePos.z - closest.z
        let distSq = dx * dx + dy * dy + dz * dz
        if distSq >= radius * radius { return nil }
        
        let dist = sqrt(distSq)
        var normal = dist > 0.0001 ? Vec3d(dx / dist, dy / dist, dz / dist) : Vec3d(0, 1, 0)
        if !boxIsA { normal = Vec3d(-normal.x, -normal.y, -normal.z) }
        
        return CollisionPair(
            bodyIdA: boxIsA ? boxCollider.bodyId : sphereCollider.bodyId,
            bodyIdB: boxIsA ? sphereCollider.bodyId : boxCollider.bodyId,
            colliderIndexA: boxIsA ? boxIndex : sphereIndex,
            colliderIndexB: boxIsA ? sphereIndex : boxIndex,
            contactPoint: closest, normal: normal, penetrationDepth: radius - dist,
            materialA: boxIsA ? boxCollider.material : sphereCollider.material,
            materialB: boxIsA ? sphereCollider.material : boxCollider.material
        )
    }
    
    private func resolveCollisions(bodies: [GameUUID: PhysicsBodyState], collisions: [CollisionPair]) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for collision in collisions {
            guard var bodyA = result[collision.bodyIdA], var bodyB = result[collision.bodyIdB] else { continue }
            
            let isKinA = bodyA.isKinematic, isKinB = bodyB.isKinematic
            if isKinA && isKinB { continue }
            
            let normal = collision.normal
            let penetration = collision.penetrationDepth
            if penetration < 0.001 { continue }
            
            // Mass ratios
            let massA = bodyA.mass, massB = bodyB.mass
            let ratioA: Float = isKinA ? 0 : (isKinB ? 1.0 : massB / (massA + massB))
            let ratioB: Float = isKinB ? 0 : (isKinA ? 1.0 : massA / (massA + massB))
            
            // Position correction
            let correction = penetration + 0.01
            if !isKinA {
                bodyA.position = Vec3d(bodyA.position.x - normal.x * correction * ratioA,
                                       bodyA.position.y - normal.y * correction * ratioA,
                                       bodyA.position.z - normal.z * correction * ratioA)
            }
            if !isKinB {
                bodyB.position = Vec3d(bodyB.position.x + normal.x * correction * ratioB,
                                       bodyB.position.y + normal.y * correction * ratioB,
                                       bodyB.position.z + normal.z * correction * ratioB)
            }
            
            // Velocity response
            let velA = bodyA.velocity, velB = bodyB.velocity
            let relVelN = (velB.x - velA.x) * normal.x + (velB.y - velA.y) * normal.y + (velB.z - velA.z) * normal.z
            
            if relVelN > 0 {
                result[collision.bodyIdA] = bodyA
                result[collision.bodyIdB] = bodyB
                continue
            }
            
            let bounciness = PhysicsMaterial.combinedBounciness(collision.materialA, collision.materialB)
            let friction = PhysicsMaterial.combinedFriction(collision.materialA, collision.materialB)
            
            let invMassA = isKinA ? 0.0 : 1.0 / massA
            let invMassB = isKinB ? 0.0 : 1.0 / massB
            let invMassSum = invMassA + invMassB
            guard invMassSum > 0 else { continue }
            
            let j = -(1.0 + bounciness) * relVelN / invMassSum
            
            if !isKinA {
                bodyA.velocity = Vec3d(velA.x - j * invMassA * normal.x,
                                       velA.y - j * invMassA * normal.y,
                                       velA.z - j * invMassA * normal.z)
            }
            if !isKinB {
                bodyB.velocity = Vec3d(velB.x + j * invMassB * normal.x,
                                       velB.y + j * invMassB * normal.y,
                                       velB.z + j * invMassB * normal.z)
            }
            
            // Friction
            let newVelA = bodyA.velocity, newVelB = bodyB.velocity
            let relVel = Vec3d(newVelA.x - newVelB.x, newVelA.y - newVelB.y, newVelA.z - newVelB.z)
            let relVelN2 = relVel.x * normal.x + relVel.y * normal.y + relVel.z * normal.z
            let tangent = Vec3d(relVel.x - relVelN2 * normal.x, relVel.y - relVelN2 * normal.y, relVel.z - relVelN2 * normal.z)
            let tangentSpeed = sqrt(tangent.x * tangent.x + tangent.y * tangent.y + tangent.z * tangent.z)
            
            if tangentSpeed > 0.001 {
                let t = Vec3d(tangent.x / tangentSpeed, tangent.y / tangentSpeed, tangent.z / tangentSpeed)
                let jt = min(friction * abs(j), tangentSpeed / invMassSum)
                
                if !isKinA {
                    bodyA.velocity = Vec3d(bodyA.velocity.x - jt * invMassA * t.x,
                                           bodyA.velocity.y - jt * invMassA * t.y,
                                           bodyA.velocity.z - jt * invMassA * t.z)
                }
                if !isKinB {
                    bodyB.velocity = Vec3d(bodyB.velocity.x + jt * invMassB * t.x,
                                           bodyB.velocity.y + jt * invMassB * t.y,
                                           bodyB.velocity.z + jt * invMassB * t.z)
                }
            }
            
            result[collision.bodyIdA] = bodyA
            result[collision.bodyIdB] = bodyB
        }
        
        return result
    }
    
    // MARK: - Utilities
    
    /// Clear all registered bodies
    public func clear() {
        rigidBodies.removeAll()
        bodyLookup.removeAll()
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
