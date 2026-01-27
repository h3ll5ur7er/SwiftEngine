import Foundation

/// Manages collision detection and response
@MainActor
public final class CollisionManager {
    
    /// Shared instance
    public static let shared = CollisionManager()
    
    /// All active colliders
    private var colliders: [Collider] = []
    
    /// Collision callbacks
    public var onCollision: ((Collider, Collider, CollisionInfo) -> Void)?
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register a collider
    public func register(_ collider: Collider) {
        if !colliders.contains(where: { $0 === collider }) {
            colliders.append(collider)
        }
    }
    
    /// Unregister a collider
    public func unregister(_ collider: Collider) {
        colliders.removeAll { $0 === collider }
    }
    
    /// Clear all colliders
    public func clear() {
        colliders.removeAll()
    }
    
    /// Get the number of registered colliders
    public var colliderCount: Int {
        colliders.count
    }
    
    /// Get all registered colliders (for debug drawing)
    public var allColliders: [Collider] {
        colliders
    }
    
    // MARK: - Collision Detection
    
    /// Debug output flag
    public var debugOutput: Bool = false
    private var debugFrameCounter: Int = 0
    
    /// Perform collision detection and return all collision pairs
    public func detectCollisions() -> [(Collider, Collider, CollisionInfo)] {
        var collisions: [(Collider, Collider, CollisionInfo)] = []
        
        let activeColliders = colliders.filter { $0.isEnabled && $0.gameObject?.isActive == true }
        
        debugFrameCounter += 1
        let shouldPrint = debugOutput && (debugFrameCounter % 60 == 0)
        
        if shouldPrint {
            print("[CollisionManager] Active colliders: \(activeColliders.count)")
            for c in activeColliders {
                let name = c.gameObject?.name ?? "unknown"
                let type = c.colliderType
                let center = c.worldCenter
                print("  - \(name): type=\(type) center=(\(String(format: "%.2f", center.x)), \(String(format: "%.2f", center.y)), \(String(format: "%.2f", center.z)))")
            }
        }
        
        // Broad phase + narrow phase (simple O(n²) for now)
        for i in 0..<activeColliders.count {
            for j in (i + 1)..<activeColliders.count {
                let a = activeColliders[i]
                let b = activeColliders[j]
                
                // Skip if both are triggers
                if a.isTrigger && b.isTrigger { continue }
                
                // Skip if different layers (unless layer is 0 which collides with everything)
                if a.layer != 0 && b.layer != 0 && a.layer != b.layer { continue }
                
                // Broad phase: bounding sphere check
                // Skip broad phase if either collider has infinite bounds (e.g., PlaneCollider)
                let radiusA = a.boundingSphereRadius
                let radiusB = b.boundingSphereRadius
                let skipBroadPhase = radiusA.isInfinite || radiusB.isInfinite
                
                if !skipBroadPhase {
                    let centerA = a.worldCenter
                    let centerB = b.worldCenter
                    let dx = centerB.x - centerA.x
                    let dy = centerB.y - centerA.y
                    let dz = centerB.z - centerA.z
                    let distSquared = dx * dx + dy * dy + dz * dz
                    let radiusSum = radiusA + radiusB
                    
                    if distSquared > radiusSum * radiusSum {
                        continue // No possible collision
                    }
                }
                
                // Narrow phase
                if let info = a.intersects(with: b) {
                    collisions.append((a, b, info))
                    onCollision?(a, b, info)
                }
            }
        }
        
        return collisions
    }
    
