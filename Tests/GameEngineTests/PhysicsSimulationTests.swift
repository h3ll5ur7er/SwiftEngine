import Testing
import Foundation
@testable import GameEngine

@Suite("Physics Simulation Tests")
struct PhysicsSimulationTests {

    let epsilon: Float = 0.001
    let dt: Float = 1.0 / 60.0
    
    // MARK: - Helpers
    
    func body(
        _ id: GameUUID = GameUUID(),
        at position: Vec3d,
        velocity: Vec3d = .zero,
        mass: Float = 1,
        isKinematic: Bool = false,
        force: Vec3d = .zero
    ) -> PhysicsBodyState {
        PhysicsBodyState(
            id: id,
            position: position,
            velocity: velocity,
            mass: mass,
            isKinematic: isKinematic,
            accumulatedForce: force
        )
    }
    
    func sphere(_ body: PhysicsBodyState, radius: Float, isTrigger: Bool = false) -> ColliderSnapshot {
        ColliderSnapshot(
            bodyId: body.id,
            type: .sphere(radius: radius),
            worldCenter: body.position,
            isTrigger: isTrigger,
            boundingSphereRadius: radius
        )
    }
    
    func box(_ body: PhysicsBodyState, halfExtents: Vec3d) -> ColliderSnapshot {
        ColliderSnapshot(
            bodyId: body.id,
            type: .box(halfExtents: halfExtents),
            worldCenter: body.position,
            boundingSphereRadius: halfExtents.length
        )
    }
    
    func ground(_ id: GameUUID = GameUUID()) -> ColliderSnapshot {
        ColliderSnapshot(
            bodyId: id,
            type: .plane(normal: Vec3d(0, 1, 0), offset: 0),
            worldCenter: .zero,
            boundingSphereRadius: .infinity
        )
    }
    
    /// Runs `frames` frames of `frameTime` seconds, feeding results back as input.
    /// Like PhysicsSystem, colliders are re-snapshotted each frame so they follow their bodies.
    func run(
        _ simulation: inout PhysicsSimulation,
        bodies: [PhysicsBodyState],
        colliders: [ColliderSnapshot],
        frames: Int,
        frameTime: Float = 1.0 / 60.0
    ) -> [GameUUID: PhysicsBodyState] {
        var state = Dictionary(uniqueKeysWithValues: bodies.map { ($0.id, $0) })
        let offsets = colliders.map { collider in
            state[collider.bodyId].map { collider.worldCenter - $0.position } ?? .zero
        }
        for _ in 0..<frames {
            let current = zip(colliders, offsets).map { collider, offset in
                ColliderSnapshot(
                    bodyId: collider.bodyId,
                    type: collider.type,
                    worldCenter: (state[collider.bodyId]?.position).map { $0 + offset } ?? collider.worldCenter,
                    isTrigger: collider.isTrigger,
                    boundingSphereRadius: collider.boundingSphereRadius
                )
            }
            let result = simulation.simulate(PhysicsFrameInput(bodies: state, colliders: current, deltaTime: frameTime))
            state = result.updatedBodies
        }
        return state
    }
    
    // MARK: - Integration
    
    @Test("Free fall uses semi-implicit Euler")
    func freeFall() {
        var sim = PhysicsSimulation()
        let b = body(at: Vec3d(0, 10, 0))
        let result = sim.simulate(PhysicsFrameInput(bodies: [b.id: b], colliders: [], deltaTime: dt))
        let updated = result.updatedBodies[b.id]!
        
        #expect(result.stepsExecuted == 1)
        #expect(abs(updated.velocity.y - (-9.81 * dt)) < epsilon)
        #expect(abs(updated.position.y - (10 - 9.81 * dt * dt)) < epsilon)
    }
    
    @Test("Kinematic bodies ignore gravity")
    func kinematicIgnoresGravity() {
        var sim = PhysicsSimulation()
        let b = body(at: Vec3d(0, 10, 0), isKinematic: true)
        let state = run(&sim, bodies: [b], colliders: [], frames: 30)
        #expect(state[b.id]!.position == Vec3d(0, 10, 0))
    }
    
    @Test("Accumulated force is applied once")
    func forceAppliedOnce() {
        var sim = PhysicsSimulation()
        // Exactly cancels gravity for one step
        let b = body(at: .zero, force: Vec3d(0, 9.81, 0))
        let result = sim.simulate(PhysicsFrameInput(bodies: [b.id: b], colliders: [], deltaTime: dt * 2.5))
        let updated = result.updatedBodies[b.id]!
        
        #expect(result.stepsExecuted == 2)
        #expect(abs(updated.velocity.y - (-9.81 * dt)) < epsilon)
        #expect(updated.accumulatedForce == .zero)
    }
    
    @Test("Forces survive frames that run no fixed step")
    func forcesKeptWithoutStep() {
        var sim = PhysicsSimulation()
        let b = body(at: .zero, force: Vec3d(1, 0, 0))
        let result = sim.simulate(PhysicsFrameInput(bodies: [b.id: b], colliders: [], deltaTime: dt / 4))
        
        #expect(result.stepsExecuted == 0)
        #expect(result.updatedBodies[b.id]!.accumulatedForce == Vec3d(1, 0, 0))
    }
    
