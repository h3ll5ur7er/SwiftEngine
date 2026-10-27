/// A component that renders a UI overlay on screen
/// 
/// UIOverlay allows you to add UI elements to GameObjects that render on top
/// of the 3D scene. Supports screen-space UI (fixed to screen) and can be
/// ordered by depth for layering multiple overlays.
///
/// ## Usage
///
/// ```swift
/// let hudObject = createGameObject(name: "HUD")
/// let overlay = hudObject.addComponent(UIOverlay.self)
/// overlay.setContent {
///     VStack {
///         Text("Score: 0")
///         Text("Health: 100")
///     }
///     .padding(20)
/// }
/// ```
@MainActor
public final class UIOverlay: Component {
    
    // MARK: - Properties
    
    /// The UI root containing the overlay content
    public private(set) var uiRoot: UIRoot?
    
    /// Render order (higher values render on top of lower values)
    public var depth: Int = 0
    
    /// Whether this overlay blocks input from reaching lower overlays
    public var blocksInput: Bool = false
    
    /// Whether the overlay is visible
    public var isVisible: Bool = true
    
    /// Optional anchor point for positioning (screen-space coordinates 0-1)
    /// nil means full screen
    public var anchor: Anchor?
    
    /// Optional fixed size for the overlay
    /// nil means: full screen without an anchor, or fit the content when anchored
    public var size: Size?
    
    /// Padding applied to the overlay content
    public var padding: EdgeInsets = EdgeInsets(0)
    
    /// Background color (optional)
    public var backgroundColor: Color?
    
    // MARK: - Internal State
    
    /// Cached screen dimensions
    private var screenWidth: Float = 0
    private var screenHeight: Float = 0
    
    /// Bounds used for the most recent render (input uses the same area)
    internal private(set) var lastBounds: UIRect?
    
    /// Whether content needs rebuild
    private var needsRebuild: Bool = false
    
    /// Content builder for deferred/rebuild
    private var contentBuilder: (() -> [any View])?
    
    // MARK: - Anchor Type
    
    /// Anchor point for positioning the overlay
    public struct Anchor: Sendable {
        /// Horizontal position (0 = left, 0.5 = center, 1 = right)
        public let x: Float
        /// Vertical position (0 = top, 0.5 = center, 1 = bottom)
        public let y: Float
        
        public init(x: Float, y: Float) {
            self.x = x
            self.y = y
        }
        
        public static let topLeft = Anchor(x: 0, y: 0)
        public static let topCenter = Anchor(x: 0.5, y: 0)
        public static let topRight = Anchor(x: 1, y: 0)
        public static let centerLeft = Anchor(x: 0, y: 0.5)
        public static let center = Anchor(x: 0.5, y: 0.5)
        public static let centerRight = Anchor(x: 1, y: 0.5)
        public static let bottomLeft = Anchor(x: 0, y: 1)
        public static let bottomCenter = Anchor(x: 0.5, y: 1)
        public static let bottomRight = Anchor(x: 1, y: 1)
    }
    
    // MARK: - Initialization
    
    public required init() {
        super.init()
    }
    
    // MARK: - Content Management
    
    /// Set the UI content using a ViewBuilder
    public func setContent(@ViewBuilder _ content: @escaping () -> [any View]) {
        self.contentBuilder = content
        rebuildContent()
    }
    
    /// Set the UI content with a single view
    public func setContent(_ content: any View) {
        self.contentBuilder = { [content] }
        rebuildContent()
    }
    
    /// Rebuild the UI content (call after modifying state that affects UI)
    public func rebuildContent() {
        guard let builder = contentBuilder else { return }
        
        let views = builder()
        let rootContent: any View
        
        if views.count == 1 {
            rootContent = views[0]
        } else {
            rootContent = VStack(children: views)
        }
        
        uiRoot = UIRoot(padding: padding, content: rootContent)
        uiRoot?.backgroundColor = backgroundColor
    }
    
    /// Mark content for rebuild on next frame
    public func setNeedsRebuild() {
        needsRebuild = true
    }
    
    // MARK: - Lifecycle
    
