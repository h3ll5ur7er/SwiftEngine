/// Manages all UIOverlay components in the scene
///
/// The UIOverlayManager is a singleton that tracks all active overlays,
/// sorts them by depth, and handles rendering and input distribution.
///
/// ## Rendering Order
/// Overlays with lower depth values render first (behind higher values).
///
/// ## Input Handling
/// Input is processed from highest to lowest depth. If an overlay with
/// `blocksInput = true` consumes the input, lower overlays don't receive it.
@MainActor
public final class UIOverlayManager {
    
    // MARK: - Singleton
    
    /// Shared overlay manager instance
    public static let shared = UIOverlayManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// All registered overlays
    private var overlays: [UIOverlay] = []
    
    /// Overlays sorted by depth (cached)
    private var sortedOverlays: [UIOverlay] = []
    
    /// Whether the sorted list needs updating
    private var needsSort: Bool = false
    
    // MARK: - Registration
    
    /// Register an overlay with the manager
    internal func register(_ overlay: UIOverlay) {
        guard !overlays.contains(where: { $0 === overlay }) else { return }
        overlays.append(overlay)
        needsSort = true
    }
    
    /// Unregister an overlay from the manager
    internal func unregister(_ overlay: UIOverlay) {
        if let index = overlays.firstIndex(where: { $0 === overlay }) {
            overlays.remove(at: index)
            needsSort = true
        }
    }
    
    // MARK: - Sorting
    
    /// Sort overlays by depth
    private func sortOverlaysIfNeeded() {
        guard needsSort else { return }
        sortedOverlays = overlays.sorted { $0.depth < $1.depth }
        needsSort = false
    }
    
    // MARK: - Rendering
    
    /// Render all overlays (call from scene's render method)
    public func renderOverlays(context: RenderContext) {
        sortOverlaysIfNeeded()
        
        // Render in depth order (lowest first, so highest is on top)
        for overlay in sortedOverlays {
            if overlay.isEnabled && overlay.isVisible {
                overlay.render(context: context)
            }
        }
    }
    
    // MARK: - Input Handling
    
    /// Handle input for all overlays (call from scene's update method)
    /// Returns true if any overlay consumed the input
    @discardableResult
    public func handleInput(_ input: Input, screenWidth: Float, screenHeight: Float) -> Bool {
        sortOverlaysIfNeeded()
        
        // Process input from highest to lowest depth (reverse order)
        for overlay in sortedOverlays.reversed() {
            if overlay.isEnabled && overlay.isVisible {
                if overlay.handleInput(input, screenWidth: screenWidth, screenHeight: screenHeight) {
                    // Input was consumed by this overlay
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Queries
    
    /// Get all registered overlays
    public var allOverlays: [UIOverlay] {
        sortOverlaysIfNeeded()
        return sortedOverlays
    }
    
    /// Get overlay at a specific screen position
    public func overlayAt(x: Float, y: Float) -> UIOverlay? {
        sortOverlaysIfNeeded()
        
        // Check from highest to lowest depth
        for overlay in sortedOverlays.reversed() {
            guard overlay.isEnabled && overlay.isVisible else { continue }
            
            // Would need bounds checking here
            // For now, return the topmost overlay
        }
        
        return nil
    }
    
    /// Clear all overlays (useful when changing scenes)
    public func clear() {
        overlays.removeAll()
        sortedOverlays.removeAll()
        needsSort = false
    }
    
    /// Notify that an overlay's depth changed
    public func notifyDepthChanged() {
        needsSort = true
    }
}

// MARK: - GameObjectScene Extension

extension GameObjectScene {
    
    /// Render all UI overlays in the scene
    /// Call this at the end of your render method, after 3D rendering
    public func renderUIOverlays(context: RenderContext) {
        UIOverlayManager.shared.renderOverlays(context: context)
    }
    
    /// Handle input for UI overlays
    /// Call this at the beginning of your update method
    /// Returns true if a UI overlay consumed the input
    @discardableResult
    public func handleUIOverlayInput(_ input: Input, screenWidth: Float, screenHeight: Float) -> Bool {
        return UIOverlayManager.shared.handleInput(input, screenWidth: screenWidth, screenHeight: screenHeight)
    }
}
