

/// The root container for a UI hierarchy
/// 
/// This manages the entire UI tree, handling layout, rendering, and input.
@MainActor
public final class UIRoot {
    /// The root view
    public var content: any View
    
    /// The bitmap font used for text rendering
    public var font: BitmapFont
    
    /// Background color (optional)
    public var backgroundColor: Color?
    
    /// Padding around the entire UI
    public var padding: EdgeInsets
    
    /// Previous mouse state for detecting clicks
    private var wasMouseDown: Bool = false
    private var lastMouseX: Float = 0
    private var lastMouseY: Float = 0
    
    /// Track previous key states for detecting key presses
    private var previousKeyStates: [Key: Bool] = [:]
    
    /// Cached screen bounds
    private var cachedBounds: UIRect = .zero
    
    public init(
        font: BitmapFont? = nil,
        padding: EdgeInsets = EdgeInsets(0),
        @ViewBuilder content: () -> [any View]
    ) {
        self.font = font ?? BitmapFont.createBuiltinFont()
        self.padding = padding
        
        let views = content()
        if views.count == 1 {
            self.content = views[0]
        } else {
            self.content = VStack(children: views)
        }
    }
    
    /// Create with a single view
    public init(
        font: BitmapFont? = nil,
        padding: EdgeInsets = EdgeInsets(0),
        content: any View
    ) {
        self.font = font ?? BitmapFont.createBuiltinFont()
        self.padding = padding
        self.content = content
    }
    
    /// Process input and update UI state
    public func handleInput(_ input: Input) {
        let (mx, my) = input.getMousePosition()
        let mouseX = Float(mx)
        let mouseY = Float(my)
        let isMouseDown = input.isMouseButtonDown(.left)
        
        // Create appropriate mouse event
        let eventType: MouseEventType
        if isMouseDown && !wasMouseDown {
            eventType = .pressed(.left)
        } else if !isMouseDown && wasMouseDown {
            eventType = .released(.left)
        } else if mouseX != lastMouseX || mouseY != lastMouseY {
            eventType = .moved
        } else {
            // No event to send
            wasMouseDown = isMouseDown
            lastMouseX = mouseX
            lastMouseY = mouseY
            return
        }
        
        let event = MouseEvent(type: eventType, x: mouseX, y: mouseY)
        
        // Get render context bounds (we need the screen size)
        // For now, use a reasonable default; this will be set properly during render
        let bounds = UIRect(x: padding.leading, y: padding.top, 
                           width: 800 - padding.horizontal, 
                           height: 600 - padding.vertical)
        
        _ = content.handleMouse(event, in: bounds)
        
        wasMouseDown = isMouseDown
        lastMouseX = mouseX
        lastMouseY = mouseY
    }
    
    /// Render the UI
    public func render(_ renderContext: RenderContext) {
        let context = UIRenderContext(renderer: renderContext.renderer, font: font)
        UIGlobals.currentContext = context
        
        // Calculate content bounds
        let bounds = context.bounds.inset(by: padding)
        cachedBounds = bounds
        
        // Draw background if set
        if let bg = backgroundColor {
            context.fillRect(context.bounds, color: bg)
        }
        
        // Render content
        content.render(in: bounds, context: context)
        
        UIGlobals.currentContext = nil
    }
    
    /// Process input with correct bounds (call after render to use correct bounds)
    public func handleInput(_ input: Input, screenWidth: Float, screenHeight: Float) {
        let (mx, my) = input.getMousePosition()
        let mouseX = Float(mx)
        let mouseY = Float(my)
        let isMouseDown = input.isMouseButtonDown(.left)
        
        // Calculate actual bounds
        let bounds = UIRect(
            x: padding.leading,
            y: padding.top,
            width: screenWidth - padding.horizontal,
            height: screenHeight - padding.vertical
        )
        
        // Create appropriate mouse event
        let eventType: MouseEventType
        if isMouseDown && !wasMouseDown {
            eventType = .pressed(.left)
        } else if !isMouseDown && wasMouseDown {
            eventType = .released(.left)
        } else {
            eventType = .moved
        }
        
        let event = MouseEvent(type: eventType, x: mouseX, y: mouseY)
        _ = content.handleMouse(event, in: bounds)
        
        wasMouseDown = isMouseDown
        lastMouseX = mouseX
        lastMouseY = mouseY
        
        // Handle keyboard input
        handleKeyboardInput(input, in: bounds)
    }
    
    /// Process keyboard input
    private func handleKeyboardInput(_ input: Input, in bounds: UIRect) {
        // Check all keys for state changes
        let keysToCheck: [Key] = [
            .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
            .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
            .num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9,
            .space, .enter, .backspace, .delete, .escape, .tab,
            .left, .right, .up, .down
        ]
        
        let isShiftDown = input.isKeyDown(.shift)
        
        for key in keysToCheck {
            let isDown = input.isKeyDown(key)
            let wasDown = previousKeyStates[key] ?? false
            
            if isDown && !wasDown {
                // Key just pressed
                let event = KeyboardEvent(type: .pressed, key: key)
                _ = content.handleKeyboard(event)
                
                // Also send character event for character keys
                if let char = characterForKey(key, shift: isShiftDown) {
                    let charEvent = KeyboardEvent(type: .character(char), key: key)
                    _ = content.handleKeyboard(charEvent)
                }
            } else if !isDown && wasDown {
                // Key just released
                let event = KeyboardEvent(type: .released, key: key)
                _ = content.handleKeyboard(event)
            }
            
            previousKeyStates[key] = isDown
        }
    }
    
    /// Convert a key to its character representation
    private func characterForKey(_ key: Key, shift: Bool) -> Character? {
        switch key {
        case .a: return shift ? "A" : "a"
        case .b: return shift ? "B" : "b"
        case .c: return shift ? "C" : "c"
        case .d: return shift ? "D" : "d"
        case .e: return shift ? "E" : "e"
        case .f: return shift ? "F" : "f"
        case .g: return shift ? "G" : "g"
        case .h: return shift ? "H" : "h"
        case .i: return shift ? "I" : "i"
        case .j: return shift ? "J" : "j"
        case .k: return shift ? "K" : "k"
        case .l: return shift ? "L" : "l"
        case .m: return shift ? "M" : "m"
        case .n: return shift ? "N" : "n"
        case .o: return shift ? "O" : "o"
        case .p: return shift ? "P" : "p"
        case .q: return shift ? "Q" : "q"
        case .r: return shift ? "R" : "r"
        case .s: return shift ? "S" : "s"
        case .t: return shift ? "T" : "t"
        case .u: return shift ? "U" : "u"
        case .v: return shift ? "V" : "v"
        case .w: return shift ? "W" : "w"
        case .x: return shift ? "X" : "x"
        case .y: return shift ? "Y" : "y"
        case .z: return shift ? "Z" : "z"
        case .num0: return shift ? ")" : "0"
        case .num1: return shift ? "!" : "1"
        case .num2: return shift ? "@" : "2"
        case .num3: return shift ? "#" : "3"
        case .num4: return shift ? "$" : "4"
        case .num5: return shift ? "%" : "5"
        case .num6: return shift ? "^" : "6"
        case .num7: return shift ? "&" : "7"
        case .num8: return shift ? "*" : "8"
        case .num9: return shift ? "(" : "9"
        case .space: return " "
        default: return nil
        }
    }
}
