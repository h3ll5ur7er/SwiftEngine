import Foundation

/// Debug drawing utilities for visualizing physics, colliders, and other debug information
@MainActor
public final class DebugDraw {
    
    /// Shared instance
    public static let shared = DebugDraw()
    
    /// Whether debug drawing is enabled
    public var isEnabled: Bool = true
    
    /// Whether to draw collider wireframes
    public var showColliders: Bool = true
    
    /// Whether to also show each box collider's AABB (axis-aligned bounding box)
    public var showAABB: Bool = true
    
    /// Color for box collider wireframes (the actual rotated shape)
    public var boxColliderColor: Color = Color(r: 0, g: 255, b: 0)
    
    /// Color for AABB wireframes
    public var aabbColor: Color = Color(r: 255, g: 255, b: 0)
    
    /// Color for sphere collider wireframes
    public var sphereColliderColor: Color = Color(r: 0, g: 200, b: 255)
    
    /// Color for plane collider wireframes
    public var planeColliderColor: Color = Color(r: 200, g: 100, b: 255)
    
    /// Color for collision contacts
    public var contactColor: Color = Color(r: 255, g: 0, b: 0)
    
    private init() {}
    
    /// Draw all debug visualizations
    public func draw(context: RenderContext, camera: Camera) {
        guard isEnabled else { return }
        
        if showColliders {
            drawColliders(context: context, camera: camera)
        }
    }
    
    /// Draw all registered colliders
    private func drawColliders(context: RenderContext, camera: Camera) {
        let colliders = CollisionManager.shared.allColliders
        
        for collider in colliders {
            guard collider.isEnabled else { continue }
            guard collider.gameObject?.isActive == true else { continue }
            
            if let box = collider as? BoxCollider {
                drawBoxCollider(box, context: context, camera: camera)
            } else if let sphere = collider as? SphereCollider {
                drawSphereCollider(sphere, context: context, camera: camera)
            } else if let plane = collider as? PlaneCollider {
                drawPlaneCollider(plane, context: context, camera: camera)
            }
        }
    }
    
    /// Draw a box collider wireframe (rotated OBB + AABB)
    private func drawBoxCollider(_ collider: BoxCollider, context: RenderContext, camera: Camera) {
        // Draw the actual rotated box (OBB) in green
        let corners = collider.worldCorners
        
        // 12 edges of the box
        let edges: [(Int, Int)] = [
            // Front face
            (0, 1), (1, 2), (2, 3), (3, 0),
            // Back face
            (4, 5), (5, 6), (6, 7), (7, 4),
            // Connecting edges
            (0, 4), (1, 5), (2, 6), (3, 7)
        ]
        
        for (i, j) in edges {
            draw3DLine(from: corners[i], to: corners[j], color: boxColliderColor, context: context, camera: camera)
        }
        
        // Optionally draw the AABB in a different color to show the difference
        if showAABB {
            let min = collider.worldMin
            let max = collider.worldMax
            
            let aabbCorners: [Vec3d] = [
                Vec3d(min.x, min.y, min.z),
                Vec3d(max.x, min.y, min.z),
                Vec3d(max.x, max.y, min.z),
                Vec3d(min.x, max.y, min.z),
                Vec3d(min.x, min.y, max.z),
                Vec3d(max.x, min.y, max.z),
                Vec3d(max.x, max.y, max.z),
                Vec3d(min.x, max.y, max.z),
            ]
            
            for (i, j) in edges {
                draw3DLine(from: aabbCorners[i], to: aabbCorners[j], color: aabbColor, context: context, camera: camera)
            }
        }
    }
    
    /// Draw a sphere collider wireframe (as circles)
    private func drawSphereCollider(_ collider: SphereCollider, context: RenderContext, camera: Camera) {
        let center = collider.worldCenter
        let radius = collider.radius
        let segments = 16
        
        // Draw 3 circles (XY, XZ, YZ planes)
        drawCircle(center: center, radius: radius, axis: Vec3d(0, 0, 1), segments: segments, color: sphereColliderColor, context: context, camera: camera)
        drawCircle(center: center, radius: radius, axis: Vec3d(0, 1, 0), segments: segments, color: sphereColliderColor, context: context, camera: camera)
        drawCircle(center: center, radius: radius, axis: Vec3d(1, 0, 0), segments: segments, color: sphereColliderColor, context: context, camera: camera)
    }
    
