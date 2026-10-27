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
    /// Whether either collider is a trigger (reported, but not resolved)
    public internal(set) var isTrigger: Bool = false
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

// MARK: - Settings

/// Tunable parameters for the physics simulation
public struct PhysicsSettings: Sendable {
    /// Fixed timestep for physics steps (default: 60Hz)
    public var fixedDeltaTime: Float = 1.0 / 60.0

    /// Maximum frame time fed into the accumulator (caps to 33ms to prevent explosion)
    public var maxDeltaTime: Float = 1.0 / 30.0

    /// Maximum physics steps per frame to prevent spiral of death
    public var maxStepsPerFrame: Int = 4

    /// Gravity vector
    public var gravity: Vec3d = Vec3d(0, -9.81, 0)

    /// How strongly contact impulses spin bodies (0 = no spin from contacts).
    /// Box colliders are axis-aligned, so spin from contacts is off by default.
    public var contactAngularResponse: Float = 0

    public init() {}
}

// MARK: - Simulation

/// Fixed-timestep rigid body simulation on plain value snapshots.
/// Used by both PhysicsSystem (inline on the main actor) and PhysicsActor (off the main actor).
public struct PhysicsSimulation: Sendable {

    /// Simulation parameters
    public var settings: PhysicsSettings

    /// Time not yet consumed by fixed steps
    public private(set) var accumulator: Float = 0

    public init(settings: PhysicsSettings = PhysicsSettings()) {
        self.settings = settings
    }

    /// Fraction of a fixed step left in the accumulator, for interpolating rendering
    public var interpolationAlpha: Float {
        accumulator / settings.fixedDeltaTime
    }

    /// Discard any accumulated time (use when simulation is paused/resumed)
    public mutating func resetAccumulator() {
        accumulator = 0
    }

    /// Advance the simulation by a frame's worth of fixed steps
    public mutating func simulate(_ input: PhysicsFrameInput) -> PhysicsStepResult {
        let dt = settings.fixedDeltaTime
        accumulator += min(input.deltaTime, settings.maxDeltaTime)

        let colliders = input.colliders
        let localOffsets = colliderLocalOffsets(colliders: colliders, bodies: input.bodies)
        var bodies = input.bodies
        var allCollisions: [CollisionPair] = []
        var steps = 0

        while accumulator >= dt && steps < settings.maxStepsPerFrame {
            bodies = integrateVelocities(bodies: bodies, dt: dt)
            bodies = integratePositions(bodies: bodies, dt: dt)

            let collisions = detectCollisions(bodies: bodies, colliders: colliders, localOffsets: localOffsets)
            bodies = resolveCollisions(bodies: bodies, collisions: collisions)

            allCollisions.append(contentsOf: collisions)
            accumulator -= dt
            steps += 1
        }

        // Prevent accumulator from growing too large (spiral of death prevention)
        if accumulator > dt * Float(settings.maxStepsPerFrame) {
            accumulator = 0
        }

        return PhysicsStepResult(
            updatedBodies: bodies,
            collisions: allCollisions,
            simulatedTime: Float(steps) * dt,
            stepsExecuted: steps
        )
    }

    // MARK: - Integration

