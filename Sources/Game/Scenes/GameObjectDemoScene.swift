import GameEngine

/// Demo scene showcasing the GameObject system with Camera and MeshRenderer
@MainActor
public final class GameObjectDemoScene: GameObjectScene {
    
    private var playerController: PlayerController?
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Create lighting
        let lightObject = createGameObject(name: "Light")
        let directionalLight = lightObject.addComponent(DirectionalLight.self)
        directionalLight.direction = Vec3d(0.5, 1.0, 0.3)
        directionalLight.intensity = 1.0
        
        let ambientLight = lightObject.addComponent(AmbientLight.self)
        ambientLight.intensity = 0.3
        
        // Create player with camera and controller
        let player = createGameObject(name: "Player", at: Vec3d(0, 0, 5))
        let camera = player.addComponent(Camera.self)
        camera.projection = .perspective
        camera.fieldOfView = 60.0
        camera.nearClipPlane = 0.1
        camera.farClipPlane = 100.0
        camera.backgroundColor = .vsCodeDark
        
        // Add player controller for movement
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
        playerController?.enableMouseLook = true
        
        // Create rotating cube with material
        let cube = createGameObject(name: "Cube", at: Vec3d(0, 0, 0))
        let cubeMaterial = Material.solid(.cornflowerBlue)
        cubeMaterial.shadingModel = .flat
        let meshRenderer = cube.addComponent(MeshRenderer.self)
        meshRenderer.mesh = CubeMesh.shared
        meshRenderer.material = cubeMaterial
        
        // Add rotator component
        let rotator = cube.addComponent(Rotator.self)
        rotator.axis = .up
        rotator.speed = 1.5
        
        // Create a floor plane with darker material
        let floor = createGameObject(name: "Floor", at: Vec3d(0, -1.5, 0))
        let floorMaterial = Material.matte(Color(r: 60, g: 60, b: 60))
        let floorRenderer = floor.addComponent(MeshRenderer.self)
        floorRenderer.mesh = PlaneMesh(width: 10, depth: 10)
        floorRenderer.material = floorMaterial
        
        // Add a second cube with different material
        let cube2 = createGameObject(name: "Cube2", at: Vec3d(2, 0, -1))
        let cube2Material = Material.solid(.red)
        cube2Material.shadingModel = .flat
        let cube2Renderer = cube2.addComponent(MeshRenderer.self)
        cube2Renderer.mesh = CubeMesh.shared
        cube2Renderer.material = cube2Material

        let rotator2 = cube2.addComponent(Rotator.self)
        rotator2.axis = .right
        rotator2.speed = 2.0
        
        // Add a third cube
        let cube3 = createGameObject(name: "Cube3", at: Vec3d(-2, 0, -1))
        let cube3Material = Material.solid(.green)
        cube3Material.shadingModel = .flat
        let cube3Renderer = cube3.addComponent(MeshRenderer.self)
        cube3Renderer.mesh = CubeMesh.shared
        cube3Renderer.material = cube3Material
    
        let rotator3 = cube3.addComponent(Rotator.self)
        rotator3.axis = .forward
        rotator3.speed = 1.0
    }
    
    public override func update(context: FrameContext, input: Input) {
        // Toggle mouse capture on left click
        if input.isMouseButtonPressed(.left) {
            engine?.captureMouse()
        }
        
        // Release mouse capture on right click
        if input.isMouseButtonPressed(.right) {
            engine?.releaseMouse()
        }
        
        // Provide input to player controller
        playerController?.setInput(input)
        
        super.update(context: context, input: input)
    }
    
    // Rendering uses GameObjectScene's default render(context:)
}