    /// Draw a plane collider (as a bounded grid with normal indicator)
    private func drawPlaneCollider(_ collider: PlaneCollider, context: RenderContext, camera: Camera) {
        let center = collider.worldPlanePoint
        let normal = collider.worldNormal
        
        // Create orthonormal basis for the plane
        let right: Vec3d
        let forward: Vec3d
        
        // Find a vector not parallel to the normal to create the basis
        if abs(normal.y) < 0.9 {
            right = Vec3d(normal.z, 0, -normal.x).normalized
        } else {
            right = Vec3d(1, 0, 0)
        }
        forward = Vec3d(
            normal.y * right.z - normal.z * right.y,
            normal.z * right.x - normal.x * right.z,
            normal.x * right.y - normal.y * right.x
        )
        
        // Draw a grid on the plane (limited size for visualization)
        let gridSize: Float = 10.0
        let gridStep: Float = 2.0
        
        // Draw grid lines along "right" direction
        let numLines = Int(gridSize / gridStep)
        for i in -numLines...numLines {
            let offset = Float(i) * gridStep
            let start = Vec3d(
                center.x + forward.x * offset - right.x * gridSize,
                center.y + forward.y * offset - right.y * gridSize,
                center.z + forward.z * offset - right.z * gridSize
            )
            let end = Vec3d(
                center.x + forward.x * offset + right.x * gridSize,
                center.y + forward.y * offset + right.y * gridSize,
                center.z + forward.z * offset + right.z * gridSize
            )
            draw3DLine(from: start, to: end, color: planeColliderColor, context: context, camera: camera)
        }
        
        // Draw grid lines along "forward" direction
        for i in -numLines...numLines {
            let offset = Float(i) * gridStep
            let start = Vec3d(
                center.x + right.x * offset - forward.x * gridSize,
                center.y + right.y * offset - forward.y * gridSize,
                center.z + right.z * offset - forward.z * gridSize
            )
            let end = Vec3d(
                center.x + right.x * offset + forward.x * gridSize,
                center.y + right.y * offset + forward.y * gridSize,
                center.z + right.z * offset + forward.z * gridSize
            )
            draw3DLine(from: start, to: end, color: planeColliderColor, context: context, camera: camera)
        }
        
        // Draw normal arrow
        let normalEnd = Vec3d(
            center.x + normal.x * 2.0,
            center.y + normal.y * 2.0,
            center.z + normal.z * 2.0
        )
        draw3DLine(from: center, to: normalEnd, color: Color(r: 255, g: 100, b: 100), context: context, camera: camera)
    }
    
    /// Draw a circle in 3D space
    private func drawCircle(center: Vec3d, radius: Float, axis: Vec3d, segments: Int, color: Color, context: RenderContext, camera: Camera) {
        var prevPoint: Vec3d?
        
        for i in 0...segments {
            let angle = Float(i) / Float(segments) * Float.pi * 2
            let cos_a = cos(angle) * radius
            let sin_a = sin(angle) * radius
            
            let point: Vec3d
            if axis.y > 0.5 {
                // XZ plane
                point = Vec3d(center.x + cos_a, center.y, center.z + sin_a)
            } else if axis.x > 0.5 {
                // YZ plane
                point = Vec3d(center.x, center.y + cos_a, center.z + sin_a)
            } else {
                // XY plane
                point = Vec3d(center.x + cos_a, center.y + sin_a, center.z)
            }
            
            if let prev = prevPoint {
                draw3DLine(from: prev, to: point, color: color, context: context, camera: camera)
            }
            prevPoint = point
        }
    }
    
