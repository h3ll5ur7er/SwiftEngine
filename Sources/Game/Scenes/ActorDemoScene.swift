import GameEngine
import Foundation

/// Demo scene showcasing the actor-based concurrency system
/// Demonstrates async asset loading, physics simulation, and game logic
@MainActor
public final class ActorDemoScene: GameObjectScene {
    
    private var playerController: PlayerController?
    private var physicsObjects: [GameObject] = []
    private var spawnTimer: Float = 0
    
    // Stats overlay
    private var statsOverlay: UIOverlay!
    private var fpsText: Text!
    private var physicsUPSText: Text!
    private var bodiesText: Text!
    private var collidersText: Text!
    private var collisionsText: Text!
    private var debugText: Text!
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Create lighting
        let lightObject = createGameObject(name: "Light")
        let directionalLight = lightObject.addComponent(DirectionalLight.self)
        directionalLight.direction = Vec3d(0.5, 1.0, 0.3)
        directionalLight.intensity = 1.0
        
        let ambientLight = lightObject.addComponent(AmbientLight.self)
        ambientLight.intensity = 0.3
        
        // Create player with camera
        let player = createGameObject(name: "Player", at: Vec3d(0, 3, 10))
        let camera = player.addComponent(Camera.self)
        camera.projection = .perspective
        camera.fieldOfView = 60.0
        camera.nearClipPlane = 0.1
        camera.farClipPlane = 100.0
        camera.backgroundColor = Color(r: 20, g: 20, b: 30)
        
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
        playerController?.enableMouseLook = true
        
        // Create ground plane with physics
        let floor = createGameObject(name: "Floor", at: Vec3d(0, 0, 0))
        let floorMaterial = Material.matte(Color(r: 40, g: 80, b: 40))
        let floorRenderer = floor.addComponent(MeshRenderer.self)
        floorRenderer.mesh = PlaneMesh(width: 30, depth: 30)
        floorRenderer.material = floorMaterial
        
        // Add plane collider for efficient ground collision
        let floorCollider = floor.addComponent(PlaneCollider.self)
        floorCollider.normal = Vec3d(0, 1, 0)  // Pointing up
        floorCollider.material = .stone  // Low bounciness, good friction
        
        // Add kinematic rigid body so it participates in physics but doesn't move
        let floorRigidBody = floor.addComponent(RigidBody.self)
        floorRigidBody.isKinematic = true
        
        // Create initial physics cubes
        spawnPhysicsCubes(count: 5)
        
        // Register a custom game logic handler for a "Spinner" behavior
        Task {
            await GameLogicActor.shared.registerHandler(for: "SpinnerTag") { snapshot, deltaTime in
                // Rotate based on deltaTime (demonstrates async game logic)
                let currentRotation = snapshot.rotation
                let spinRotation = Quaternion.fromAxisAngle(axis: .up, angle: deltaTime * 2.0)
                let newRotation = currentRotation * spinRotation
                return TransformUpdate(rotation: newRotation)
            }
        }
        
        // Create some spinning markers
        for i in 0..<4 {
            let angle = Float(i) * (.pi / 2.0)
            let x = cos(angle) * 8.0
            let z = sin(angle) * 8.0
            
            let spinner = createGameObject(name: "Spinner\(i)", at: Vec3d(x, 1, z))
            spinner.tag = "SpinnerTag"
            
            let material = Material.solid([Color.red, Color.green, Color.blue, Color.yellow][i])
            material.shadingModel = .flat
            
            let meshRenderer = spinner.addComponent(MeshRenderer.self)
            meshRenderer.mesh = CubeMesh.shared
            meshRenderer.material = material
        }
        
