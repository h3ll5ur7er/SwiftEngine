

/// A text input field
@MainActor
public final class TextField: View {
    /// The current text value
    public var text: String {
        didSet {
            onTextChanged?(text)
        }
    }
    
    /// Placeholder text shown when empty
    public var placeholder: String
    
    /// Text color
    public var textColor: Color
    
    /// Placeholder color
    public var placeholderColor: Color
    
    /// Background color
    public var backgroundColor: Color
    
    /// Border color when not focused
    public var borderColor: Color
    
    /// Border color when focused
    public var focusedBorderColor: Color
    
    /// Padding inside the field
    public var padding: EdgeInsets
    
    /// Font scale
    public var scale: Int
    
    /// Whether the field is focused
    public private(set) var isFocused: Bool = false
    
    /// Cursor position (character index)
    private var cursorPosition: Int = 0
    
    /// Cursor blink timer
    private var cursorBlinkTime: Float = 0
    private var showCursor: Bool = true
    
    /// Callback when text changes
    public var onTextChanged: ((String) -> Void)?
    
    /// Callback when return is pressed
    public var onSubmit: ((String) -> Void)?
    
    /// Optional binding for two-way text synchronization
    private var textBinding: Binding<String>?
    
    public init(_ placeholder: String = "", text: String = "") {
        self.placeholder = placeholder
        self.text = text
        self.textColor = .white
        self.placeholderColor = .gray
        self.backgroundColor = Color(r: 40, g: 40, b: 40)
        self.borderColor = Color(r: 60, g: 60, b: 60)
        self.focusedBorderColor = .cornflowerBlue
        self.padding = EdgeInsets(horizontal: 8, vertical: 6)
        self.scale = 1
        self.cursorPosition = text.count
    }
    
    /// Initialize with a binding for two-way text synchronization
    public init(text: Binding<String>, placeholder: String = "") {
        self.placeholder = placeholder
        self.textBinding = text
        self.text = text.wrappedValue
        self.textColor = .white
        self.placeholderColor = .gray
        self.backgroundColor = Color(r: 40, g: 40, b: 40)
        self.borderColor = Color(r: 60, g: 60, b: 60)
        self.focusedBorderColor = .cornflowerBlue
        self.padding = EdgeInsets(horizontal: 8, vertical: 6)
        self.scale = 1
        self.cursorPosition = self.text.count
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Calculate based on content or minimum size
        let charWidth: Float = 6 * Float(scale)
        let charHeight: Float = 8 * Float(scale)
        
        let minChars: Float = 20  // Minimum width in characters
        let contentWidth = max(Float(text.count), minChars) * charWidth
        
        return Size(
            width: proposal.width ?? (contentWidth + padding.horizontal),
            height: charHeight + padding.vertical
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Update cursor blink (simple timer based on frame count)
        cursorBlinkTime += 0.016  // Approximate 60fps
        if cursorBlinkTime >= 0.5 {
            cursorBlinkTime = 0
            showCursor.toggle()
        }
        
        // Draw background
        context.fillRect(bounds, color: backgroundColor)
        
        // Draw border
        let borderCol = isFocused ? focusedBorderColor : borderColor
        context.strokeRect(bounds, color: borderCol, lineWidth: 1)
        
        // Calculate text area
        let textBounds = bounds.inset(by: padding)
        
        // Draw text or placeholder
        let displayText = text.isEmpty ? placeholder : text
        let displayColor = text.isEmpty ? placeholderColor : textColor
        
        context.drawText(displayText, at: (textBounds.x, textBounds.y), color: displayColor, scale: scale)
        
        // Draw cursor if focused
        if isFocused && showCursor {
            let charWidth = Float(6 * scale)
            let cursorX = textBounds.x + Float(cursorPosition) * charWidth
            let cursorHeight = Float(8 * scale)
            
            context.drawLine(
                from: (cursorX, textBounds.y),
                to: (cursorX, textBounds.y + cursorHeight),
                color: textColor
            )
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        switch event.type {
        case .pressed(.left):
            let wasInBounds = bounds.contains(x: event.x, y: event.y)
            if wasInBounds {
                isFocused = true
                showCursor = true
                cursorBlinkTime = 0
                
                // Calculate cursor position from click
                let textBounds = bounds.inset(by: padding)
                let charWidth = Float(6 * scale)
                let relativeX = event.x - textBounds.x
                cursorPosition = min(text.count, max(0, Int(relativeX / charWidth)))
                
                return true
            } else {
                isFocused = false
            }
        default:
            break
        }
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        guard isFocused else { return false }
        
        switch event.type {
        case .pressed:
            switch event.key {
            case .backspace:
                if cursorPosition > 0 {
                    let index = text.index(text.startIndex, offsetBy: cursorPosition - 1)
                    text.remove(at: index)
                    cursorPosition -= 1
                    syncBinding()
                }
                return true
                
            case .delete:
                if cursorPosition < text.count {
                    let index = text.index(text.startIndex, offsetBy: cursorPosition)
                    text.remove(at: index)
                    syncBinding()
                }
                return true
                
            case .left:
                cursorPosition = max(0, cursorPosition - 1)
                showCursor = true
                cursorBlinkTime = 0
                return true
                
            case .right:
                cursorPosition = min(text.count, cursorPosition + 1)
                showCursor = true
                cursorBlinkTime = 0
                return true
                
            case .enter:
                onSubmit?(text)
                return true
                
            case .escape:
                isFocused = false
                return true
                
            default:
                break
            }
            
        case .character(let char):
            // Insert character at cursor position
            if char.isASCII && !char.isNewline {
                let index = text.index(text.startIndex, offsetBy: cursorPosition)
                text.insert(char, at: index)
                cursorPosition += 1
                showCursor = true
                cursorBlinkTime = 0
                syncBinding()
                return true
            }
            
        default:
            break
        }
        
        return false
    }
    
    /// Sync text to binding if present
    private func syncBinding() {
        textBinding?.wrappedValue = text
    }
}

// MARK: - Fluent Modifiers

extension TextField {
    /// Set placeholder text
    public func placeholder(_ text: String) -> TextField {
        self.placeholder = text
        return self
    }
    
    /// Set text color
    public func foregroundColor(_ color: Color) -> TextField {
        self.textColor = color
        return self
    }
    
    /// Set background color
    public func backgroundColor(_ color: Color) -> TextField {
        self.backgroundColor = color
        return self
    }
    
    /// Set border color
    public func borderColor(_ color: Color) -> TextField {
        self.borderColor = color
        return self
    }
    
    /// Set focused border color
    public func focusedBorderColor(_ color: Color) -> TextField {
        self.focusedBorderColor = color
        return self
    }
    
    /// Set font scale
    public func fontSize(_ scale: Int) -> TextField {
        self.scale = scale
        return self
    }
    
    /// Set text change callback
    public func onChange(_ action: @escaping (String) -> Void) -> TextField {
        self.onTextChanged = action
        return self
    }
    
    /// Set submit callback
    public func onSubmit(_ action: @escaping (String) -> Void) -> TextField {
        self.onSubmit = action
        return self
    }
}
