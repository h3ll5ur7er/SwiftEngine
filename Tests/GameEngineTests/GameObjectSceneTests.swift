import Testing
@testable import GameEngine

/// Records which lifecycle methods were called, in order
@MainActor
final class LifecycleRecorder: Component {
    var calls: [String] = []
    
    override func awake() { calls.append("awake") }
    override func onEnable() { calls.append("onEnable") }
    override func start() { calls.append("start") }
    override func update(deltaTime: Float) { calls.append("update") }
    override func onDisable() { calls.append("onDisable") }
}

@Suite("GameObjectScene Tests")
@MainActor
struct GameObjectSceneTests {

    let input = Input()
    
    func frame(_ n: UInt64 = 0) -> FrameContext {
        FrameContext(deltaTime: 0.016, totalTime: 0.016 * Double(n + 1), frameCount: n, fps: 60)
    }
    
    // MARK: - Lifecycle
    
    @Test("start() is called before the first update for objects created during setup")
    func startCalledForInitialObjects() {
        let scene = GameObjectScene()
        let recorder = scene.createGameObject(name: "A").addComponent(LifecycleRecorder.self)
        
        #expect(recorder.calls == ["awake", "onEnable"])
        
        scene.update(context: frame(), input: input)
        
        #expect(recorder.calls == ["awake", "onEnable", "start", "update"])
    }
    
    @Test("start() is called exactly once")
    func startCalledOnce() {
        let scene = GameObjectScene()
        let recorder = scene.createGameObject(name: "A").addComponent(LifecycleRecorder.self)
        
        scene.update(context: frame(0), input: input)
        scene.update(context: frame(1), input: input)
        scene.update(context: frame(2), input: input)
        
        #expect(recorder.calls.filter { $0 == "start" }.count == 1)
        #expect(recorder.calls.filter { $0 == "update" }.count == 3)
    }
    
    @Test("Objects created after the first frame are started on the next frame")
    func startCalledForLateObjects() {
        let scene = GameObjectScene()
        scene.update(context: frame(0), input: input)
        
        let recorder = scene.createGameObject(name: "Late").addComponent(LifecycleRecorder.self)
        #expect(!recorder.calls.contains("start"))
        
        scene.update(context: frame(1), input: input)
        #expect(recorder.calls == ["awake", "onEnable", "start", "update"])
    }
    
    @Test("Components added to a started object are started immediately")
    func componentAddedToStartedObject() {
        let scene = GameObjectScene()
        let go = scene.createGameObject(name: "A")
        scene.update(context: frame(0), input: input)
        
        let recorder = go.addComponent(LifecycleRecorder.self)
        #expect(recorder.calls == ["awake", "onEnable", "start"])
    }
    
    @Test("Unloading and reloading a scene starts objects again")
    func reloadStartsObjects() {
        let engine = Engine(config: EngineConfig(title: "Test", width: 64, height: 64))
        let scene = GameObjectScene()
        scene.onLoad(engine: engine)
        scene.update(context: frame(0), input: input)
        scene.onUnload(engine: engine)
        
        let recorder = scene.createGameObject(name: "B").addComponent(LifecycleRecorder.self)
        scene.update(context: frame(1), input: input)
        
        #expect(recorder.calls.contains("start"))
    }
    
    @Test("Toggling isEnabled calls onDisable/onEnable")
    func toggleEnabled() {
        let go = GameObject(name: "A")
        let recorder = go.addComponent(LifecycleRecorder.self)
        recorder.calls.removeAll()
        
        recorder.isEnabled = false
        recorder.isEnabled = false
        recorder.isEnabled = true
        #expect(recorder.calls == ["onDisable", "onEnable"])
        
        // No callbacks while the GameObject is inactive
        go.isActive = false
        recorder.calls.removeAll()
        recorder.isEnabled = false
        #expect(recorder.calls.isEmpty)
    }
    
    // MARK: - Lookup
    
    @Test("Tags and names set after creation are found by lookups")
    func lookupsFollowRenames() {
        let scene = GameObjectScene()
        let go = scene.createGameObject(name: "Old")
        go.tag = "Enemy"
        go.name = "New"
        
        #expect(scene.findWithTag("Enemy").map(\.name) == ["New"])
        #expect(scene.findWithTag("Untagged").isEmpty)
        #expect(scene.find(name: "New") === go)
        #expect(scene.find(name: "Old") == nil)
    }
    
    // MARK: - Hierarchy
    
    @Test("GameObject.parent reflects setParent")
    func parentReflectsSetParent() {
        let parent = GameObject(name: "Parent")
        let child = GameObject(name: "Child")
        
        #expect(child.parent == nil)
        
        child.setParent(parent)
        #expect(child.parent === parent)
        #expect(parent.children.map(\.name) == ["Child"])
        
        child.setParent(nil)
        #expect(child.parent == nil)
        #expect(parent.children.isEmpty)
    }
    
    @Test("Transform links back to its GameObject")
    func transformBackReference() {
        let go = GameObject(name: "A")
        #expect(go.transform.gameObject === go)
    }
    
    @Test("Destroying a parent destroys its children")
    func destroyParentDestroysChildren() {
        let scene = GameObjectScene()
        let parent = scene.createGameObject(name: "Parent")
        let child = scene.createGameObject(name: "Child")
        child.setParent(parent)
        
        scene.destroy(parent)
        scene.update(context: frame(), input: input)
        
        #expect(scene.find(name: "Parent") == nil)
        #expect(scene.find(name: "Child") == nil)
        #expect(scene.allGameObjects.isEmpty)
    }
}