        // Setup stats overlay
        setupStatsOverlay()
    }
    
    private func setupStatsOverlay() {
        let theme = ThemeManager.shared.current
        
        // Create reusable text elements
        let fps = Text("FPS: --")
            .foregroundColor(theme.textPrimary)
        fpsText = fps
        
        let physics = Text("Physics: -- UPS")
            .foregroundColor(theme.textSecondary)
        physicsUPSText = physics
        
        let bodies = Text("Bodies: 0")
            .foregroundColor(theme.textSecondary)
        bodiesText = bodies
        
        let colliders = Text("Colliders: 0")
            .foregroundColor(theme.textSecondary)
        collidersText = colliders
        
        let collisions = Text("Collisions: 0")
            .foregroundColor(theme.textSecondary)
        collisionsText = collisions
        
        let debug = Text("Debug: ON")
            .foregroundColor(Color(r: 0, g: 255, b: 0))
        debugText = debug
        
        // Create overlay
        let statsObject = createGameObject(name: "StatsOverlay")
        statsOverlay = statsObject.addComponent(UIOverlay.self)
        statsOverlay.depth = 0
        statsOverlay.padding = EdgeInsets(10)
        
        statsOverlay.setContent {
            VStack(alignment: .leading, spacing: 4) {
                Text("Actor Demo Stats")
                    .foregroundColor(theme.primary)
                
                Divider()
                    .padding(EdgeInsets(horizontal: 0, vertical: 4))
                
                fps
                physics
                
                Divider()
                    .padding(EdgeInsets(horizontal: 0, vertical: 4))
                
                bodies
                colliders
                collisions
                debug
                
                Divider()
                    .padding(EdgeInsets(horizontal: 0, vertical: 4))
                
                Text("Controls:")
                    .foregroundColor(theme.primary)
                Text("WASD - Move")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                Text("Mouse - Look")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                Text("Space - Spawn cubes")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                Text("F1 - Toggle debug")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                Text("Left click - Capture mouse")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                Text("Right click - Release mouse")
                    .foregroundColor(Color(r: 120, g: 120, b: 120))
                
                Spacer()
            }
        }
    }
    
    private func spawnPhysicsCubes(count: Int) {
        // Available physics materials for variety
        let physicsMaterials: [PhysicsMaterial] = [
            .rubber,      // Bouncy
            .wood,        // Medium bounce, light
            .metal,       // Heavy, some bounce
            .stone,       // Heavy, low bounce
            .bouncyBall,  // Super bouncy
        ]
        
        for _ in 0..<count {
            // Spawn cubes in a tighter cluster to encourage stacking
            let x = Float.random(in: -1...1)
            let y = Float(physicsObjects.count) * 1.5 + 3.0  // Stack vertically with spacing
            let z = Float.random(in: -1...1)
            
            let cube = createGameObject(name: "PhysicsCube\(physicsObjects.count)", at: Vec3d(x, y, z))
            
            // Random color
            let colors: [Color] = [.red, .green, .blue, .yellow, .cyan, .magenta, .orange]
            let material = Material.solid(colors.randomElement()!)
            material.shadingModel = .flat
            
            let meshRenderer = cube.addComponent(MeshRenderer.self)
            meshRenderer.mesh = CubeMesh.shared
            meshRenderer.material = material
            
            // Add collider with random physics material
            let collider = cube.addComponent(BoxCollider.self)
            collider.halfExtents = Vec3d(0.5, 0.5, 0.5)
            collider.material = physicsMaterials.randomElement()!
            
            // Add physics - mass is calculated from collider volume and material density
            let rigidBody = cube.addComponent(RigidBody.self)
            rigidBody.mass = collider.calculatedMass
            
            // Random initial rotation
            cube.transform.rotation = Quaternion.fromAxisAngle(
                axis: Vec3d(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)).normalized,
                angle: Float.random(in: 0...(.pi * 2))
            )
            
            physicsObjects.append(cube)
        }
    }
    
    public override func update(context: FrameContext, input: Input) {
        // Toggle mouse capture
        if input.isMouseButtonPressed(.left) {
            engine?.captureMouse()
        }
        if input.isMouseButtonPressed(.right) {
            engine?.releaseMouse()
        }
        
        // Provide input to player controller
        playerController?.setInput(input)
        
        // Spawn more cubes with space bar
        if input.isKeyPressed(.space) {
            spawnPhysicsCubes(count: 3)
        }
        
        // Toggle debug drawing with F1
        if input.isKeyPressed(.f1) {
            DebugDraw.shared.showColliders.toggle()
        }
        
        // Update stats overlay
        updateStats(context: context)
        
        // Physics is now handled by PhysicsSystem in the engine
        
        // Auto-spawn timer
        spawnTimer += Float(context.deltaTime)
        if spawnTimer > 3.0 && physicsObjects.count < 50 {
            spawnTimer = 0
            spawnPhysicsCubes(count: 1)
        }
        
        super.update(context: context, input: input)
    }
    
    private func updateStats(context: FrameContext) {
        let fps = Int(context.fps)
        let physicsSteps = PhysicsSystem.shared.stepsThisFrame
        let bodies = PhysicsSystem.shared.bodyCount
        let activeBodies = PhysicsSystem.shared.activeBodyCount
        let colliders = CollisionManager.shared.colliderCount
        let collisions = PhysicsSystem.shared.collisionsThisFrame
        let debugOn = DebugDraw.shared.showColliders
        
        fpsText.content = "FPS: \(fps)"
        physicsUPSText.content = "Physics: \(physicsSteps) steps"
        bodiesText.content = "Bodies: \(activeBodies)/\(bodies)"
        collidersText.content = "Colliders: \(colliders)"
        collisionsText.content = "Collisions: \(collisions)"
        debugText.content = "Debug: \(debugOn ? "ON" : "OFF") (F1)"
        debugText.color = debugOn ? Color(r: 0, g: 255, b: 0) : Color(r: 150, g: 150, b: 150)
    }
    
    public override func render(context: RenderContext) {
        // Clear with camera background
        let bgColor = Camera.main?.backgroundColor ?? .black
        context.renderer.clear(bgColor)
        
        // Render 3D scene
        if let camera = Camera.main {
            camera.aspectRatio = Float(context.width) / Float(context.height)
            
            let meshRenderers = findComponentsOfType(MeshRenderer.self)
            RenderPipeline.shared.render(
                meshRenderers: meshRenderers,
                camera: camera,
                context: context
            )
            
            // Draw debug collider wireframes
            DebugDraw.shared.draw(context: context, camera: camera)
        }
        
        // Render UI overlays on top
        renderUIOverlays(context: context)
    }
}