    public override func awake() {
        // Register with overlay manager
        UIOverlayManager.shared.register(self)
    }
    
    public override func onDestroy() {
        // Unregister from overlay manager
        UIOverlayManager.shared.unregister(self)
    }
    
    public override func onEnable() {
        UIOverlayManager.shared.register(self)
    }
    
    public override func onDisable() {
        UIOverlayManager.shared.unregister(self)
    }
    
    public override func update(deltaTime: Float) {
        if needsRebuild {
            rebuildContent()
            needsRebuild = false
        }
    }
    
    // MARK: - Rendering
    
    /// Render the overlay (called by UIOverlayManager)
    internal func render(context: RenderContext) {
        guard isEnabled && isVisible, let uiRoot = uiRoot else { return }
        
        screenWidth = Float(context.width)
        screenHeight = Float(context.height)
        
        // Calculate overlay bounds based on anchor and size
        let fitted = (size == nil && anchor != nil)
            ? uiRoot.fittingSize(maxWidth: screenWidth, maxHeight: screenHeight, renderer: context.renderer)
            : nil
        let bounds = calculateBounds(fittedSize: fitted)
        lastBounds = bounds
        
        uiRoot.render(context, in: bounds)
    }
    
    /// Handle input for this overlay (called by UIOverlayManager)
    /// Returns true if input was consumed
    internal func handleInput(_ input: Input, screenWidth: Float, screenHeight: Float) -> Bool {
        guard isEnabled && isVisible, let uiRoot = uiRoot else { return false }
        
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        
        let bounds = lastBounds ?? calculateBounds(fittedSize: nil)
        
        // Check if mouse is within overlay bounds
        let (mx, my) = input.getMousePosition()
        let mouseX = Float(mx)
        let mouseY = Float(my)
        
        if mouseX >= bounds.x && mouseX < bounds.x + bounds.width &&
           mouseY >= bounds.y && mouseY < bounds.y + bounds.height {
            // Mouse is over this overlay
            uiRoot.handleInput(input, in: bounds)
            return blocksInput
        }
        
        return false
    }
    
    // MARK: - Bounds Calculation
    
    private func calculateBounds(fittedSize: Size?) -> UIRect {
        let overlayWidth: Float
        let overlayHeight: Float
        
        if let size = size ?? fittedSize {
            overlayWidth = size.width
            overlayHeight = size.height
        } else {
            overlayWidth = screenWidth
            overlayHeight = screenHeight
        }
        
        let x: Float
        let y: Float
        
        if let anchor = anchor {
            // Position based on anchor
            x = (screenWidth - overlayWidth) * anchor.x
            y = (screenHeight - overlayHeight) * anchor.y
        } else {
            // Full screen
            x = 0
            y = 0
        }
        
        return UIRect(x: x, y: y, width: overlayWidth, height: overlayHeight)
    }
    
    // MARK: - Fluent Configuration
    
    /// Set the render depth
    @discardableResult
    public func depth(_ value: Int) -> Self {
        self.depth = value
        return self
    }
    
    /// Set whether this overlay blocks input
    @discardableResult
    public func blocksInput(_ value: Bool) -> Self {
        self.blocksInput = value
        return self
    }
    
    /// Set the anchor position
    @discardableResult
    public func anchor(_ value: Anchor) -> Self {
        self.anchor = value
        return self
    }
    
    /// Set the overlay size
    @discardableResult
    public func size(_ width: Float, _ height: Float) -> Self {
        self.size = Size(width: width, height: height)
        return self
    }
    
    /// Set the padding
    @discardableResult
    public func padding(_ value: EdgeInsets) -> Self {
        self.padding = value
        uiRoot?.padding = value
        return self
    }
    
    /// Set padding for all sides
    @discardableResult
    public func padding(_ value: Float) -> Self {
        self.padding = EdgeInsets(value)
        uiRoot?.padding = EdgeInsets(value)
        return self
    }
    
    /// Set the background color
    @discardableResult
    public func backgroundColor(_ color: Color?) -> Self {
        self.backgroundColor = color
        uiRoot?.backgroundColor = color
        return self
    }
}