    /// Apply forces and gravity to update velocities
    private func integrateVelocities(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies
        let gravity = settings.gravity

        for (id, body) in bodies {
            guard !body.isKinematic else { continue }

            // Gravity and accumulated forces (forces are consumed by the first step)
            var vel = body.velocity + (gravity + body.accumulatedForce / body.mass) * dt

            // Accumulated torques (simplified: assume uniform inertia = mass), then angular drag
            var angVel = body.angularVelocity + (body.accumulatedTorque / body.mass) * dt
            angVel = angVel * (1.0 - body.angularDrag)

            // Clamp velocities
            let speed = vel.length
            if speed > body.maxVelocity {
                vel = vel * (body.maxVelocity / speed)
            }
            let angSpeed = angVel.length
            if angSpeed > body.maxAngularVelocity {
                angVel = angVel * (body.maxAngularVelocity / angSpeed)
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

    /// Integrate positions and rotations
    private func integratePositions(bodies: [GameUUID: PhysicsBodyState], dt: Float) -> [GameUUID: PhysicsBodyState] {
        var result = bodies

        for (id, body) in bodies {
            guard !body.isKinematic else { continue }

            var updated = body
            updated.position = body.position + body.velocity * dt

            let angSpeed = body.angularVelocity.length
            if angSpeed > 0.0001 {
                let axis = body.angularVelocity / angSpeed
                let deltaRotation = Quaternion.fromAxisAngle(axis: axis, angle: angSpeed * dt)
                updated.rotation = (deltaRotation * body.rotation).normalized
            }

            result[id] = updated
        }

        return result
    }

    // MARK: - Collision Detection

    /// Collider center relative to its body, in the body's local frame (nil for static colliders)
    private func colliderLocalOffsets(colliders: [ColliderSnapshot], bodies: [GameUUID: PhysicsBodyState]) -> [Vec3d?] {
        colliders.map { collider in
            guard let body = bodies[collider.bodyId] else { return nil }
            return body.rotation.inverse * (collider.worldCenter - body.position)
        }
    }

    /// Detect all collisions between colliders
    private func detectCollisions(
        bodies: [GameUUID: PhysicsBodyState],
        colliders: [ColliderSnapshot],
        localOffsets: [Vec3d?]
    ) -> [CollisionPair] {
        var collisions: [CollisionPair] = []

        // Colliders follow their body's current position and rotation; static colliders stay put
        let positions: [Vec3d] = colliders.indices.map { i in
            if let offset = localOffsets[i], let body = bodies[colliders[i].bodyId] {
                return body.position + body.rotation * offset
            }
            return colliders[i].worldCenter
        }

        // O(n²) collision detection
        for i in 0..<colliders.count {
            for j in (i + 1)..<colliders.count {
                let colliderA = colliders[i]
                let colliderB = colliders[j]
                let posA = positions[i]
                let posB = positions[j]

                // Colliders on the same body don't collide with each other
                if colliderA.bodyId == colliderB.bodyId { continue }

                // Skip if both are triggers
                if colliderA.isTrigger && colliderB.isTrigger { continue }

                // Skip if different layers (unless layer is 0 which collides with everything)
                if colliderA.layer != 0 && colliderB.layer != 0 && colliderA.layer != colliderB.layer { continue }

                // Broad phase: bounding sphere check (skipped for infinite colliders like planes)
                let radiusA = colliderA.boundingSphereRadius
                let radiusB = colliderB.boundingSphereRadius
                if !radiusA.isInfinite && !radiusB.isInfinite {
                    let radiusSum = radiusA + radiusB
                    if (posB - posA).squaredLength > radiusSum * radiusSum {
                        continue
                    }
                }

                // Narrow phase collision detection
                if var collision = narrowPhaseCollision(
                    colliderA: colliderA, posA: posA, indexA: i,
                    colliderB: colliderB, posB: posB, indexB: j
                ) {
                    collision.isTrigger = colliderA.isTrigger || colliderB.isTrigger
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

    /// Resolve all collisions by adjusting positions and velocities.
    /// Colliders without a body are static: they push bodies out but never move.
    private func resolveCollisions(bodies: [GameUUID: PhysicsBodyState], collisions: [CollisionPair]) -> [GameUUID: PhysicsBodyState] {
        var result = bodies

        for collision in collisions where !collision.isTrigger {
            let bodyStateA = result[collision.bodyIdA]
            let bodyStateB = result[collision.bodyIdB]

            let isStaticA = bodyStateA?.isKinematic ?? true
            let isStaticB = bodyStateB?.isKinematic ?? true

            // Skip if neither side can move
            if isStaticA && isStaticB { continue }

            let normal = collision.normal
            let penetration = collision.penetrationDepth

            // Skip tiny penetrations
            if penetration < 0.001 { continue }

            let invMassA: Float = isStaticA ? 0 : 1.0 / bodyStateA!.mass
            let invMassB: Float = isStaticB ? 0 : 1.0 / bodyStateB!.mass
            let invMassSum = invMassA + invMassB

            // Position correction, split by inverse mass
            let correctionBias: Float = 0.01
            let correctionAmount = penetration + correctionBias

            if var bodyA = bodyStateA, !isStaticA {
                bodyA.position = bodyA.position - normal * (correctionAmount * invMassA / invMassSum)
                result[collision.bodyIdA] = bodyA
            }
            if var bodyB = bodyStateB, !isStaticB {
                bodyB.position = bodyB.position + normal * (correctionAmount * invMassB / invMassSum)
                result[collision.bodyIdB] = bodyB
            }

            // Velocity response
            // (kinematic bodies keep their velocity, e.g. moving platforms)
            let velA = result[collision.bodyIdA]?.velocity ?? .zero
            let velB = result[collision.bodyIdB]?.velocity ?? .zero

            // Relative velocity along normal (velB - velA) · normal; don't resolve if separating
            let relVelNormal = (velB - velA).dot(normal)
            if relVelNormal > 0 { continue }

            let combinedBounciness = PhysicsMaterial.combinedBounciness(collision.materialA, collision.materialB)
            let combinedFriction = PhysicsMaterial.combinedFriction(collision.materialA, collision.materialB)

            // Normal impulse
            let normalImpulseMag = -(1.0 + combinedBounciness) * relVelNormal / invMassSum
            var newVelA = velA - normal * (normalImpulseMag * invMassA)
            var newVelB = velB + normal * (normalImpulseMag * invMassB)

            // Friction impulse
            let relVel = newVelA - newVelB
            let tangentVel = relVel - normal * relVel.dot(normal)
            let tangentSpeed = tangentVel.length

            if tangentSpeed > 0.001 {
                let tangent = tangentVel / tangentSpeed
                let frictionImpulseMag = min(combinedFriction * abs(normalImpulseMag), tangentSpeed / invMassSum)
                newVelA = newVelA - tangent * (frictionImpulseMag * invMassA)
                newVelB = newVelB + tangent * (frictionImpulseMag * invMassB)
            }

            // Angular impulse from the contact (scaled for stability)
            let angularScale = settings.contactAngularResponse

            if var bodyA = result[collision.bodyIdA], !isStaticA {
                bodyA.velocity = newVelA
                if angularScale > 0 {
                    let impulse = normal * (-normalImpulseMag * invMassA * angularScale)
                    bodyA.angularVelocity = bodyA.angularVelocity + (collision.contactPoint - bodyA.position).cross(impulse)
                }
                result[collision.bodyIdA] = bodyA
            }
            if var bodyB = result[collision.bodyIdB], !isStaticB {
                bodyB.velocity = newVelB
                if angularScale > 0 {
                    let impulse = normal * (normalImpulseMag * invMassB * angularScale)
                    bodyB.angularVelocity = bodyB.angularVelocity + (collision.contactPoint - bodyB.position).cross(impulse)
                }
                result[collision.bodyIdB] = bodyB
            }
        }

        return result
    }
}
