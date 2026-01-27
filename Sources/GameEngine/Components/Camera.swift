import Foundation

/// Projection type for the camera
public enum CameraProjection: Sendable {
    case perspective
    case orthographic
}

/// Camera component for viewing the scene
@MainActor
public final class Camera: Component {
    // MARK: - Static Main Camera
    
    /// The main camera used for rendering
    /// Set automatically when a Camera component is created if no main camera exists
    public private(set) static weak var main: Camera?
    
    /// Manually set this camera as the main camera
    public func setAsMain() {
        Camera.main = self
    }
    
    // MARK: - Projection Settings
    
    /// The projection type (perspective or orthographic)
    public var projection: CameraProjection = .perspective {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Field of view in degrees (perspective only)
    public var fieldOfView: Float = 60.0 {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Orthographic size - half the vertical size of the viewing volume (orthographic only)
    public var orthographicSize: Float = 5.0 {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Near clipping plane distance
    public var nearClipPlane: Float = 0.1 {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Far clipping plane distance
    public var farClipPlane: Float = 1000.0 {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Aspect ratio (width / height) - usually set automatically from viewport
    public var aspectRatio: Float = 16.0 / 9.0 {
        didSet { invalidateProjectionMatrix() }
    }
    
    /// Viewport rect (normalized 0-1 coordinates)
    public var viewportRect: Rect = Rect(x: 0, y: 0, width: 1, height: 1)
    
    /// Background color for this camera
    public var backgroundColor: Color = .black
    
    /// Render order (lower values render first)
    public var depth: Int = 0
    
    // MARK: - Cached Matrices
    
    private var _projectionMatrix: Mat4d?
    private var _viewMatrix: Mat4d?
    private var _viewProjectionMatrix: Mat4d?
    private var _frustum: Frustum?
    
    // MARK: - Initialization
    
    public required init() {
        super.init()
    }
    
    public convenience init(projection: CameraProjection, fov: Float = 60.0) {
        self.init()
        self.projection = projection
        self.fieldOfView = fov
    }
    
    // MARK: - Lifecycle
    
    public override func awake() {
        // Set as main camera if none exists
        if Camera.main == nil {
            Camera.main = self
        }
    }
    
    public override func onDestroy() {
        // Clear main camera reference if this was the main camera
        if Camera.main === self {
            Camera.main = nil
        }
    }
    
    // MARK: - Matrices
    
    /// The projection matrix based on camera settings
    public var projectionMatrix: Mat4d {
        if let cached = _projectionMatrix {
            return cached
        }
        
        let matrix: Mat4d
        switch projection {
        case .perspective:
            matrix = Mat4d.perspective(
                fovY: fieldOfView * (.pi / 180.0),  // Convert to radians
                aspect: aspectRatio,
                near: nearClipPlane,
                far: farClipPlane
            )
        case .orthographic:
            let halfHeight = orthographicSize
            let halfWidth = halfHeight * aspectRatio
            matrix = Mat4d.orthographic(
                left: -halfWidth,
                right: halfWidth,
                bottom: -halfHeight,
                top: halfHeight,
                near: nearClipPlane,
                far: farClipPlane
            )
        }
        
        _projectionMatrix = matrix
        return matrix
    }
    
    /// The view matrix (inverse of camera's world transform)
    public var viewMatrix: Mat4d {
        if let cached = _viewMatrix {
            return cached
        }
        
        // Use lookAt for view matrix construction
        let position = transform.position
        let forward = transform.forward
        let up = transform.up
        let target = position + forward
        
        let matrix = Mat4d.lookAt(eye: position, target: target, up: up)
        _viewMatrix = matrix
        return matrix
    }
    
    /// Combined view-projection matrix
    public var viewProjectionMatrix: Mat4d {
        if let cached = _viewProjectionMatrix {
            return cached
        }
        
        let matrix = projectionMatrix * viewMatrix
        _viewProjectionMatrix = matrix
        return matrix
    }
    
    /// The view frustum for culling
    public var frustum: Frustum {
        if let cached = _frustum {
            return cached
        }
        
        let f = Frustum.fromViewProjection(viewProjectionMatrix)
        _frustum = f
        return f
    }
    
    /// Invalidate cached projection matrix
    private func invalidateProjectionMatrix() {
        _projectionMatrix = nil
        _viewProjectionMatrix = nil
        _frustum = nil
    }
    
    /// Invalidate cached view matrix (called when transform changes)
    public func invalidateViewMatrix() {
        _viewMatrix = nil
        _viewProjectionMatrix = nil
        _frustum = nil
    }
    
    public override func lateUpdate(deltaTime: Float) {
        // Invalidate view matrix since transform may have changed
        invalidateViewMatrix()
    }
    
    // MARK: - Screen/World Conversion
    
    /// Convert a world position to screen coordinates
    /// Returns normalized coordinates (0-1) where (0,0) is bottom-left
    public func worldToScreenPoint(_ worldPos: Vec3d) -> Vec3d {
        let clipPos = viewProjectionMatrix.transformPoint(worldPos)
        
        // Perspective divide and convert to 0-1 range
        let screenX = (clipPos.x + 1.0) / 2.0
        let screenY = (clipPos.y + 1.0) / 2.0
        let depth = (clipPos.z + 1.0) / 2.0
        
        return Vec3d(screenX, screenY, depth)
    }
    
    /// Convert screen coordinates to a world ray
    /// screenPos should be normalized (0-1) where (0,0) is bottom-left
    public func screenToWorldRay(_ screenPos: Vec2d) -> (origin: Vec3d, direction: Vec3d) {
        // Convert to clip space (-1 to 1)
        let clipX = screenPos.x * 2.0 - 1.0
        let clipY = screenPos.y * 2.0 - 1.0
        
        // Near and far points in clip space
        let nearPoint = Vec3d(clipX, clipY, -1.0)
        let farPoint = Vec3d(clipX, clipY, 1.0)
        
        // Transform to world space
        guard let inverseVP = viewProjectionMatrix.inverse else {
            return (transform.position, transform.forward)
        }
        
        let worldNear = inverseVP.transformPoint(nearPoint)
        let worldFar = inverseVP.transformPoint(farPoint)
        
        let direction = (worldFar - worldNear).normalized
        
        return (worldNear, direction)
    }
    
    /// Convert a world position to viewport coordinates (in pixels)
    public func worldToViewportPoint(_ worldPos: Vec3d, viewportWidth: Int, viewportHeight: Int) -> Vec3d {
        let screenPoint = worldToScreenPoint(worldPos)
        return Vec3d(
            screenPoint.x * Float(viewportWidth),
            screenPoint.y * Float(viewportHeight),
            screenPoint.z
        )
    }
}
