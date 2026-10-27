import Testing
@testable import GameEngine

@Suite("Rotator Tests")
@MainActor
struct RotatorTests {

    let epsilon: Float = 0.001
    
    func isClose(_ a: Vec3d, _ b: Vec3d) -> Bool {
        abs(a.x - b.x) < epsilon && abs(a.y - b.y) < epsilon && abs(a.z - b.z) < epsilon
    }
    
    /// An object tipped 90° about Z, so its local up axis points along world -X
    func tippedObject(localSpace: Bool) -> GameObject {
        let go = GameObject(name: "Tipped")
        go.transform.rotation = Quaternion.fromAxisAngle(axis: .unitZ, angle: .pi / 2)
        go.addComponent(Rotator(axis: .up, speed: .pi / 2, useLocalSpace: localSpace))
        return go
    }
    
    @Test("Local space rotates about the object's own axis")
    func localSpace() {
        let go = tippedObject(localSpace: true)
        let upBefore = go.transform.up
        go.getComponent(Rotator.self)!.update(deltaTime: 1)
        
        // Spinning about its own up axis leaves that axis unchanged
        #expect(isClose(go.transform.up, upBefore))
    }
    
    @Test("World space rotates about the world axis")
    func worldSpace() {
        let go = tippedObject(localSpace: false)
        go.getComponent(Rotator.self)!.update(deltaTime: 1)
        
        // Local up was world -X; a quarter turn about world Y takes it to world +Z
        #expect(isClose(go.transform.up, Vec3d(0, 0, 1)))
    }
}
