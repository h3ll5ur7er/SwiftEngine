import Foundation

// MARK: - Sendable State Types

/// Snapshot of physics state for a single rigid body
public struct PhysicsBodyState: Sendable {
    public let id: GameUUID
    public var position: Vec3d
    public var velocity: Vec3d
    public var rotation: Quaternion
    public var angularVelocity: Vec3d
    public let mass: Float
    public let isKinematic: Bool
    public let angularDrag: Float
    public let maxVelocity: Float
    public let maxAngularVelocity: Float
    public var accumulatedForce: Vec3d
    public var accumulatedTorque: Vec3d
    
    public init(
        id: GameUUID,
        position: Vec3d,
        velocity: Vec3d = .zero,
        rotation: Quaternion = .identity,
        angularVelocity: Vec3d = .zero,
        mass: Float = 1.0,
        isKinematic: Bool = false,
        angularDrag: Float = 0.05,
        maxVelocity: Float = 50.0,
        maxAngularVelocity: Float = 20.0,
        accumulatedForce: Vec3d = .zero,
        accumulatedTorque: Vec3d = .zero
    ) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.rotation = rotation
        self.angularVelocity = angularVelocity
        self.mass = mass
        self.isKinematic = isKinematic
        self.angularDrag = angularDrag
        self.maxVelocity = maxVelocity
        self.maxAngularVelocity = maxAngularVelocity
        self.accumulatedForce = accumulatedForce
        self.accumulatedTorque = accumulatedTorque
    }
}

/// Snapshot of a collider for collision detection
public struct ColliderSnapshot: Sendable {
    public enum ColliderType: Sendable {
        case box(halfExtents: Vec3d)
        case sphere(radius: Float)
        case plane(normal: Vec3d, offset: Float)
    }
    
    public let bodyId: GameUUID
    public let type: ColliderType
    public let worldCenter: Vec3d
    public let worldRotation: Quaternion
    public let isTrigger: Bool
    public let layer: Int
    public let material: PhysicsMaterial
    public let boundingSphereRadius: Float
    
    public init(
        bodyId: GameUUID,
        type: ColliderType,
        worldCenter: Vec3d,
        worldRotation: Quaternion = .identity,
        isTrigger: Bool = false,
        layer: Int = 0,
        material: PhysicsMaterial = .default,
        boundingSphereRadius: Float = 1.0
    ) {
        self.bodyId = bodyId
        self.type = type
        self.worldCenter = worldCenter
        self.worldRotation = worldRotation
        self.isTrigger = isTrigger
        self.layer = layer
        self.material = material
        self.boundingSphereRadius = boundingSphereRadius
    }
}

/// Collision info for collision response
public struct CollisionPair: Sendable {
    public let bodyIdA: GameUUID
    public let bodyIdB: GameUUID
    public let colliderIndexA: Int
    public let colliderIndexB: Int
    public let contactPoint: Vec3d
    public let normal: Vec3d  // Points from A to B
    public let penetrationDepth: Float
    public let materialA: PhysicsMaterial
    public let materialB: PhysicsMaterial
}

/// Result of a physics simulation step
public struct PhysicsStepResult: Sendable {
    public let updatedBodies: [GameUUID: PhysicsBodyState]
    public let collisions: [CollisionPair]
    public let simulatedTime: Float
    public let stepsExecuted: Int
    
    public init(
        updatedBodies: [GameUUID: PhysicsBodyState],
        collisions: [CollisionPair],
        simulatedTime: Float,
        stepsExecuted: Int = 1
    ) {
        self.updatedBodies = updatedBodies
        self.collisions = collisions
        self.simulatedTime = simulatedTime
        self.stepsExecuted = stepsExecuted
    }
}

/// Input for a physics simulation frame
public struct PhysicsFrameInput: Sendable {
    public let bodies: [GameUUID: PhysicsBodyState]
    public let colliders: [ColliderSnapshot]
    public let deltaTime: Float
    
    public init(bodies: [GameUUID: PhysicsBodyState], colliders: [ColliderSnapshot], deltaTime: Float) {
        self.bodies = bodies
        self.colliders = colliders
        self.deltaTime = deltaTime
    }
}

