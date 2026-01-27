

/// A dropdown selection control
@MainActor
public final class Dropdown: View {
    
    public var selectedIndex: Int {
        didSet {
            if selectedIndex != oldValue {
                selectedIndexBinding?.wrappedValue = selectedIndex
            }
        }
    }
    public var options: [String]
    
    /// Optional binding for two-way index synchronization
    private var selectedIndexBinding: Binding<Int>?
    
    private var placeholder: String
    private var isOpen: Bool = false
    private var hoveredIndex: Int = -1
    private var isHoveredMain: Bool = false
    
    private var bgColor: Color = Color(r: 50, g: 50, b: 50)
    private var textColor: Color = .white
    private var highlightColor: Color = .cornflowerBlue
    private var borderColor: Color = Color(r: 80, g: 80, b: 80)
    private var dropdownBgColor: Color = Color(r: 40, g: 40, b: 40)
    
    private var minWidth: Float = 150
    private var itemHeight: Float = 24
    private var maxVisibleItems: Int = 6
    
    private var onChangeHandler: ((Int, String) -> Void)?
    
    public init(_ placeholder: String = "Select...", options: [String], selectedIndex: Int = -1) {
        self.placeholder = placeholder
        self.options = options
        self.selectedIndex = selectedIndex
    }
    
    /// Initialize with a binding for two-way index synchronization
    public init(options: [String], selectedIndex: Binding<Int>, placeholder: String = "Select...") {
        self.placeholder = placeholder
        self.options = options
        self.selectedIndexBinding = selectedIndex
        self.selectedIndex = selectedIndex.wrappedValue
    }
    
    @discardableResult
    public func backgroundColor(_ color: Color) -> Self {
        bgColor = color
        return self
    }
    
    @discardableResult
    public func textColor(_ color: Color) -> Self {
        textColor = color
        return self
    }
    
    @discardableResult
    public func highlightColor(_ color: Color) -> Self {
        highlightColor = color
        return self
    }
    
    @discardableResult
    public func borderColor(_ color: Color) -> Self {
        borderColor = color
        return self
    }
    
    @discardableResult
    public func width(_ width: Float) -> Self {
        minWidth = width
        return self
    }
    
    @discardableResult
    public func itemHeight(_ height: Float) -> Self {
        itemHeight = height
        return self
    }
    
    @discardableResult
    public func maxItems(_ count: Int) -> Self {
        maxVisibleItems = count
        return self
    }
    
