import Foundation

/// Component for controlling player movement with keyboard input
@MainActor
public final class PlayerController: Component {
    
    /// Movement speed in units per second
    public var moveSpeed: Float = 3.0
    
    /// Look/rotation speed (mouse sensitivity)
    public var lookSpeed: Float = 0.002
    
    /// Key bindings for movement
    public var forwardKey: Key = .w
    public var backwardKey: Key = .s
    public var leftKey: Key = .a
    public var rightKey: Key = .d
    public var upKey: Key = .e
    public var downKey: Key = .q
    
    /// Alternative key bindings (arrows)
    public var useArrowKeys: Bool = true
    
    /// Whether to enable mouse look (rotation)
    public var enableMouseLook: Bool = false
    
    /// Pitch constraints (in radians)
    public var minPitch: Float = -.pi / 2 + 0.01
    public var maxPitch: Float = .pi / 2 - 0.01
    
    /// Current rotation angles
    private var yaw: Float = 0
    private var pitch: Float = 0
    
    /// Current input reference (set during update)
    private var currentInput: Input?
    
    public required init() {
        super.init()
    }
    
    public convenience init(moveSpeed: Float) {
        self.init()
        self.moveSpeed = moveSpeed
    }
    
    public override func update(deltaTime: Float) {
        guard let input = currentInput else { return }
        
        // Handle mouse look when enabled and mouse is captured
        if enableMouseLook && input.isMouseCaptured {
            let (deltaX, deltaY) = input.getMouseDelta()
            
            // Update yaw (horizontal rotation around Y) and pitch (vertical rotation around X)
            yaw -= Float(deltaX) * lookSpeed
            pitch -= Float(deltaY) * lookSpeed
            
            // Clamp pitch to prevent flipping
            pitch = max(minPitch, min(maxPitch, pitch))
            
            // Apply rotation: first yaw (around Y), then pitch (around X)
            // This gives proper FPS-style camera behavior
            let yawRotation = Quaternion.fromAxisAngle(axis: .unitY, angle: yaw)
            let pitchRotation = Quaternion.fromAxisAngle(axis: .unitX, angle: pitch)
            transform.localRotation = yawRotation * pitchRotation
        }
        
        var movement = Vec3d.zero
        
        // Forward/Backward
        if input.isKeyDown(forwardKey) || (useArrowKeys && input.isKeyDown(.up)) {
            movement.z -= 1
        }
        if input.isKeyDown(backwardKey) || (useArrowKeys && input.isKeyDown(.down)) {
            movement.z += 1
        }
        
        // Left/Right strafe
        if input.isKeyDown(leftKey) || (useArrowKeys && input.isKeyDown(.left)) {
            movement.x -= 1
        }
        if input.isKeyDown(rightKey) || (useArrowKeys && input.isKeyDown(.right)) {
            movement.x += 1
        }
        
        // Up/Down (vertical movement, not affected by look direction)
        var verticalMovement: Float = 0
        if input.isKeyDown(upKey) {
            verticalMovement += 1
        }
        if input.isKeyDown(downKey) {
            verticalMovement -= 1
        }
        
        // Normalize horizontal movement to prevent faster diagonal speed
        if movement.squaredLength > 0 {
            movement = movement.normalized * moveSpeed * deltaTime
            
            // Transform horizontal movement by yaw only (not pitch)
            // This keeps movement on the ground plane regardless of look angle
            let yawRotation = Quaternion.fromAxisAngle(axis: .unitY, angle: yaw)
            let rotatedMovement = yawRotation * movement
            transform.localPosition = transform.localPosition + rotatedMovement
        }
        
        // Apply vertical movement separately (world-space Y axis)
        if verticalMovement != 0 {
            transform.localPosition.y += verticalMovement * moveSpeed * deltaTime
        }
    }
    
    /// Called by the scene to provide input for this frame
    public func setInput(_ input: Input) {
        self.currentInput = input
    }
}
