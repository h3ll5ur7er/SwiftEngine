

/// A scrollable container view
@MainActor
public final class ScrollView: View {
    
    private var content: any View
    private var showsVerticalIndicator: Bool = true
    private var showsHorizontalIndicator: Bool = false
    private var indicatorColor: Color = Color(r: 100, g: 100, b: 100)
    private var indicatorWidth: Float = 6
    
    // Scroll state
    private var scrollOffsetX: Float = 0
    private var scrollOffsetY: Float = 0
    private var contentSize: Size = .zero
    private var viewportSize: Size = .zero
    private var isDraggingVertical: Bool = false
    private var isDraggingHorizontal: Bool = false
    private var lastMouseY: Float = 0
    private var lastMouseX: Float = 0
    private var isHovered: Bool = false
    
    public init(@SingleViewBuilder content: () -> any View) {
        self.content = content()
    }
    
    public init(content: any View) {
        self.content = content
    }
    
    @discardableResult
    public func showsIndicators(vertical: Bool = true, horizontal: Bool = false) -> Self {
        showsVerticalIndicator = vertical
        showsHorizontalIndicator = horizontal
        return self
    }
    
    @discardableResult
    public func indicatorStyle(color: Color, width: Float = 6) -> Self {
        indicatorColor = color
        indicatorWidth = width
        return self
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // ScrollView takes the proposed size (or defaults)
        let width = proposal.width ?? 200
        let height = proposal.height ?? 200
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        viewportSize = Size(width: bounds.width, height: bounds.height)
        
        // Calculate content size
        let contentProposal = ProposedSize(
            width: showsHorizontalIndicator ? nil : bounds.width - (showsVerticalIndicator ? indicatorWidth + 2 : 0),
            height: nil
        )
        contentSize = content.sizeThatFits(contentProposal)
        
        // Clamp scroll offsets
        let maxScrollX = max(0, contentSize.width - bounds.width + (showsVerticalIndicator ? indicatorWidth + 2 : 0))
        let maxScrollY = max(0, contentSize.height - bounds.height + (showsHorizontalIndicator ? indicatorWidth + 2 : 0))
        scrollOffsetX = min(max(0, scrollOffsetX), maxScrollX)
        scrollOffsetY = min(max(0, scrollOffsetY), maxScrollY)
        
        // Content area (accounting for scrollbars)
        let contentAreaWidth = bounds.width - (showsVerticalIndicator && contentSize.height > bounds.height ? indicatorWidth + 2 : 0)
        let contentAreaHeight = bounds.height - (showsHorizontalIndicator && contentSize.width > bounds.width ? indicatorWidth + 2 : 0)
        
        // Render content with clipping (simulated by only rendering visible portion)
        let contentBounds = UIRect(
            x: bounds.x - scrollOffsetX,
            y: bounds.y - scrollOffsetY,
            width: contentSize.width,
            height: contentSize.height
        )
        
        // Set up clipping region
        let clipRect = UIRect(x: bounds.x, y: bounds.y, width: contentAreaWidth, height: contentAreaHeight)
        context.pushClipRect(clipRect)
        content.render(in: contentBounds, context: context)
        context.popClipRect()
        
        // Draw vertical scrollbar
        if showsVerticalIndicator && contentSize.height > bounds.height {
            let trackX = bounds.x + bounds.width - indicatorWidth - 1
            let trackY = bounds.y + 1
            let trackHeight = contentAreaHeight - 2
            
            // Track background
            context.primitives.fillRect(
                Int(trackX), Int(trackY),
                Int(indicatorWidth), Int(trackHeight),
                Color(r: 40, g: 40, b: 40)
            )
            
            // Thumb
            let visibleRatio = min(1.0, contentAreaHeight / contentSize.height)
            let thumbHeight = max(20, trackHeight * visibleRatio)
            let scrollRatio = scrollOffsetY / max(1, contentSize.height - contentAreaHeight)
            let thumbY = trackY + (trackHeight - thumbHeight) * scrollRatio
            
            let thumbColor = isDraggingVertical ? indicatorColor.lighter(by: 0.3) : indicatorColor
            context.primitives.fillRect(
                Int(trackX), Int(thumbY),
                Int(indicatorWidth), Int(thumbHeight),
                thumbColor
            )
        }
        
        // Draw horizontal scrollbar
        if showsHorizontalIndicator && contentSize.width > bounds.width {
            let trackX = bounds.x + 1
            let trackY = bounds.y + bounds.height - indicatorWidth - 1
            let trackWidth = contentAreaWidth - 2
            
            // Track background
            context.primitives.fillRect(
                Int(trackX), Int(trackY),
                Int(trackWidth), Int(indicatorWidth),
                Color(r: 40, g: 40, b: 40)
            )
            
            // Thumb
            let visibleRatio = min(1.0, contentAreaWidth / contentSize.width)
            let thumbWidth = max(20, trackWidth * visibleRatio)
            let scrollRatio = scrollOffsetX / max(1, contentSize.width - contentAreaWidth)
            let thumbX = trackX + (trackWidth - thumbWidth) * scrollRatio
            
            let thumbColor = isDraggingHorizontal ? indicatorColor.lighter(by: 0.3) : indicatorColor
            context.primitives.fillRect(
                Int(thumbX), Int(trackY),
                Int(thumbWidth), Int(indicatorWidth),
                thumbColor
            )
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let contentAreaWidth = bounds.width - (showsVerticalIndicator && contentSize.height > bounds.height ? indicatorWidth + 2 : 0)
        let contentAreaHeight = bounds.height - (showsHorizontalIndicator && contentSize.width > bounds.width ? indicatorWidth + 2 : 0)
        
        // Check if in bounds
        let inBounds = event.x >= bounds.x && event.x < bounds.x + bounds.width &&
                       event.y >= bounds.y && event.y < bounds.y + bounds.height
        
        switch event.type {
        case .moved:
            // Track mouse for dragging
            if isDraggingVertical {
                let deltaY = event.y - lastMouseY
                let trackHeight = contentAreaHeight - 2
                let maxScroll = contentSize.height - contentAreaHeight
                if trackHeight > 0 && maxScroll > 0 {
                    let scrollPerPixel = maxScroll / trackHeight
                    scrollOffsetY = max(0, min(maxScroll, scrollOffsetY + deltaY * scrollPerPixel * 1.5))
                }
            }
            if isDraggingHorizontal {
                let deltaX = event.x - lastMouseX
                let trackWidth = contentAreaWidth - 2
                let maxScroll = contentSize.width - contentAreaWidth
                if trackWidth > 0 && maxScroll > 0 {
                    let scrollPerPixel = maxScroll / trackWidth
                    scrollOffsetX = max(0, min(maxScroll, scrollOffsetX + deltaX * scrollPerPixel * 1.5))
                }
            }
            lastMouseX = event.x
            lastMouseY = event.y
            isHovered = inBounds
            return isDraggingVertical || isDraggingHorizontal
            
        case .pressed:
            lastMouseX = event.x
            lastMouseY = event.y
            if inBounds {
                // Check vertical scrollbar
                if showsVerticalIndicator && contentSize.height > bounds.height {
                    let trackX = bounds.x + bounds.width - indicatorWidth - 1
                    if event.x >= trackX {
                        isDraggingVertical = true
                        return true
                    }
                }
                
                // Check horizontal scrollbar
                if showsHorizontalIndicator && contentSize.width > bounds.width {
                    let trackY = bounds.y + bounds.height - indicatorWidth - 1
                    if event.y >= trackY {
                        isDraggingHorizontal = true
                        return true
                    }
                }
            }
            
        case .released:
            if isDraggingVertical || isDraggingHorizontal {
                isDraggingVertical = false
                isDraggingHorizontal = false
                return true
            }
        }
        
        // Forward to content if in content area
        if inBounds && event.x < bounds.x + contentAreaWidth && event.y < bounds.y + contentAreaHeight {
            let contentBounds = UIRect(
                x: bounds.x - scrollOffsetX,
                y: bounds.y - scrollOffsetY,
                width: contentSize.width,
                height: contentSize.height
            )
            return content.handleMouse(event, in: contentBounds)
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        // Forward keyboard events to content
        return content.handleKeyboard(event)
    }
    
    // Programmatic scrolling
    public func scrollTo(x: Float? = nil, y: Float? = nil) {
        if let x = x {
            scrollOffsetX = max(0, x)
        }
        if let y = y {
            scrollOffsetY = max(0, y)
        }
    }
    
    public func scrollToTop() {
        scrollOffsetY = 0
    }
    
    public func scrollToBottom() {
        scrollOffsetY = max(0, contentSize.height - viewportSize.height)
    }
}