    /// Draw a 3D line projected to screen space with proper near-plane clipping
    public func draw3DLine(from: Vec3d, to: Vec3d, color: Color, context: RenderContext, camera: Camera) {
        let screenWidth = Float(context.width)
        let screenHeight = Float(context.height)
        
        // Transform to homogeneous clip space (keeping w component for proper clipping)
        let mvp = camera.viewProjectionMatrix
        
        var clip0 = Vec4d(
            mvp.m00 * from.x + mvp.m01 * from.y + mvp.m02 * from.z + mvp.m03,
            mvp.m10 * from.x + mvp.m11 * from.y + mvp.m12 * from.z + mvp.m13,
            mvp.m20 * from.x + mvp.m21 * from.y + mvp.m22 * from.z + mvp.m23,
            mvp.m30 * from.x + mvp.m31 * from.y + mvp.m32 * from.z + mvp.m33
        )
        var clip1 = Vec4d(
            mvp.m00 * to.x + mvp.m01 * to.y + mvp.m02 * to.z + mvp.m03,
            mvp.m10 * to.x + mvp.m11 * to.y + mvp.m12 * to.z + mvp.m13,
            mvp.m20 * to.x + mvp.m21 * to.y + mvp.m22 * to.z + mvp.m23,
            mvp.m30 * to.x + mvp.m31 * to.y + mvp.m32 * to.z + mvp.m33
        )
        
        // Near plane clipping in homogeneous coordinates
        // A point is behind the near plane if w <= 0 (or z < -w for the standard frustum)
        // For simplicity, we clip against w = nearW (small positive value)
        let nearW: Float = 0.001
        
        let behind0 = clip0.w < nearW
        let behind1 = clip1.w < nearW
        
        // Skip if both points are behind camera
        if behind0 && behind1 { return }
        
        // Clip line against near plane (w = nearW)
        if behind0 {
            let t = (nearW - clip1.w) / (clip0.w - clip1.w)
            clip0 = Vec4d(
                clip1.x + t * (clip0.x - clip1.x),
                clip1.y + t * (clip0.y - clip1.y),
                clip1.z + t * (clip0.z - clip1.z),
                nearW
            )
        } else if behind1 {
            let t = (nearW - clip0.w) / (clip1.w - clip0.w)
            clip1 = Vec4d(
                clip0.x + t * (clip1.x - clip0.x),
                clip0.y + t * (clip1.y - clip0.y),
                clip0.z + t * (clip1.z - clip0.z),
                nearW
            )
        }
        
        // Perspective divide to get NDC coordinates
        let ndc0x = clip0.x / clip0.w
        let ndc0y = clip0.y / clip0.w
        let ndc1x = clip1.x / clip1.w
        let ndc1y = clip1.y / clip1.w
        
        // Check for NaN or Inf values
        guard ndc0x.isFinite && ndc0y.isFinite &&
              ndc1x.isFinite && ndc1y.isFinite else {
            return
        }
        
        // Frustum culling in NDC space - check each axis separately
        // Skip if both endpoints are outside the same side of the view
        if ndc0x > 1.0 && ndc1x > 1.0 { return }  // Both to the right
        if ndc0x < -1.0 && ndc1x < -1.0 { return } // Both to the left
        if ndc0y > 1.0 && ndc1y > 1.0 { return }  // Both above
        if ndc0y < -1.0 && ndc1y < -1.0 { return } // Both below
        
        // Convert NDC (-1 to 1) to screen coordinates
        let fromX = (ndc0x * 0.5 + 0.5) * screenWidth
        let fromY = (1.0 - (ndc0y * 0.5 + 0.5)) * screenHeight
        let toX = (ndc1x * 0.5 + 0.5) * screenWidth
        let toY = (1.0 - (ndc1y * 0.5 + 0.5)) * screenHeight
        
        // Clamp to prevent Int32 overflow
        let maxCoord: Float = 100000.0
        let x0 = Int32(max(-maxCoord, min(maxCoord, fromX)))
        let y0 = Int32(max(-maxCoord, min(maxCoord, fromY)))
        let x1 = Int32(max(-maxCoord, min(maxCoord, toX)))
        let y1 = Int32(max(-maxCoord, min(maxCoord, toY)))
        
        // Basic clipping - skip if completely outside screen
        let sw = Int32(screenWidth)
        let sh = Int32(screenHeight)
        if (x0 < 0 && x1 < 0) || (x0 > sw && x1 > sw) { return }
        if (y0 < 0 && y1 < 0) || (y0 > sh && y1 > sh) { return }
        
        Primitives.drawLine(x0: x0, y0: y0, x1: x1, y1: y1, color: color)
    }
    
    /// Draw a point in 3D space (as a small cross)
    public func draw3DPoint(_ point: Vec3d, color: Color, size: Float = 0.1, context: RenderContext, camera: Camera) {
        draw3DLine(from: Vec3d(point.x - size, point.y, point.z), to: Vec3d(point.x + size, point.y, point.z), color: color, context: context, camera: camera)
        draw3DLine(from: Vec3d(point.x, point.y - size, point.z), to: Vec3d(point.x, point.y + size, point.z), color: color, context: context, camera: camera)
        draw3DLine(from: Vec3d(point.x, point.y, point.z - size), to: Vec3d(point.x, point.y, point.z + size), color: color, context: context, camera: camera)
    }
}
