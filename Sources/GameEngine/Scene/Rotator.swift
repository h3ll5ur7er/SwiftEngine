import Foundation

/// A component that continuously rotates a GameObject around an axis
@MainActor
public final class Rotator: Component {
    
    /// Rotation axis (will be normalized)
    public var axis: Vec3d = .up {
        didSet { axis = axis.normalized }
    }
    
    /// Rotation speed in radians per second
    public var speed: Float = 1.0
    
    /// Whether to rotate in local or world space
    public var useLocalSpace: Bool = true
    
    public required init() {
        super.init()
    }
    
    /// Convenience initializer
    public convenience init(axis: Vec3d, speed: Float, useLocalSpace: Bool = true) {
        self.init()
        self.axis = axis.normalized
        self.speed = speed
        self.useLocalSpace = useLocalSpace
    }
    
    public override func update(deltaTime: Float) {
        super.update(deltaTime: deltaTime)
        
        let angle = speed * deltaTime
        let rotation = Quaternion.fromAxisAngle(axis: axis, angle: angle)
        
        if useLocalSpace {
            // Rotate in local space (rotation happens around object's own axis)
            transform.localRotation = rotation * transform.localRotation
        } else {
            // Rotate in world space (rotation happens around world axis)
            transform.localRotation = transform.localRotation * rotation
        }
    }
}
