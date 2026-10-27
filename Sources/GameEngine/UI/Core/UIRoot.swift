

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
    
    /// Cached screen bounds
    private var cachedBounds: UIRect = .zero
    
    /// Screen size from the most recent render
    private var lastScreenSize: (width: Float, height: Float) = (0, 0)
    
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
    
    /// Process input using the screen size from the most recent render
    public func handleInput(_ input: Input) {
        handleInput(input, screenWidth: lastScreenSize.width, screenHeight: lastScreenSize.height)
    }
    
    /// Render the UI over the whole screen
    public func render(_ renderContext: RenderContext) {
        let screen = UIRect(x: 0, y: 0, width: Float(renderContext.width), height: Float(renderContext.height))
        render(renderContext, in: screen)
    }
    
    /// Render the UI within a frame (in screen coordinates)
    public func render(_ renderContext: RenderContext, in frame: UIRect) {
        let context = UIRenderContext(renderer: renderContext.renderer, font: font)
        UIGlobals.currentContext = context
        
        // Calculate content bounds
        let bounds = frame.inset(by: padding)
        cachedBounds = bounds
        lastScreenSize = (context.bounds.width, context.bounds.height)
        
        // Draw background if set
        if let bg = backgroundColor {
            context.fillRect(frame, color: bg)
        }
        
        // Render content
        content.render(in: bounds, context: context)
        
        UIGlobals.currentContext = nil
    }
    
    /// Process input for UI covering the whole screen
    public func handleInput(_ input: Input, screenWidth: Float, screenHeight: Float) {
        handleInput(input, in: UIRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
    }
    
    /// Process input for UI rendered within a frame (in screen coordinates)
    public func handleInput(_ input: Input, in frame: UIRect) {
        let (mx, my) = input.getMousePosition()
        let mouseX = Float(mx)
        let mouseY = Float(my)
        
        let bounds = frame.inset(by: padding)
        
        // Send press/release (both, for a click within one frame), otherwise a move
        let pressed = input.isMouseButtonPressed(.left)
        let released = input.isMouseButtonReleased(.left)
        if pressed {
            _ = content.handleMouse(MouseEvent(type: .pressed(.left), x: mouseX, y: mouseY), in: bounds)
        }
        if released {
            _ = content.handleMouse(MouseEvent(type: .released(.left), x: mouseX, y: mouseY), in: bounds)
        }
        if !pressed && !released {
            _ = content.handleMouse(MouseEvent(type: .moved, x: mouseX, y: mouseY), in: bounds)
        }
        
        // Handle keyboard input
        handleKeyboardInput(input, in: bounds)
    }
    
    /// The size the content (plus padding) wants, limited to the given space
    public func fittingSize(maxWidth: Float, maxHeight: Float, renderer: Renderer) -> Size {
        // Text measurement needs the font from a render context
        let previous = UIGlobals.currentContext
        UIGlobals.currentContext = UIRenderContext(renderer: renderer, font: font)
        defer { UIGlobals.currentContext = previous }
        
        // Ask for the content's ideal size (no proposal), then clamp to the space
        let content = content.sizeThatFits(ProposedSize(width: nil, height: nil))
        return Size(
            width: min(maxWidth, content.width + padding.horizontal),
            height: min(maxHeight, content.height + padding.vertical)
        )
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
            if input.isKeyPressed(key) {
                // Key just pressed
                let event = KeyboardEvent(type: .pressed, key: key)
                _ = content.handleKeyboard(event)
                
                // Also send character event for character keys
                if let char = characterForKey(key, shift: isShiftDown) {
                    let charEvent = KeyboardEvent(type: .character(char), key: key)
                    _ = content.handleKeyboard(charEvent)
                }
            }
            if input.isKeyReleased(key) {
                // Key just released
                let event = KeyboardEvent(type: .released, key: key)
                _ = content.handleKeyboard(event)
            }
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
