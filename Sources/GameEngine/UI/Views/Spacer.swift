

/// A flexible space that expands to fill available space
@MainActor
public final class Spacer: View {
    /// Minimum length (width in HStack, height in VStack)
    public var minLength: Float?
    
    public init(minLength: Float? = nil) {
        self.minLength = minLength
    }
    
    // MARK: - View Protocol
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Spacer expands to fill all available space
        // The stack will constrain this appropriately
        Size(
            width: proposal.width ?? minLength ?? 0,
            height: proposal.height ?? minLength ?? 0
        )
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // Spacer renders nothing
    }
}