/// Collision event between two physics bodies (legacy, kept for compatibility)
public struct CollisionEvent: Sendable {
    public let bodyA: GameUUID
    public let bodyB: GameUUID
    public let contactPoint: Vec3d
    public let normal: Vec3d
    public let penetration: Float
    
    public init(bodyA: GameUUID, bodyB: GameUUID, contactPoint: Vec3d, normal: Vec3d, penetration: Float) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.contactPoint = contactPoint
        self.normal = normal
        self.penetration = penetration
    }
}

// MARK: - Physics Actor

/// Actor responsible for running physics simulation on a separate thread
/// Uses a fixed timestep to ensure deterministic simulation
public actor PhysicsActor {
    
    /// Shared instance
    public static let shared = PhysicsActor()
    
    /// Shared timer for performance measurement
    private let timer = sharedTimer
    
    /// Fixed timestep for physics (default: 60Hz)
    public var fixedDeltaTime: Float = 1.0 / 60.0
    
    /// Maximum delta time to prevent explosion (caps to 33ms)
    public var maxDeltaTime: Float = 1.0 / 30.0
    
    /// Maximum physics steps per frame to prevent spiral of death
    public var maxStepsPerFrame: Int = 4
    
    /// Gravity vector
    public var gravity: Vec3d = Vec3d(0, -9.81, 0)
    
    /// Accumulated time from variable frame updates
    private var accumulator: Float = 0
    
    /// Whether simulation is enabled
    public var isEnabled: Bool = true
    
    /// Statistics tracking
    private var totalStepsProcessed: UInt64 = 0
    private var totalProcessingTimeMs: Double = 0
    private var lastFrameSteps: Int = 0
    
    public init() {}
    
    // MARK: - Simulation
    
    /// Run physics simulation for a frame
    /// Takes snapshots of bodies and colliders, simulates, returns updated states
    public func simulate(input: PhysicsFrameInput) async -> PhysicsStepResult {
        guard isEnabled else {
            return PhysicsStepResult(updatedBodies: input.bodies, collisions: [], simulatedTime: 0, stepsExecuted: 0)
        }
        
        let startTime = timer.currentTimeMillis()
        
        // Clamp incoming delta time
        let clampedDt = min(input.deltaTime, maxDeltaTime)
        accumulator += clampedDt
        
        var bodies = input.bodies
        let colliders = input.colliders
        var allCollisions: [CollisionPair] = []
        var totalSimulatedTime: Float = 0
        var stepsThisFrame = 0
        
        // Run fixed timestep updates
        while accumulator >= fixedDeltaTime && stepsThisFrame < maxStepsPerFrame {
            // Step 1: Update velocities (apply forces, gravity)
            bodies = integrateVelocities(bodies: bodies, dt: fixedDeltaTime)
            
            // Step 2: Integrate positions
            bodies = integratePositions(bodies: bodies, dt: fixedDeltaTime)
            
            // Step 3: Detect collisions
            let collisions = detectCollisions(bodies: bodies, colliders: colliders)
            
            // Step 4: Resolve collisions
            bodies = resolveCollisions(bodies: bodies, collisions: collisions)
            
            allCollisions.append(contentsOf: collisions)
            accumulator -= fixedDeltaTime
            totalSimulatedTime += fixedDeltaTime
            stepsThisFrame += 1
        }
        
        // Prevent accumulator from growing too large (spiral of death prevention)
        if accumulator > fixedDeltaTime * Float(maxStepsPerFrame) {
            accumulator = 0
        }
        
        // Update statistics
        totalStepsProcessed += UInt64(stepsThisFrame)
        totalProcessingTimeMs += Double(timer.currentTimeMillis() - startTime)
        lastFrameSteps = stepsThisFrame
        
        return PhysicsStepResult(
            updatedBodies: bodies,
            collisions: allCollisions,
            simulatedTime: totalSimulatedTime,
            stepsExecuted: stepsThisFrame
        )
    }
    
    // MARK: - Integration
    
    /// Apply forces and gravity to update velocities
    private func integrateVelocities(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for (id, body) in bodies {
            guard !body.isKinematic else { continue }
            
            var vel = body.velocity
            var angVel = body.angularVelocity
            
            // Apply gravity
            vel = Vec3d(
                vel.x + gravity.x * dt,
                vel.y + gravity.y * dt,
                vel.z + gravity.z * dt
            )
            
            // Apply accumulated forces
            let forceAccel = body.accumulatedForce / body.mass
            vel = Vec3d(
                vel.x + forceAccel.x * dt,
                vel.y + forceAccel.y * dt,
                vel.z + forceAccel.z * dt
            )
            
            // Apply accumulated torques (simplified: assume uniform inertia = mass)
            let torqueAccel = body.accumulatedTorque / body.mass
            angVel = Vec3d(
                angVel.x + torqueAccel.x * dt,
                angVel.y + torqueAccel.y * dt,
                angVel.z + torqueAccel.z * dt
            )
            
            // Apply angular drag
            let angularDampening = 1.0 - body.angularDrag
            angVel = Vec3d(angVel.x * angularDampening, angVel.y * angularDampening, angVel.z * angularDampening)
            
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
            
            // Update body state
            var updated = body
            updated.velocity = vel
            updated.angularVelocity = angVel
            updated.accumulatedForce = .zero
            updated.accumulatedTorque = .zero
            result[id] = updated
        }
        
        return result
    }
    
    /// Integrate positions and rotations
    private func integratePositions(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for (id, body) in bodies {
            guard !body.isKinematic else { continue }
            
            // Integrate position
            let newPos = Vec3d(
                body.position.x + body.velocity.x * dt,
                body.position.y + body.velocity.y * dt,
                body.position.z + body.velocity.z * dt
            )
            
            // Integrate rotation
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
    
    // MARK: - Collision Detection
    
    /// Detect all collisions between colliders
    private func detectCollisions(bodies: [GameUUID: PhysicsBodyState], colliders: [ColliderSnapshot]) -> [CollisionPair] {
        var collisions: [CollisionPair] = []
        
        // Update collider positions based on body positions
        var updatedColliders: [(ColliderSnapshot, Vec3d)] = []
        for collider in colliders {
            if let body = bodies[collider.bodyId] {
                // Use body's current position
                updatedColliders.append((collider, body.position))
            } else {
                // Static collider - use original position
                updatedColliders.append((collider, collider.worldCenter))
            }
        }
        
        // O(n²) collision detection
        for i in 0..<updatedColliders.count {
            for j in (i + 1)..<updatedColliders.count {
                let (colliderA, posA) = updatedColliders[i]
                let (colliderB, posB) = updatedColliders[j]
                
                // Skip if both are triggers
                if colliderA.isTrigger && colliderB.isTrigger { continue }
                
                // Skip if different layers (unless layer is 0 which collides with everything)
                if colliderA.layer != 0 && colliderB.layer != 0 && colliderA.layer != colliderB.layer { continue }
                
                // Broad phase: bounding sphere check
                let radiusA = colliderA.boundingSphereRadius
                let radiusB = colliderB.boundingSphereRadius
                let skipBroadPhase = radiusA.isInfinite || radiusB.isInfinite
                
                if !skipBroadPhase {
                    let dx = posB.x - posA.x
                    let dy = posB.y - posA.y
                    let dz = posB.z - posA.z
                    let distSquared = dx * dx + dy * dy + dz * dz
                    let radiusSum = radiusA + radiusB
                    
                    if distSquared > radiusSum * radiusSum {
                        continue
                    }
                }
                
                // Narrow phase collision detection
                if let collision = narrowPhaseCollision(
                    colliderA: colliderA, posA: posA, indexA: i,
                    colliderB: colliderB, posB: posB, indexB: j
                ) {
                    collisions.append(collision)
                }
            }
        }
        
        return collisions
    }
    
    /// Narrow phase collision detection between two colliders
    private func narrowPhaseCollision(
        colliderA: ColliderSnapshot, posA: Vec3d, indexA: Int,
        colliderB: ColliderSnapshot, posB: Vec3d, indexB: Int
    ) -> CollisionPair? {
        
        switch (colliderA.type, colliderB.type) {
        case (.box(let halfExtentsA), .box(let halfExtentsB)):
            return boxVsBox(
                colliderA: colliderA, posA: posA, halfExtentsA: halfExtentsA, indexA: indexA,
                colliderB: colliderB, posB: posB, halfExtentsB: halfExtentsB, indexB: indexB
            )
            
        case (.sphere(let radiusA), .sphere(let radiusB)):
            return sphereVsSphere(
                colliderA: colliderA, posA: posA, radiusA: radiusA, indexA: indexA,
                colliderB: colliderB, posB: posB, radiusB: radiusB, indexB: indexB
            )
            
        case (.box(let halfExtents), .sphere(let radius)):
            return boxVsSphere(
                boxCollider: colliderA, boxPos: posA, halfExtents: halfExtents, boxIndex: indexA,
                sphereCollider: colliderB, spherePos: posB, radius: radius, sphereIndex: indexB,
                boxIsA: true
            )
            
        case (.sphere(let radius), .box(let halfExtents)):
            return boxVsSphere(
                boxCollider: colliderB, boxPos: posB, halfExtents: halfExtents, boxIndex: indexB,
                sphereCollider: colliderA, spherePos: posA, radius: radius, sphereIndex: indexA,
                boxIsA: false
            )
            
        case (.plane(let normal, let offset), .box(let halfExtents)):
            return planeVsBox(
                planeCollider: colliderA, planeNormal: normal, planeOffset: offset, planeIndex: indexA,
                boxCollider: colliderB, boxPos: posB, halfExtents: halfExtents, boxIndex: indexB,
                planeIsA: true
            )
            
        case (.box(let halfExtents), .plane(let normal, let offset)):
            return planeVsBox(
                planeCollider: colliderB, planeNormal: normal, planeOffset: offset, planeIndex: indexB,
                boxCollider: colliderA, boxPos: posA, halfExtents: halfExtents, boxIndex: indexA,
                planeIsA: false
            )
            
        case (.plane(let normal, let offset), .sphere(let radius)):
            return planeVsSphere(
                planeCollider: colliderA, planeNormal: normal, planeOffset: offset, planeIndex: indexA,
                sphereCollider: colliderB, spherePos: posB, radius: radius, sphereIndex: indexB,
                planeIsA: true
            )
            
        case (.sphere(let radius), .plane(let normal, let offset)):
            return planeVsSphere(
                planeCollider: colliderB, planeNormal: normal, planeOffset: offset, planeIndex: indexB,
                sphereCollider: colliderA, spherePos: posA, radius: radius, sphereIndex: indexA,
                planeIsA: false
            )
            
        case (.plane, .plane):
            // Planes don't collide with each other
            return nil
        }
    }
    
    // MARK: - Collision Detection Primitives
    
    private func boxVsBox(
        colliderA: ColliderSnapshot, posA: Vec3d, halfExtentsA: Vec3d, indexA: Int,
        colliderB: ColliderSnapshot, posB: Vec3d, halfExtentsB: Vec3d, indexB: Int
    ) -> CollisionPair? {
        // AABB vs AABB
        let minA = Vec3d(posA.x - halfExtentsA.x, posA.y - halfExtentsA.y, posA.z - halfExtentsA.z)
        let maxA = Vec3d(posA.x + halfExtentsA.x, posA.y + halfExtentsA.y, posA.z + halfExtentsA.z)
        let minB = Vec3d(posB.x - halfExtentsB.x, posB.y - halfExtentsB.y, posB.z - halfExtentsB.z)
        let maxB = Vec3d(posB.x + halfExtentsB.x, posB.y + halfExtentsB.y, posB.z + halfExtentsB.z)
        
        // Check for overlap
        if maxA.x < minB.x || minA.x > maxB.x { return nil }
        if maxA.y < minB.y || minA.y > maxB.y { return nil }
        if maxA.z < minB.z || minA.z > maxB.z { return nil }
        
        // Calculate penetration on each axis
        let overlapX = min(maxA.x - minB.x, maxB.x - minA.x)
        let overlapY = min(maxA.y - minB.y, maxB.y - minA.y)
        let overlapZ = min(maxA.z - minB.z, maxB.z - minA.z)
        
        // Find minimum penetration axis
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
        
        // Contact point at center of overlap region
        let contactPoint = Vec3d(
            (max(minA.x, minB.x) + min(maxA.x, maxB.x)) / 2,
            (max(minA.y, minB.y) + min(maxA.y, maxB.y)) / 2,
            (max(minA.z, minB.z) + min(maxA.z, maxB.z)) / 2
        )
        
        return CollisionPair(
            bodyIdA: colliderA.bodyId,
            bodyIdB: colliderB.bodyId,
            colliderIndexA: indexA,
            colliderIndexB: indexB,
            contactPoint: contactPoint,
            normal: normal,
            penetrationDepth: penetration,
            materialA: colliderA.material,
            materialB: colliderB.material
        )
    }
    
    private func sphereVsSphere(
        colliderA: ColliderSnapshot, posA: Vec3d, radiusA: Float, indexA: Int,
        colliderB: ColliderSnapshot, posB: Vec3d, radiusB: Float, indexB: Int
    ) -> CollisionPair? {
        let dx = posB.x - posA.x
        let dy = posB.y - posA.y
        let dz = posB.z - posA.z
        let distSquared = dx * dx + dy * dy + dz * dz
        let radiusSum = radiusA + radiusB
        
        if distSquared >= radiusSum * radiusSum {
            return nil
        }
        
        let dist = sqrt(distSquared)
        let penetration = radiusSum - dist
        
        let normal: Vec3d
        if dist > 0.0001 {
            normal = Vec3d(dx / dist, dy / dist, dz / dist)
        } else {
            normal = Vec3d(0, 1, 0)  // Default up for coincident spheres
        }
        
        let contactPoint = Vec3d(
            posA.x + normal.x * radiusA,
            posA.y + normal.y * radiusA,
            posA.z + normal.z * radiusA
        )
        
        return CollisionPair(
            bodyIdA: colliderA.bodyId,
            bodyIdB: colliderB.bodyId,
            colliderIndexA: indexA,
            colliderIndexB: indexB,
            contactPoint: contactPoint,
            normal: normal,
            penetrationDepth: penetration,
            materialA: colliderA.material,
            materialB: colliderB.material
        )
    }
    
    private func boxVsSphere(
        boxCollider: ColliderSnapshot, boxPos: Vec3d, halfExtents: Vec3d, boxIndex: Int,
        sphereCollider: ColliderSnapshot, spherePos: Vec3d, radius: Float, sphereIndex: Int,
        boxIsA: Bool
    ) -> CollisionPair? {
        // Find closest point on box to sphere center
        let closest = Vec3d(
            max(boxPos.x - halfExtents.x, min(spherePos.x, boxPos.x + halfExtents.x)),
            max(boxPos.y - halfExtents.y, min(spherePos.y, boxPos.y + halfExtents.y)),
            max(boxPos.z - halfExtents.z, min(spherePos.z, boxPos.z + halfExtents.z))
        )
        
        let dx = spherePos.x - closest.x
        let dy = spherePos.y - closest.y
        let dz = spherePos.z - closest.z
        let distSquared = dx * dx + dy * dy + dz * dz
        
        if distSquared >= radius * radius {
            return nil
        }
        
        let dist = sqrt(distSquared)
        let penetration = radius - dist
        
        var normal: Vec3d
        if dist > 0.0001 {
            normal = Vec3d(dx / dist, dy / dist, dz / dist)
        } else {
            normal = Vec3d(0, 1, 0)
        }
        
        // Normal points from A to B
        if !boxIsA {
            normal = Vec3d(-normal.x, -normal.y, -normal.z)
        }
        
        return CollisionPair(
            bodyIdA: boxIsA ? boxCollider.bodyId : sphereCollider.bodyId,
            bodyIdB: boxIsA ? sphereCollider.bodyId : boxCollider.bodyId,
            colliderIndexA: boxIsA ? boxIndex : sphereIndex,
            colliderIndexB: boxIsA ? sphereIndex : boxIndex,
            contactPoint: closest,
            normal: normal,
            penetrationDepth: penetration,
            materialA: boxIsA ? boxCollider.material : sphereCollider.material,
            materialB: boxIsA ? sphereCollider.material : boxCollider.material
        )
    }
    
    private func planeVsBox(
        planeCollider: ColliderSnapshot, planeNormal: Vec3d, planeOffset: Float, planeIndex: Int,
        boxCollider: ColliderSnapshot, boxPos: Vec3d, halfExtents: Vec3d, boxIndex: Int,
        planeIsA: Bool
    ) -> CollisionPair? {
        // Check all 8 corners of the box against the plane
        let corners = [
            Vec3d(boxPos.x - halfExtents.x, boxPos.y - halfExtents.y, boxPos.z - halfExtents.z),
            Vec3d(boxPos.x + halfExtents.x, boxPos.y - halfExtents.y, boxPos.z - halfExtents.z),
            Vec3d(boxPos.x - halfExtents.x, boxPos.y + halfExtents.y, boxPos.z - halfExtents.z),
            Vec3d(boxPos.x + halfExtents.x, boxPos.y + halfExtents.y, boxPos.z - halfExtents.z),
            Vec3d(boxPos.x - halfExtents.x, boxPos.y - halfExtents.y, boxPos.z + halfExtents.z),
            Vec3d(boxPos.x + halfExtents.x, boxPos.y - halfExtents.y, boxPos.z + halfExtents.z),
            Vec3d(boxPos.x - halfExtents.x, boxPos.y + halfExtents.y, boxPos.z + halfExtents.z),
            Vec3d(boxPos.x + halfExtents.x, boxPos.y + halfExtents.y, boxPos.z + halfExtents.z)
        ]
        
        var deepestPenetration: Float = 0
        var deepestPoint = corners[0]
        
        for corner in corners {
            // Distance from point to plane (negative if below plane)
            let dist = planeNormal.x * corner.x + planeNormal.y * corner.y + planeNormal.z * corner.z - planeOffset
            
            if dist < deepestPenetration {
                deepestPenetration = dist
                deepestPoint = corner
            }
        }
        
        // No collision if all corners are above plane
        if deepestPenetration >= 0 {
            return nil
        }
        
        let penetration = -deepestPenetration
        
        // Normal points from plane (A) to box (B) when planeIsA
        var normal = planeNormal
        if !planeIsA {
            normal = Vec3d(-normal.x, -normal.y, -normal.z)
        }
        
        return CollisionPair(
            bodyIdA: planeIsA ? planeCollider.bodyId : boxCollider.bodyId,
            bodyIdB: planeIsA ? boxCollider.bodyId : planeCollider.bodyId,
            colliderIndexA: planeIsA ? planeIndex : boxIndex,
            colliderIndexB: planeIsA ? boxIndex : planeIndex,
            contactPoint: deepestPoint,
            normal: normal,
            penetrationDepth: penetration,
            materialA: planeIsA ? planeCollider.material : boxCollider.material,
            materialB: planeIsA ? boxCollider.material : planeCollider.material
        )
    }
    
    private func planeVsSphere(
        planeCollider: ColliderSnapshot, planeNormal: Vec3d, planeOffset: Float, planeIndex: Int,
        sphereCollider: ColliderSnapshot, spherePos: Vec3d, radius: Float, sphereIndex: Int,
        planeIsA: Bool
    ) -> CollisionPair? {
        // Distance from sphere center to plane
        let dist = planeNormal.x * spherePos.x + planeNormal.y * spherePos.y + planeNormal.z * spherePos.z - planeOffset
        
        if dist >= radius {
            return nil  // No collision
        }
        
        let penetration = radius - dist
        
        // Contact point on sphere surface
        let contactPoint = Vec3d(
            spherePos.x - planeNormal.x * radius,
            spherePos.y - planeNormal.y * radius,
            spherePos.z - planeNormal.z * radius
        )
        
        var normal = planeNormal
        if !planeIsA {
            normal = Vec3d(-normal.x, -normal.y, -normal.z)
        }
        
        return CollisionPair(
            bodyIdA: planeIsA ? planeCollider.bodyId : sphereCollider.bodyId,
            bodyIdB: planeIsA ? sphereCollider.bodyId : planeCollider.bodyId,
            colliderIndexA: planeIsA ? planeIndex : sphereIndex,
            colliderIndexB: planeIsA ? sphereIndex : planeIndex,
            contactPoint: contactPoint,
            normal: normal,
            penetrationDepth: penetration,
            materialA: planeIsA ? planeCollider.material : sphereCollider.material,
            materialB: planeIsA ? sphereCollider.material : planeCollider.material
        )
    }
    
    // MARK: - Collision Resolution
    
    /// Resolve all collisions by adjusting positions and velocities
    private func resolveCollisions(bodies: [GameUUID: PhysicsBodyState], collisions: [CollisionPair]) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        
        for collision in collisions {
            guard var bodyA = result[collision.bodyIdA] else { continue }
            guard var bodyB = result[collision.bodyIdB] else { continue }
            
            let isKinematicA = bodyA.isKinematic
            let isKinematicB = bodyB.isKinematic
            
            // Skip if both are kinematic
            if isKinematicA && isKinematicB { continue }
            
            let normal = collision.normal
            let penetration = collision.penetrationDepth
            
            // Skip tiny penetrations
            if penetration < 0.001 { continue }
            
            // Calculate mass ratios
            let massA = bodyA.mass
            let massB = bodyB.mass
            
            let ratioA: Float
            let ratioB: Float
            
            if isKinematicA && !isKinematicB {
                ratioA = 0
                ratioB = 1.0
            } else if !isKinematicA && isKinematicB {
                ratioA = 1.0
                ratioB = 0
            } else {
                let totalMass = massA + massB
                ratioA = massB / totalMass
                ratioB = massA / totalMass
            }
            
            // Position correction
            let correctionBias: Float = 0.01
            let correctionAmount = penetration + correctionBias
            
            if !isKinematicA {
                bodyA.position = Vec3d(
                    bodyA.position.x - normal.x * correctionAmount * ratioA,
                    bodyA.position.y - normal.y * correctionAmount * ratioA,
                    bodyA.position.z - normal.z * correctionAmount * ratioA
                )
            }
            
            if !isKinematicB {
                bodyB.position = Vec3d(
                    bodyB.position.x + normal.x * correctionAmount * ratioB,
                    bodyB.position.y + normal.y * correctionAmount * ratioB,
                    bodyB.position.z + normal.z * correctionAmount * ratioB
                )
            }
            
            // Velocity response
            let velA = bodyA.velocity
            let velB = bodyB.velocity
            
            // Relative velocity along normal (velB - velA) · normal
            let relVelNormal = (velB.x - velA.x) * normal.x + (velB.y - velA.y) * normal.y + (velB.z - velA.z) * normal.z
            
            // Don't resolve if separating
            if relVelNormal > 0 { 
                result[collision.bodyIdA] = bodyA
                result[collision.bodyIdB] = bodyB
                continue 
            }
            
            // Calculate combined material properties
            let combinedBounciness = PhysicsMaterial.combinedBounciness(collision.materialA, collision.materialB)
            let combinedFriction = PhysicsMaterial.combinedFriction(collision.materialA, collision.materialB)
            
            // Inverse masses
            let invMassA = isKinematicA ? 0.0 : (1.0 / massA)
            let invMassB = isKinematicB ? 0.0 : (1.0 / massB)
            let invMassSum = invMassA + invMassB
            
            guard invMassSum > 0 else {
                result[collision.bodyIdA] = bodyA
                result[collision.bodyIdB] = bodyB
                continue
            }
            
            // Normal impulse
            let normalImpulseMag = -(1.0 + combinedBounciness) * relVelNormal / invMassSum
            
            // Apply normal impulse
            if !isKinematicA {
                bodyA.velocity = Vec3d(
                    velA.x - normalImpulseMag * invMassA * normal.x,
                    velA.y - normalImpulseMag * invMassA * normal.y,
                    velA.z - normalImpulseMag * invMassA * normal.z
                )
            }
            
            if !isKinematicB {
                bodyB.velocity = Vec3d(
                    velB.x + normalImpulseMag * invMassB * normal.x,
                    velB.y + normalImpulseMag * invMassB * normal.y,
                    velB.z + normalImpulseMag * invMassB * normal.z
                )
            }
            
            // Apply angular impulse (scaled down for stability)
            let angularScale: Float = 0.3
            
            if !isKinematicA {
                let contactOffset = Vec3d(
                    collision.contactPoint.x - bodyA.position.x,
                    collision.contactPoint.y - bodyA.position.y,
                    collision.contactPoint.z - bodyA.position.z
                )
                let impulse = Vec3d(
                    -normalImpulseMag * invMassA * normal.x * angularScale,
                    -normalImpulseMag * invMassA * normal.y * angularScale,
                    -normalImpulseMag * invMassA * normal.z * angularScale
                )
                // Cross product: contactOffset × impulse
                let torque = Vec3d(
                    contactOffset.y * impulse.z - contactOffset.z * impulse.y,
                    contactOffset.z * impulse.x - contactOffset.x * impulse.z,
                    contactOffset.x * impulse.y - contactOffset.y * impulse.x
                )
                bodyA.angularVelocity = Vec3d(
                    bodyA.angularVelocity.x + torque.x,
                    bodyA.angularVelocity.y + torque.y,
                    bodyA.angularVelocity.z + torque.z
                )
            }
            
            if !isKinematicB {
                let contactOffset = Vec3d(
                    collision.contactPoint.x - bodyB.position.x,
                    collision.contactPoint.y - bodyB.position.y,
                    collision.contactPoint.z - bodyB.position.z
                )
                let impulse = Vec3d(
                    normalImpulseMag * invMassB * normal.x * angularScale,
                    normalImpulseMag * invMassB * normal.y * angularScale,
                    normalImpulseMag * invMassB * normal.z * angularScale
                )
                let torque = Vec3d(
                    contactOffset.y * impulse.z - contactOffset.z * impulse.y,
                    contactOffset.z * impulse.x - contactOffset.x * impulse.z,
                    contactOffset.x * impulse.y - contactOffset.y * impulse.x
                )
                bodyB.angularVelocity = Vec3d(
                    bodyB.angularVelocity.x + torque.x,
                    bodyB.angularVelocity.y + torque.y,
                    bodyB.angularVelocity.z + torque.z
                )
            }
            
            // Friction impulse
            let newVelA = bodyA.velocity
            let newVelB = bodyB.velocity
            let newRelVel = Vec3d(newVelA.x - newVelB.x, newVelA.y - newVelB.y, newVelA.z - newVelB.z)
            let newRelVelNormal = newRelVel.x * normal.x + newRelVel.y * normal.y + newRelVel.z * normal.z
            
            let tangentVel = Vec3d(
                newRelVel.x - newRelVelNormal * normal.x,
                newRelVel.y - newRelVelNormal * normal.y,
                newRelVel.z - newRelVelNormal * normal.z
            )
            
            let tangentSpeed = sqrt(tangentVel.x * tangentVel.x + tangentVel.y * tangentVel.y + tangentVel.z * tangentVel.z)
            
            if tangentSpeed > 0.001 {
                let tangent = Vec3d(tangentVel.x / tangentSpeed, tangentVel.y / tangentSpeed, tangentVel.z / tangentSpeed)
                let frictionImpulseMag = min(combinedFriction * abs(normalImpulseMag), tangentSpeed / invMassSum)
                
                if !isKinematicA {
                    bodyA.velocity = Vec3d(
                        bodyA.velocity.x - frictionImpulseMag * invMassA * tangent.x,
                        bodyA.velocity.y - frictionImpulseMag * invMassA * tangent.y,
                        bodyA.velocity.z - frictionImpulseMag * invMassA * tangent.z
                    )
                }
                
                if !isKinematicB {
                    bodyB.velocity = Vec3d(
                        bodyB.velocity.x + frictionImpulseMag * invMassB * tangent.x,
                        bodyB.velocity.y + frictionImpulseMag * invMassB * tangent.y,
                        bodyB.velocity.z + frictionImpulseMag * invMassB * tangent.z
                    )
                }
            }
            
            result[collision.bodyIdA] = bodyA
            result[collision.bodyIdB] = bodyB
        }
        
        return result
    }
    
    // MARK: - Utilities
    
    /// Reset accumulator (use when simulation is paused/resumed)
    public func resetAccumulator() {
        accumulator = 0
    }
    
    /// Get interpolation alpha for rendering between physics steps
    public func getInterpolationAlpha() -> Float {
        accumulator / fixedDeltaTime
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
