

/// A tabbed panel container that shows one content view at a time
@MainActor
public final class TabPanel: View {
    
    /// A single tab with title and content
    public struct Tab {
        public let title: String
        public let content: any View
        
        public init(_ title: String, @SingleViewBuilder content: () -> any View) {
            self.title = title
            self.content = content()
        }
        
        public init(_ title: String, content: any View) {
            self.title = title
            self.content = content
        }
    }
    
    private var tabs: [Tab]
    private var selectedIndex: Int
    private var hoveredTabIndex: Int = -1
    private var cachedTabWidths: [Float] = []
    
    // Styling
    private var tabHeight: Float = 28
    private var tabPadding: Float = 12
    private var tabSpacing: Float = 2
    
    private var tabBackground: Color = Color(r: 45, g: 45, b: 45)
    private var tabBackgroundHover: Color = Color(r: 55, g: 55, b: 55)
    private var tabBackgroundSelected: Color = Color(r: 60, g: 60, b: 60)
    private var tabTextColor: Color = Color(r: 180, g: 180, b: 180)
    private var tabTextColorSelected: Color = .white
    private var tabIndicatorColor: Color = .cornflowerBlue
    private var contentBackground: Color = Color(r: 35, g: 35, b: 35)
    private var borderColor: Color = Color(r: 60, g: 60, b: 60)
    
    private var onTabChanged: ((Int) -> Void)?
    
    public init(selectedIndex: Int = 0, tabs: [Tab]) {
        self.selectedIndex = selectedIndex
        self.tabs = tabs
    }
    
    public init(selectedIndex: Int = 0, @TabBuilder tabs: () -> [Tab]) {
        self.selectedIndex = selectedIndex
        self.tabs = tabs()
    }
    
    // MARK: - Fluent Modifiers
    
    @discardableResult
    public func tabHeight(_ height: Float) -> Self {
        self.tabHeight = height
        return self
    }
    
    @discardableResult
    public func tabStyle(
        background: Color? = nil,
        backgroundHover: Color? = nil,
        backgroundSelected: Color? = nil,
        textColor: Color? = nil,
        textColorSelected: Color? = nil,
        indicatorColor: Color? = nil
    ) -> Self {
        if let bg = background { tabBackground = bg }
        if let hover = backgroundHover { tabBackgroundHover = hover }
        if let selected = backgroundSelected { tabBackgroundSelected = selected }
        if let text = textColor { tabTextColor = text }
        if let textSel = textColorSelected { tabTextColorSelected = textSel }
        if let indicator = indicatorColor { tabIndicatorColor = indicator }
        return self
    }
    
    @discardableResult
    public func contentBackground(_ color: Color) -> Self {
        self.contentBackground = color
        return self
    }
    
    @discardableResult
    public func borderColor(_ color: Color) -> Self {
        self.borderColor = color
        return self
    }
    
    @discardableResult
    public func onTabChanged(_ handler: @escaping (Int) -> Void) -> Self {
        self.onTabChanged = handler
        return self
    }
    