    // MARK: - Fixed Timestep
    
    @Test("Accumulator carries leftover time between frames")
    func accumulatorCarriesOver() {
        var sim = PhysicsSimulation()
        let input = PhysicsFrameInput(bodies: [:], colliders: [], deltaTime: 0.01)
        #expect(sim.simulate(input).stepsExecuted == 0)
        #expect(sim.simulate(input).stepsExecuted == 1)
    }
    
    @Test("Large frame times are clamped to maxDeltaTime")
    func largeDeltaClamped() {
        var sim = PhysicsSimulation()
        let result = sim.simulate(PhysicsFrameInput(bodies: [:], colliders: [], deltaTime: 1.0))
        #expect(result.stepsExecuted == 2)
    }
    
    // MARK: - Collisions
    
    @Test("Sphere comes to rest on a static plane without a rigid body")
    func sphereRestsOnStaticPlane() {
        var sim = PhysicsSimulation()
        let b = body(at: Vec3d(0, 2, 0))
        let state = run(&sim, bodies: [b], colliders: [sphere(b, radius: 0.5), ground()], frames: 300)
        let rested = state[b.id]!
        
        #expect(abs(rested.position.y - 0.5) < 0.05)
        #expect(rested.velocity.length < 0.5)
    }
    
    @Test("Box comes to rest on a kinematic plane")
    func boxRestsOnKinematicPlane() {
        var sim = PhysicsSimulation()
        let b = body(at: Vec3d(0, 3, 0))
        let floor = body(at: .zero, isKinematic: true)
        let state = run(&sim, bodies: [b, floor], colliders: [box(b, halfExtents: Vec3d(0.5, 0.5, 0.5)), ground(floor.id)], frames: 300)
        
        #expect(abs(state[b.id]!.position.y - 0.5) < 0.05)
        #expect(state[floor.id]!.position == .zero)
    }
    
    @Test("Head-on sphere collision conserves momentum and separates")
    func sphereCollisionConservesMomentum() {
        var sim = PhysicsSimulation()
        let a = body(at: Vec3d(-0.45, 5, 0), velocity: Vec3d(1, 0, 0))
        let b = body(at: Vec3d(0.45, 5, 0), velocity: Vec3d(-1, 0, 0), mass: 2)
        let result = sim.simulate(PhysicsFrameInput(
            bodies: [a.id: a, b.id: b],
            colliders: [sphere(a, radius: 0.5), sphere(b, radius: 0.5)],
            deltaTime: dt
        ))
        let newA = result.updatedBodies[a.id]!
        let newB = result.updatedBodies[b.id]!
        
        #expect(result.collisions.count == 1)
        let momentumBefore: Float = 1 * 1 + 2 * -1
        let momentumAfter = 1 * newA.velocity.x + 2 * newB.velocity.x
        #expect(abs(momentumBefore - momentumAfter) < epsilon)
        #expect(newB.velocity.x - newA.velocity.x >= 0)
    }
    
    @Test("Triggers report overlaps but don't block")
    func triggersDontBlock() {
        var sim = PhysicsSimulation()
        let b = body(at: Vec3d(0, 0.4, 0), velocity: Vec3d(0, -1, 0))
        let result = sim.simulate(PhysicsFrameInput(
            bodies: [b.id: b],
            colliders: [sphere(b, radius: 0.5, isTrigger: true), ground()],
            deltaTime: dt
        ))
        
        #expect(result.collisions.count == 1)
        #expect(result.collisions[0].isTrigger)
        #expect(result.updatedBodies[b.id]!.position.y < 0.4)
    }
    
    @Test("Collider offset from body position is preserved while moving")
    func colliderOffsetFollowsBody() {
        var sim = PhysicsSimulation()
        // Body origin at y=2 with a sphere collider centered 1 unit below it
        let b = body(at: Vec3d(0, 2, 0))
        let collider = ColliderSnapshot(
            bodyId: b.id,
            type: .sphere(radius: 0.5),
            worldCenter: Vec3d(0, 1, 0),
            boundingSphereRadius: 0.5
        )
        let state = run(&sim, bodies: [b], colliders: [collider, ground()], frames: 300)
        
        // The collider (not the origin) rests on the ground
        #expect(abs(state[b.id]!.position.y - 1.5) < 0.05)
    }
    
    // MARK: - Actor
    
    @Test("PhysicsActor runs the same simulation")
    func actorMatchesSimulation() async {
        var sim = PhysicsSimulation()
        let actor = PhysicsActor()
        let b = body(at: Vec3d(0, 2, 0))
        let input = PhysicsFrameInput(bodies: [b.id: b], colliders: [sphere(b, radius: 0.5), ground()], deltaTime: dt)
        
        let expected = sim.simulate(input)
        let actual = await actor.simulate(input: input)
        
        #expect(actual.updatedBodies[b.id]!.position == expected.updatedBodies[b.id]!.position)
        #expect(actual.stepsExecuted == expected.stepsExecuted)
    }
}
