import Foundation

/// Represents the position, rotation, and scale of a GameObject in 3D space
public final class Transform: @unchecked Sendable {
    /// Local position relative to parent (or world position if no parent)
    public var localPosition: Vec3d {
        didSet { invalidateCache() }
    }
    
    /// Local rotation relative to parent (or world rotation if no parent)
    public var localRotation: Quaternion {
        didSet { invalidateCache() }
    }
    
    /// Local scale relative to parent
    public var localScale: Vec3d {
        didSet { invalidateCache() }
    }
    
    /// Parent transform (nil if root)
    public weak var parent: Transform? {
        didSet { invalidateCache() }
    }
    
    /// Child transforms
    public private(set) var children: [Transform] = []
    
    /// The GameObject that owns this transform (nil for standalone transforms)
    public internal(set) weak var gameObject: GameObject?
    
    // Cached matrices for performance
    private var _localMatrix: Mat4d?
    private var _worldMatrix: Mat4d?
    private var _worldMatrixInverse: Mat4d?
    
    public init(
        position: Vec3d = .zero,
        rotation: Quaternion = .identity,
        scale: Vec3d = .one
    ) {
        self.localPosition = position
        self.localRotation = rotation
        self.localScale = scale
    }
    
    // MARK: - World Space Properties
    
    /// World position (accounting for parent hierarchy)
    public var position: Vec3d {
        get {
            if let parent = parent {
                return parent.worldMatrix.transformPoint(localPosition)
            }
            return localPosition
        }
        set {
            if let parent = parent {
                if let inverse = parent.worldMatrix.inverse {
                    localPosition = inverse.transformPoint(newValue)
                }
            } else {
                localPosition = newValue
            }
        }
    }
    
    /// World rotation (accounting for parent hierarchy)
    public var rotation: Quaternion {
        get {
            if let parent = parent {
                return parent.rotation * localRotation
            }
            return localRotation
        }
        set {
            if let parent = parent {
                localRotation = parent.rotation.inverse * newValue
            } else {
                localRotation = newValue
            }
        }
    }
    
    /// Lossy world scale (may not be accurate with rotated parents)
    public var lossyScale: Vec3d {
        if let parent = parent {
            let ps = parent.lossyScale
            return Vec3d(
                localScale.x * ps.x,
                localScale.y * ps.y,
                localScale.z * ps.z
            )
        }
        return localScale
    }
    
    // MARK: - Matrices
    
    /// Local transformation matrix (relative to parent)
    public var localMatrix: Mat4d {
        if let cached = _localMatrix {
            return cached
        }
        
        let t = Mat4d.translate(vec: localPosition)
        let r = localRotation.toMat4d
        let s = Mat4d.scale(sx: localScale.x, sy: localScale.y, sz: localScale.z)
        
        let matrix = t * r * s
        _localMatrix = matrix
        return matrix
    }
    
    /// World transformation matrix (accounting for parent hierarchy)
    public var worldMatrix: Mat4d {
        if let cached = _worldMatrix {
            return cached
        }
        
        let matrix: Mat4d
        if let parent = parent {
            matrix = parent.worldMatrix * localMatrix
        } else {
            matrix = localMatrix
        }
        
        _worldMatrix = matrix
        return matrix
    }
    
    /// Inverse of world transformation matrix
    public var worldMatrixInverse: Mat4d? {
        if let cached = _worldMatrixInverse {
            return cached
        }
        
        let inverse = worldMatrix.inverse
        _worldMatrixInverse = inverse
        return inverse
    }
    
    // MARK: - Direction Vectors
    
    /// Forward direction in world space (negative Z in local space)
    public var forward: Vec3d {
        rotation * Vec3d(0, 0, -1)
    }
    
    /// Right direction in world space (positive X in local space)
    public var right: Vec3d {
        rotation * Vec3d(1, 0, 0)
    }
    
    /// Up direction in world space (positive Y in local space)
    public var up: Vec3d {
        rotation * Vec3d(0, 1, 0)
    }
    
    // MARK: - Hierarchy Management
    
    /// Add a child transform
    public func addChild(_ child: Transform) {
        guard child.parent !== self else { return }
        
        // Remove from previous parent
        child.parent?.removeChild(child)
        
        child.parent = self
        children.append(child)
    }
    
    /// Remove a child transform
    public func removeChild(_ child: Transform) {
        guard let index = children.firstIndex(where: { $0 === child }) else { return }
        children.remove(at: index)
        child.parent = nil
    }
    
    /// Remove from parent
    public func removeFromParent() {
        parent?.removeChild(self)
    }
    
    // MARK: - Transformations
    
    /// Translate by offset in local space
    public func translate(_ offset: Vec3d, relativeTo space: Space = .local) {
        switch space {
        case .local:
            localPosition = localPosition + (localRotation * offset)
        case .world:
            position = position + offset
        }
    }
    
    /// Rotate by quaternion
    public func rotate(_ rotation: Quaternion, relativeTo space: Space = .local) {
        switch space {
        case .local:
            localRotation = localRotation * rotation
        case .world:
            self.rotation = rotation * self.rotation
        }
    }
    
    /// Rotate around axis by angle (in radians)
    public func rotate(axis: Vec3d, angle: Float32, relativeTo space: Space = .local) {
        let rotation = Quaternion.fromAxisAngle(axis: axis, angle: angle)
        self.rotate(rotation, relativeTo: space)
    }
    
    /// Look at a target position
    public func lookAt(_ target: Vec3d, worldUp: Vec3d = .unitY) {
        let forward = (target - position).normalized
        guard forward.squaredLength > Float32.ulpOfOne else { return }
        
        rotation = Quaternion.lookRotation(forward: forward, up: worldUp)
    }
    
    /// Transform a point from local to world space
    public func transformPoint(_ point: Vec3d) -> Vec3d {
        worldMatrix.transformPoint(point)
    }
    
    /// Transform a direction from local to world space
    public func transformDirection(_ direction: Vec3d) -> Vec3d {
        worldMatrix.transformDirection(direction)
    }
    
    /// Transform a point from world to local space
    public func inverseTransformPoint(_ point: Vec3d) -> Vec3d {
        worldMatrixInverse?.transformPoint(point) ?? point
    }
    
    /// Transform a direction from world to local space
    public func inverseTransformDirection(_ direction: Vec3d) -> Vec3d {
        worldMatrixInverse?.transformDirection(direction) ?? direction
    }
    
    // MARK: - Cache Management
    
    private func invalidateCache() {
        _localMatrix = nil
        _worldMatrix = nil
        _worldMatrixInverse = nil
        
        // Invalidate children's world matrices
        for child in children {
            child.invalidateWorldCache()
        }
    }
    
    private func invalidateWorldCache() {
        _worldMatrix = nil
        _worldMatrixInverse = nil
        
        for child in children {
            child.invalidateWorldCache()
        }
    }
}

/// Reference frame for transformations
public enum Space {
    case local
    case world
}

// MARK: - CustomStringConvertible

extension Transform: CustomStringConvertible {
    public var description: String {
        "Transform(pos: \(localPosition), rot: \(localRotation), scale: \(localScale))"
    }
}
