import Testing
@testable import GameEngine

/// Tests that touch engine-wide singletons (PhysicsSystem, CollisionManager,
/// ActorCoordinator) are nested here so they run serially, never alongside each other.
@Suite("Engine Singletons", .serialized)
enum EngineSingletonTests {}

/// Resets PhysicsSystem and CollisionManager at the start of each test.
extension EngineSingletonTests {
    @Suite("PhysicsSystem Tests")
    @MainActor
    struct PhysicsSystemTests {
    
        let scene = GameObjectScene()
        
        init() {
            PhysicsSystem.shared.clear()
            CollisionManager.shared.clear()
            CollisionManager.shared.onCollision = nil
        }
        
        func makeBall(at position: Vec3d) -> (GameObject, RigidBody) {
            let ball = scene.createGameObject(name: "Ball", at: position)
            ball.addComponent(SphereCollider(radius: 0.5))
            let body = ball.addComponent(RigidBody.self)
            return (ball, body)
        }
        
        func makeStaticFloor() -> PlaneCollider {
            scene.createGameObject(name: "Floor").addComponent(PlaneCollider.self)
        }
        
        @Test("Forces added on frames without a fixed step are not lost")
        func forcesKeptAcrossShortFrames() {
            let (_, body) = makeBall(at: Vec3d(0, 10, 0))
            body.addForce(Vec3d(60, 0, 0))
            
            // Too short for a 60Hz step
            PhysicsSystem.shared.update(deltaTime: 0.005)
            #expect(PhysicsSystem.shared.stepsThisFrame == 0)
            #expect(body.accumulatedForce == Vec3d(60, 0, 0))
            
            PhysicsSystem.shared.update(deltaTime: 0.015)
            #expect(PhysicsSystem.shared.stepsThisFrame == 1)
            #expect(body.velocity.x > 0.9)
            #expect(body.accumulatedForce == .zero)
        }
        
        @Test("A static collider without a RigidBody stops falling bodies")
        func staticColliderBlocks() {
            let (ball, _) = makeBall(at: Vec3d(0, 2, 0))
            _ = makeStaticFloor()
            
            for _ in 0..<300 {
                PhysicsSystem.shared.update(deltaTime: 1.0 / 60.0)
            }
            
            #expect(abs(ball.transform.position.y - 0.5) < 0.05)
        }
        
        @Test("onCollision is reported once per pair per frame")
        func onCollisionReported() {
            let (ball, _) = makeBall(at: Vec3d(0, 0.45, 0))
            let floor = makeStaticFloor()
            
            var reports: [(Collider, Collider, CollisionInfo)] = []
            CollisionManager.shared.onCollision = { a, b, info in
                reports.append((a, b, info))
            }
            
            // Several steps in one frame
            PhysicsSystem.shared.update(deltaTime: 1.0 / 30.0)
            
            #expect(PhysicsSystem.shared.stepsThisFrame == 2)
            #expect(reports.count == 1)
            let colliders = Set([reports[0].0, reports[0].1].map { ObjectIdentifier($0) })
            #expect(colliders == Set([ObjectIdentifier(ball.getComponent(SphereCollider.self)!), ObjectIdentifier(floor)]))
            #expect(reports[0].2.other === reports[0].1)
        }
    }
}