    /// Resolve collisions by separating objects and adjusting velocities
    public func resolveCollisions(
        _ collisions: [(Collider, Collider, CollisionInfo)],
        getRigidBody: (Collider) -> RigidBody?
    ) {
        for (colliderA, colliderB, info) in collisions {
            // Skip triggers
            if colliderA.isTrigger || colliderB.isTrigger { continue }
            
            let rigidBodyA = getRigidBody(colliderA)
            let rigidBodyB = getRigidBody(colliderB)
            
            let isKinematicA = rigidBodyA?.isKinematic ?? true
            let isKinematicB = rigidBodyB?.isKinematic ?? true
            
            // If both are kinematic or neither has a rigidbody, skip
            if isKinematicA && isKinematicB { continue }
            
            // Get combined material properties
            let materialA = colliderA.material
            let materialB = colliderB.material
            let combinedFriction = PhysicsMaterial.combinedFriction(materialA, materialB)
            let combinedBounciness = PhysicsMaterial.combinedBounciness(materialA, materialB)
            
            // Calculate mass ratios for position correction
            // Kinematic objects don't move, so they absorb 0% of the correction
            // Dynamic objects absorb correction proportional to the other object's mass
            let massA = rigidBodyA?.mass ?? 1.0
            let massB = rigidBodyB?.mass ?? 1.0
            
            let ratioA: Float
            let ratioB: Float
            
            if isKinematicA && !isKinematicB {
                // A is kinematic, B takes all the correction
                ratioA = 0
                ratioB = 1.0
            } else if !isKinematicA && isKinematicB {
                // B is kinematic, A takes all the correction
                ratioA = 1.0
                ratioB = 0
            } else {
                // Both dynamic - split based on inverse mass
                let totalMass = massA + massB
                ratioA = massB / totalMass
                ratioB = massA / totalMass
            }
            
            let normal = info.normal
            let penetration = info.penetrationDepth
            
            // Skip tiny penetrations to avoid jitter
            if penetration < 0.001 { continue }
            
            // For position correction: always fully correct penetration to prevent falling through
            // The key is to correct 100% of penetration for proper collision response
            // We use a small bias to push objects slightly apart
            let correctionBias: Float = 0.01
            let correctionAmount = penetration + correctionBias
            
            // Separate the objects
            // Normal points from A to B, so A moves in -normal direction (away from B), B moves in +normal direction (away from A)
            if let goA = colliderA.gameObject, !isKinematicA {
                let posA = goA.transform.position
                let newPosA = Vec3d(
                    posA.x - normal.x * correctionAmount * ratioA,
                    posA.y - normal.y * correctionAmount * ratioA,
                    posA.z - normal.z * correctionAmount * ratioA
                )
                goA.transform.position = newPosA
            }
            
            if let goB = colliderB.gameObject, !isKinematicB {
                let posB = goB.transform.position
                let newPosB = Vec3d(
                    posB.x + normal.x * correctionAmount * ratioB,
                    posB.y + normal.y * correctionAmount * ratioB,
                    posB.z + normal.z * correctionAmount * ratioB
                )
                goB.transform.position = newPosB
            }
            
            // Adjust velocities using impulse-based collision response
            let velA = rigidBodyA?.velocity ?? .zero
            let velB = rigidBodyB?.velocity ?? .zero
            
            // Relative velocity along normal
            // Normal points from A to B
            // If relVelNormal < 0, objects are approaching (A is moving toward B along normal)
            // For Floor (A) vs Cube (B): velA=0, velB=(0,-19,0), relVel=(0,19,0)
            // normal=(0,1,0), relVelNormal=19 > 0, meaning Floor is moving away from Cube (or Cube toward Floor)
            // Wait that's still wrong...
            // 
            // Let's think differently: relVelNormal > 0 means they're separating
            // relVel = velA - velB = 0 - (0,-19,0) = (0,19,0)
            // relVelNormal = relVel · normal = (0,19,0) · (0,1,0) = 19
            // This is POSITIVE, but the cube IS approaching the floor...
            // 
            // The issue is our normal direction. Normal points from A (Floor) to B (Cube), which is UP.
            // relVel · normal gives the closing velocity. Positive = separating, Negative = approaching.
            // But relVel = velA - velB = -velB = (0, 19, 0), dotted with normal (0,1,0) = 19
            // So it says they're separating, which is WRONG.
            //
            // The fix: normal should point from the surface INTO the colliding object.
            // Or we should use velB - velA instead.
            // 
            // Standard: relVel = velB - velA, then relVelNormal = relVel · normal
            // If relVelNormal > 0, B is moving in direction of normal (away from A)
            // If relVelNormal < 0, B is moving opposite to normal (toward A)
            
            let relVelNormal = (velB.x - velA.x) * normal.x + (velB.y - velA.y) * normal.y + (velB.z - velA.z) * normal.z
            
            // Don't resolve if objects are already separating (relVelNormal > 0)
            if relVelNormal > 0 { continue }
            
            // Calculate inverse masses (0 for kinematic objects)
            let invMassA = isKinematicA ? 0.0 : (1.0 / massA)
            let invMassB = isKinematicB ? 0.0 : (1.0 / massB)
            let invMassSum = invMassA + invMassB
            
            guard invMassSum > 0 else { continue }
            
            // Normal impulse magnitude (using combined bounciness)
            let normalImpulseMag = -(1.0 + combinedBounciness) * relVelNormal / invMassSum
            
            // Angular impulse scale factor for stability
            let angularScale: Float = 0.3
            
            // Apply normal impulse
            if let rbA = rigidBodyA, !isKinematicA {
                let newVelA = Vec3d(
                    velA.x - normalImpulseMag * invMassA * normal.x,
                    velA.y - normalImpulseMag * invMassA * normal.y,
                    velA.z - normalImpulseMag * invMassA * normal.z
                )
                rbA.setVelocity(newVelA)
                
                // Apply angular impulse based on contact point offset (scaled down for stability)
                let centerA = colliderA.worldCenter
                let rA = Vec3d(
                    info.contactPoint.x - centerA.x,
                    info.contactPoint.y - centerA.y,
                    info.contactPoint.z - centerA.z
                )
                // Torque = r × impulse (cross product), scaled down for stability
                let impulseA = Vec3d(
                    -normalImpulseMag * invMassA * normal.x * angularScale,
                    -normalImpulseMag * invMassA * normal.y * angularScale,
                    -normalImpulseMag * invMassA * normal.z * angularScale
                )
                let torqueA = Vec3d(
                    rA.y * impulseA.z - rA.z * impulseA.y,
                    rA.z * impulseA.x - rA.x * impulseA.z,
                    rA.x * impulseA.y - rA.y * impulseA.x
                )
                rbA.addAngularImpulse(torqueA)
            }
            
            if let rbB = rigidBodyB, !isKinematicB {
                let newVelB = Vec3d(
                    velB.x + normalImpulseMag * invMassB * normal.x,
                    velB.y + normalImpulseMag * invMassB * normal.y,
                    velB.z + normalImpulseMag * invMassB * normal.z
                )
                rbB.setVelocity(newVelB)
                
                // Apply angular impulse based on contact point offset (scaled down for stability)
                let centerB = colliderB.worldCenter
                let rB = Vec3d(
                    info.contactPoint.x - centerB.x,
                    info.contactPoint.y - centerB.y,
                    info.contactPoint.z - centerB.z
                )
                // Torque = r × impulse (cross product), scaled down for stability
                let impulseB = Vec3d(
                    normalImpulseMag * invMassB * normal.x * angularScale,
                    normalImpulseMag * invMassB * normal.y * angularScale,
                    normalImpulseMag * invMassB * normal.z * angularScale
                )
                let torqueB = Vec3d(
                    rB.y * impulseB.z - rB.z * impulseB.y,
                    rB.z * impulseB.x - rB.x * impulseB.z,
                    rB.x * impulseB.y - rB.y * impulseB.x
                )
                rbB.addAngularImpulse(torqueB)
            }
            
            // Apply friction impulse (tangent to contact surface)
            // Recalculate velocities after normal impulse
            let newVelA = rigidBodyA?.velocity ?? .zero
            let newVelB = rigidBodyB?.velocity ?? .zero
            let newRelVel = Vec3d(newVelA.x - newVelB.x, newVelA.y - newVelB.y, newVelA.z - newVelB.z)
            
            // Get tangent velocity (velocity perpendicular to normal)
            let newRelVelNormal = newRelVel.x * normal.x + newRelVel.y * normal.y + newRelVel.z * normal.z
            let tangentVel = Vec3d(
                newRelVel.x - newRelVelNormal * normal.x,
                newRelVel.y - newRelVelNormal * normal.y,
                newRelVel.z - newRelVelNormal * normal.z
            )
            
            let tangentSpeed = sqrt(tangentVel.x * tangentVel.x + tangentVel.y * tangentVel.y + tangentVel.z * tangentVel.z)
            
            if tangentSpeed > 0.001 {
                // Normalize tangent direction
                let tangent = Vec3d(tangentVel.x / tangentSpeed, tangentVel.y / tangentSpeed, tangentVel.z / tangentSpeed)
                
                // Calculate friction impulse (clamped by Coulomb friction)
                let frictionImpulseMag = min(combinedFriction * abs(normalImpulseMag), tangentSpeed / invMassSum)
                
                // Apply friction impulse
                if let rbA = rigidBodyA, !isKinematicA {
                    let vel = rbA.velocity
                    rbA.setVelocity(Vec3d(
                        vel.x - frictionImpulseMag * invMassA * tangent.x,
                        vel.y - frictionImpulseMag * invMassA * tangent.y,
                        vel.z - frictionImpulseMag * invMassA * tangent.z
                    ))
                }
                
                if let rbB = rigidBodyB, !isKinematicB {
                    let vel = rbB.velocity
                    rbB.setVelocity(Vec3d(
                        vel.x + frictionImpulseMag * invMassB * tangent.x,
                        vel.y + frictionImpulseMag * invMassB * tangent.y,
                        vel.z + frictionImpulseMag * invMassB * tangent.z
                    ))
                }
            }
        }
    }
}