    @discardableResult
    public func onChange(_ handler: @escaping (Int, String) -> Void) -> Self {
        onChangeHandler = handler
        return self
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        let width = proposal.width ?? minWidth
        // When closed, just the header height
        // When open, include dropdown list (but this is handled specially in render)
        return Size(width: width, height: itemHeight)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        let charHeight: Float = 8
        
        // Main button background
        let mainBg = isHoveredMain ? bgColor.lighter(by: 0.1) : bgColor
        context.primitives.fillRect(
            Int(bounds.x), Int(bounds.y),
            Int(bounds.width), Int(itemHeight),
            mainBg
        )
        
        // Border
        context.primitives.drawRect(
            Int(bounds.x), Int(bounds.y),
            Int(bounds.width), Int(itemHeight),
            isOpen ? highlightColor : borderColor
        )
        
        // Selected text or placeholder
        let displayText: String
        let displayColor: Color
        if selectedIndex >= 0 && selectedIndex < options.count {
            displayText = options[selectedIndex]
            displayColor = textColor
        } else {
            displayText = placeholder
            displayColor = Color(r: 128, g: 128, b: 128)
        }
        
        let textX = bounds.x + 8
        let textY = bounds.y + (itemHeight - charHeight) / 2
        context.drawText(displayText, at: (textX, textY), color: displayColor)
        
        // Dropdown arrow
        let arrowX = Int(bounds.x + bounds.width - 16)
        let arrowY = Int(bounds.y + itemHeight / 2)
        if isOpen {
            // Up arrow
            context.primitives.drawLine(arrowX, arrowY + 2, arrowX + 4, arrowY - 2, textColor)
            context.primitives.drawLine(arrowX + 4, arrowY - 2, arrowX + 8, arrowY + 2, textColor)
        } else {
            // Down arrow
            context.primitives.drawLine(arrowX, arrowY - 2, arrowX + 4, arrowY + 2, textColor)
            context.primitives.drawLine(arrowX + 4, arrowY + 2, arrowX + 8, arrowY - 2, textColor)
        }
        
        // Dropdown list (rendered on top when open)
        if isOpen && !options.isEmpty {
            let visibleCount = min(options.count, maxVisibleItems)
            let listHeight = Float(visibleCount) * itemHeight
            let listY = bounds.y + itemHeight
            
            // Dropdown background
            context.primitives.fillRect(
                Int(bounds.x), Int(listY),
                Int(bounds.width), Int(listHeight),
                dropdownBgColor
            )
            
            // Dropdown border
            context.primitives.drawRect(
                Int(bounds.x), Int(listY),
                Int(bounds.width), Int(listHeight),
                borderColor
            )
            
            // Options
            for i in 0..<visibleCount {
                let optionY = listY + Float(i) * itemHeight
                
                // Highlight hovered item
                if i == hoveredIndex {
                    context.primitives.fillRect(
                        Int(bounds.x + 1), Int(optionY),
                        Int(bounds.width - 2), Int(itemHeight),
                        highlightColor
                    )
                }
                
                // Option text
                let optionTextY = optionY + (itemHeight - charHeight) / 2
                let optionColor = i == selectedIndex ? highlightColor.lighter(by: 0.3) : textColor
                context.drawText(options[i], at: (textX, optionTextY), color: i == hoveredIndex ? .white : optionColor)
            }
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        let mainBounds = UIRect(x: bounds.x, y: bounds.y, width: bounds.width, height: itemHeight)
        let inMain = event.x >= mainBounds.x && event.x < mainBounds.x + mainBounds.width &&
                     event.y >= mainBounds.y && event.y < mainBounds.y + mainBounds.height
        
        // Calculate dropdown bounds
        let visibleCount = min(options.count, maxVisibleItems)
        let listHeight = Float(visibleCount) * itemHeight
        let listBounds = UIRect(x: bounds.x, y: bounds.y + itemHeight, width: bounds.width, height: listHeight)
        let inList = isOpen && event.x >= listBounds.x && event.x < listBounds.x + listBounds.width &&
                     event.y >= listBounds.y && event.y < listBounds.y + listBounds.height
        
        switch event.type {
        case .moved:
            isHoveredMain = inMain
            if inList {
                let relativeY = event.y - listBounds.y
                hoveredIndex = Int(relativeY / itemHeight)
                if hoveredIndex >= options.count {
                    hoveredIndex = -1
                }
            } else {
                hoveredIndex = -1
            }
            return inMain || inList
            
        case .pressed:
            if inMain {
                isOpen = !isOpen
                hoveredIndex = -1
                return true
            } else if inList {
                let relativeY = event.y - listBounds.y
                let index = Int(relativeY / itemHeight)
                if index >= 0 && index < options.count {
                    selectedIndex = index
                    isOpen = false
                    onChangeHandler?(index, options[index])
                }
                return true
            } else if isOpen {
                // Click outside closes dropdown
                isOpen = false
                return true
            }
            
        case .released:
            break
        }
        
        return inMain || (isOpen && inList)
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        guard isOpen else { return false }
        
        switch event.type {
        case .pressed:
            switch event.key {
            case .escape:
                isOpen = false
                return true
            case .enter, .space:
                if hoveredIndex >= 0 && hoveredIndex < options.count {
                    selectedIndex = hoveredIndex
                    isOpen = false
                    onChangeHandler?(selectedIndex, options[selectedIndex])
                }
                return true
            case .up:
                hoveredIndex = max(0, hoveredIndex - 1)
                return true
            case .down:
                hoveredIndex = min(options.count - 1, hoveredIndex + 1)
                return true
            default:
                break
            }
        default:
            break
        }
        
        return false
    }
    
    /// Close the dropdown programmatically
    public func close() {
        isOpen = false
    }
    
    /// Open the dropdown programmatically
    public func open() {
        isOpen = true
    }
}