    /// Select a tab programmatically
    public func selectTab(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectedIndex = index
        onTabChanged?(index)
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        let width = proposal.width ?? 300
        let height = proposal.height ?? 200
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !tabs.isEmpty else { return }
        
        // Calculate tab bar area
        let tabBarBounds = UIRect(
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: tabHeight
        )
        
        // Draw tab bar background
        Primitives.fillRect(
            Int(tabBarBounds.x), Int(tabBarBounds.y),
            Int(tabBarBounds.width), Int(tabBarBounds.height),
            tabBackground
        )
        
        // Draw tabs and cache widths
        cachedTabWidths = tabs.map { measureTabWidth($0.title, context: context) + tabPadding * 2 }
        var tabX = bounds.x + tabSpacing
        for (index, tab) in tabs.enumerated() {
            let tabWidth = cachedTabWidths[index]
            let isSelected = index == selectedIndex
            let isHovered = index == hoveredTabIndex
            
            // Tab background
            let bgColor: Color
            if isSelected {
                bgColor = tabBackgroundSelected
            } else if isHovered {
                bgColor = tabBackgroundHover
            } else {
                bgColor = tabBackground
            }
            
            Primitives.fillRect(
                Int(tabX), Int(tabBarBounds.y),
                Int(tabWidth), Int(tabHeight),
                bgColor
            )
            
            // Selection indicator (bottom line)
            if isSelected {
                Primitives.fillRect(
                    Int(tabX), Int(tabBarBounds.y + tabHeight - 2),
                    Int(tabWidth), 2,
                    tabIndicatorColor
                )
            }
            
            // Tab text
            let textColor = isSelected ? tabTextColorSelected : tabTextColor
            let textY = tabBarBounds.y + (tabHeight - 8) / 2
            context.drawText(tab.title, at: (tabX + tabPadding, textY), color: textColor)
            
            tabX += tabWidth + tabSpacing
        }
        
        // Content area
        let contentBounds = UIRect(
            x: bounds.x,
            y: bounds.y + tabHeight,
            width: bounds.width,
            height: bounds.height - tabHeight
        )
        
        // Draw content background
        Primitives.fillRect(
            Int(contentBounds.x), Int(contentBounds.y),
            Int(contentBounds.width), Int(contentBounds.height),
            contentBackground
        )
        
        // Draw border around content
        Primitives.drawRect(
            Int(contentBounds.x), Int(contentBounds.y),
            Int(contentBounds.width), Int(contentBounds.height),
            borderColor
        )
        
        // Render selected tab content
        if selectedIndex >= 0 && selectedIndex < tabs.count {
            let paddedContent = UIRect(
                x: contentBounds.x + 8,
                y: contentBounds.y + 8,
                width: contentBounds.width - 16,
                height: contentBounds.height - 16
            )
            tabs[selectedIndex].content.render(in: paddedContent, context: context)
        }
    }
    
    private func measureTabWidth(_ title: String, context: UIRenderContext) -> Float {
        return Float(title.count * 6) // Approximate character width
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !tabs.isEmpty else { return false }
        
        let tabBarBounds = UIRect(
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: tabHeight
        )
        
        let contentBounds = UIRect(
            x: bounds.x,
            y: bounds.y + tabHeight,
            width: bounds.width,
            height: bounds.height - tabHeight
        )
        
        // Check if in tab bar
        let inTabBar = event.x >= tabBarBounds.x && event.x < tabBarBounds.x + tabBarBounds.width &&
                       event.y >= tabBarBounds.y && event.y < tabBarBounds.y + tabBarBounds.height
        
        if inTabBar {
            // Find which tab is under cursor using cached widths
            var tabX = bounds.x + tabSpacing
            var foundTab = -1
            
            for (index, _) in tabs.enumerated() {
                let tabWidth = index < cachedTabWidths.count ? cachedTabWidths[index] : Float(60)
                if event.x >= tabX && event.x < tabX + tabWidth {
                    foundTab = index
                    break
                }
                tabX += tabWidth + tabSpacing
            }
            
            switch event.type {
            case .moved:
                hoveredTabIndex = foundTab
                return true
                
            case .pressed(.left):
                if foundTab >= 0 && foundTab != selectedIndex {
                    selectedIndex = foundTab
                    onTabChanged?(selectedIndex)
                }
                return true
                
            default:
                break
            }
        } else {
            hoveredTabIndex = -1
        }
        
        // Forward to content
        let inContent = event.x >= contentBounds.x && event.x < contentBounds.x + contentBounds.width &&
                        event.y >= contentBounds.y && event.y < contentBounds.y + contentBounds.height
        
        if inContent && selectedIndex >= 0 && selectedIndex < tabs.count {
            let paddedContent = UIRect(
                x: contentBounds.x + 8,
                y: contentBounds.y + 8,
                width: contentBounds.width - 16,
                height: contentBounds.height - 16
            )
            return tabs[selectedIndex].content.handleMouse(event, in: paddedContent)
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        // Forward to selected tab content
        if selectedIndex >= 0 && selectedIndex < tabs.count {
            return tabs[selectedIndex].content.handleKeyboard(event)
        }
        return false
    }
}

// MARK: - Tab Builder

@resultBuilder
public struct TabBuilder {
    public static func buildBlock(_ components: TabPanel.Tab...) -> [TabPanel.Tab] {
        components
    }
    
    public static func buildArray(_ components: [[TabPanel.Tab]]) -> [TabPanel.Tab] {
        components.flatMap { $0 }
    }
}
