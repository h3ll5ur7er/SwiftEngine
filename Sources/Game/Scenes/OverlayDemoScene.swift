import GameEngine

/// Demo scene showcasing 3D rendering with UI overlay
@MainActor
public final class OverlayDemoScene: GameObjectScene {
    
    // Player
    private var playerController: PlayerController?
    
    // UI references for dynamic updates
    private var fpsText: Text?
    private var positionText: Text?
    private var rotationText: Text?
    private var cubeCountText: Text?
    
    // Game state
    private var cubeCount = 3
    private var isPaused = false
    private var showHelp = true
    
    // UI overlays
    private var hudOverlay: UIOverlay!
    private var helpOverlay: UIOverlay!
    private var pauseOverlay: UIOverlay!
    
    // Frame time tracking
    private var frameTimeAccumulator: Float = 0
    private var frameCount = 0
    private var currentFPS: Int = 0
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        setupLighting()
        setupPlayer()
        setupScene()
        setupUI()
    }
    
    // MARK: - Scene Setup
    
    private func setupLighting() {
        let lightObject = createGameObject(name: "Light")
        
        let directionalLight = lightObject.addComponent(DirectionalLight.self)
        directionalLight.direction = Vec3d(0.5, 1.0, 0.3)
        directionalLight.intensity = 1.0
        
        let ambientLight = lightObject.addComponent(AmbientLight.self)
        ambientLight.intensity = 0.3
    }
    
    private func setupPlayer() {
        let player = createGameObject(name: "Player", at: Vec3d(0, 2, 8))
        
        let camera = player.addComponent(Camera.self)
        camera.projection = .perspective
        camera.fieldOfView = 60.0
        camera.nearClipPlane = 0.1
        camera.farClipPlane = 100.0
        camera.backgroundColor = Color(r: 30, g: 30, b: 40)
        
        playerController = player.addComponent(PlayerController.self)
        playerController?.moveSpeed = 5.0
        playerController?.enableMouseLook = true
    }
    
    private func setupScene() {
        // Floor
        let floor = createGameObject(name: "Floor", at: Vec3d(0, -1, 0))
        let floorMaterial = Material.matte(Color(r: 50, g: 50, b: 60))
        let floorRenderer = floor.addComponent(MeshRenderer.self)
        floorRenderer.mesh = PlaneMesh(width: 20, depth: 20)
        floorRenderer.material = floorMaterial
        
        // Initial cubes
        createCube(at: Vec3d(0, 0, 0), color: .cornflowerBlue, axis: .up, speed: 1.5)
        createCube(at: Vec3d(3, 0, -2), color: .red, axis: .right, speed: 2.0)
        createCube(at: Vec3d(-3, 0, -2), color: .green, axis: .forward, speed: 1.0)
    }
    
    @discardableResult
    private func createCube(at position: Vec3d, color: Color, axis: Vec3d, speed: Float) -> GameObject {
        let cube = createGameObject(name: "Cube_\(cubeCount)", at: position)
        
        let material = Material.solid(color)
        material.shadingModel = .flat
        
        let renderer = cube.addComponent(MeshRenderer.self)
        renderer.mesh = CubeMesh.shared
        renderer.material = material
        
        let rotator = cube.addComponent(Rotator.self)
        rotator.axis = axis
        rotator.speed = speed
        
        return cube
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        setupHUD()
        setupHelpOverlay()
        setupPauseOverlay()
    }
    
    private func setupHUD() {
        let theme = ThemeManager.shared.current
        
        // Create text references
        let fps = Text("FPS: --")
            .foregroundColor(.green)
        self.fpsText = fps
        
        let pos = Text("Position: (0, 0, 0)")
            .foregroundColor(theme.textSecondary)
        self.positionText = pos
        
        let rot = Text("Looking: (0°, 0°)")
            .foregroundColor(theme.textSecondary)
        self.rotationText = rot
        
        let cubes = Text("Cubes: 3")
            .foregroundColor(theme.textSecondary)
        self.cubeCountText = cubes
        
        // Create HUD overlay
        let hud = createGameObject(name: "HUD")
        hudOverlay = hud.addComponent(UIOverlay.self)
        hudOverlay.depth = 0
        hudOverlay.padding = EdgeInsets(15)
        
        hudOverlay.setContent {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        fps
                        pos
                        rot
                        cubes
                    }
                    
                    Spacer()
                    
                    Text("Press H for help")
                        .foregroundColor(Color(r: 150, g: 150, b: 150))
                }
                
                Spacer()
            }
        }
    }
    
    private func setupHelpOverlay() {
        let theme = ThemeManager.shared.current
        
        let help = createGameObject(name: "Help")
        helpOverlay = help.addComponent(UIOverlay.self)
        helpOverlay
            .depth(50)
            .anchor(.bottomLeft)
            .padding(15)
        
        helpOverlay.setContent {
            VStack(alignment: .leading, spacing: 6) {
                Text("Controls:")
                    .foregroundColor(theme.primary)
                
                Text("WASD - Move")
                    .foregroundColor(theme.textSecondary)
                Text("Mouse - Look around")
                    .foregroundColor(theme.textSecondary)
                Text("Q/E - Down/Up")
                    .foregroundColor(theme.textSecondary)
                Text("Space - Add cube")
                    .foregroundColor(theme.textSecondary)
                Text("P - Pause")
                    .foregroundColor(theme.textSecondary)
                Text("H - Toggle help")
                    .foregroundColor(theme.textSecondary)
            }
            .padding(12)
            .background(Color(r: 0, g: 0, b: 0, a: 180))
        }
    }
    
    private func setupPauseOverlay() {
        let theme = ThemeManager.shared.current
        
        let pause = createGameObject(name: "PauseMenu")
        pauseOverlay = pause.addComponent(UIOverlay.self)
        pauseOverlay
            .depth(100)
            .anchor(.center)
            .blocksInput(true)
            .backgroundColor(Color(r: 0, g: 0, b: 0, a: 180))
        pauseOverlay.isVisible = false
        
        pauseOverlay.setContent {
            VStack(spacing: 20) {
                Text("PAUSED")
                    .foregroundColor(.white)
                    .fontSize(2)
                
                Divider()
                    .color(theme.divider)
                
                Text("Press P to resume")
                    .foregroundColor(theme.textSecondary)
                
                Divider()
                    .color(theme.divider)
                
                HStack(spacing: 15) {
                    ThemedButton("Resume", style: .primary) {
                        self.togglePause()
                    }
                    
                    ThemedButton("Reset View", style: .secondary) {
                        self.resetPlayer()
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Actions
    
    private func togglePause() {
        isPaused.toggle()
        pauseOverlay.isVisible = isPaused
        playerController?.isEnabled = !isPaused
    }
    
    private func toggleHelp() {
        showHelp.toggle()
        helpOverlay.isVisible = showHelp
    }
    
    private func resetPlayer() {
        if let player = find(name: "Player") {
            player.transform.position = Vec3d(0, 2, 8)
            player.transform.rotation = Quaternion.identity
        }
    }
    
    private func spawnRandomCube() {
        let x = Float.random(in: -8...8)
        let z = Float.random(in: -8...4)
        let colors: [Color] = [.red, .green, .cornflowerBlue, .yellow, .magenta, .cyan, .orange]
        let color = colors.randomElement() ?? .white
        let axes: [Vec3d] = [.up, .right, .forward, Vec3d(1, 1, 0).normalized, Vec3d(1, 0, 1).normalized]
        let axis = axes.randomElement() ?? .up
        let speed = Float.random(in: 0.5...3.0)
        
        cubeCount += 1
        createCube(at: Vec3d(x, 0, z), color: color, axis: axis, speed: speed)
        cubeCountText?.content = "Cubes: \(cubeCount)"
    }
    
    // MARK: - Update
    
    // Store screen size from render for use in update
    private var lastScreenWidth: Float = 800
    private var lastScreenHeight: Float = 600
    
    public override func update(context: FrameContext, input: Input) {
        // Handle UI input first
        _ = handleUIOverlayInput(input, screenWidth: lastScreenWidth, screenHeight: lastScreenHeight)
        
        // Handle keyboard shortcuts
        if input.isKeyPressed(.p) {
            togglePause()
        }
        
        if input.isKeyPressed(.h) {
            toggleHelp()
        }
        
        if !isPaused {
            // Spawn cube with space
            if input.isKeyPressed(.space) {
                spawnRandomCube()
            }
            
            // Provide input to player controller
            playerController?.setInput(input)
            
            // Update frame counter
            updateFPS(deltaTime: Float(context.deltaTime))
            
            // Update position display
            updatePositionDisplay()
        }
        
        super.update(context: context, input: input)
    }
    
    private func updateFPS(deltaTime: Float) {
        frameTimeAccumulator += deltaTime
        frameCount += 1
        
        if frameTimeAccumulator >= 0.5 {
            currentFPS = Int(Float(frameCount) / frameTimeAccumulator)
            frameCount = 0
            frameTimeAccumulator = 0
            
            let color: Color = currentFPS >= 60 ? .green : (currentFPS >= 30 ? .yellow : .red)
            fpsText?.content = "FPS: \(currentFPS)"
            fpsText?.color = color
        }
    }
    
    private func updatePositionDisplay() {
        guard let player = find(name: "Player") else { return }
        
        let pos = player.transform.position
        positionText?.content = String(format: "Position: (%.1f, %.1f, %.1f)", pos.x, pos.y, pos.z)
        
        let euler = player.transform.rotation.eulerAngles
        let yaw = euler.yaw * 180 / .pi
        let pitch = euler.pitch * 180 / .pi
        rotationText?.content = String(format: "Looking: (%.0f°, %.0f°)", yaw, pitch)
    }
    
    // MARK: - Render
    
    public override func render(context: RenderContext) {
        // Store screen size for update method
        lastScreenWidth = Float(context.width)
        lastScreenHeight = Float(context.height)
        
        // Clear with camera background
        let bgColor = Camera.main?.backgroundColor ?? Color(r: 30, g: 30, b: 40)
        context.renderer.clear(bgColor)
        
        // Render 3D scene
        guard let camera = Camera.main else { return }
        
        let meshRenderers = findComponentsOfType(MeshRenderer.self)
        RenderPipeline.shared.render(
            meshRenderers: meshRenderers,
            camera: camera,
            context: context
        )
        
        // Render UI overlays on top
        renderUIOverlays(context: context)
    }
}
