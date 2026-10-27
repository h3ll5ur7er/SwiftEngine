import Testing
@testable import GameEngine

/// Marker component the coordinator test registers a handler for
@MainActor
final class CoordinatorTestMarker: Component {}

@Suite("ActorCoordinator Tests")
@MainActor
struct ActorCoordinatorTests {
    
    @Test("GameLogicActor handlers run and their transform updates are applied")
    func gameLogicHandlersApplied() async {
        await GameLogicActor.shared.registerHandler(for: "CoordinatorTestMarker") { snapshot, _ in
            TransformUpdate(position: snapshot.position + Vec3d(0, 1, 0))
        }
        
        let marked = GameObject(name: "Marked")
        marked.addComponent(CoordinatorTestMarker.self)
        let unmarked = GameObject(name: "Unmarked")
        
        await ActorCoordinator.shared.update(deltaTime: 0.016, gameObjects: [marked, unmarked])
        await GameLogicActor.shared.unregisterHandler(for: "CoordinatorTestMarker")
        
        #expect(marked.transform.position == Vec3d(0, 1, 0))
        #expect(unmarked.transform.position == .zero)
    }
}
