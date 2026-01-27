

/// A grid layout container
@MainActor
public final class Grid: View {
    
    private var children: [any View]
    private var columns: Int
    private var horizontalSpacing: Float
    private var verticalSpacing: Float
    private var horizontalAlignment: HorizontalAlignment
    private var verticalAlignment: VerticalAlignment
    
    public init(
        columns: Int = 2,
        horizontalSpacing: Float = 8,
        verticalSpacing: Float = 8,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> [any View]
    ) {
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.children = content()
    }
    
    public init(
        columns: Int = 2,
        horizontalSpacing: Float = 8,
        verticalSpacing: Float = 8,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        children: [any View]
    ) {
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.children = children
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        guard !children.isEmpty else { return .zero }
        
        let rows = (children.count + columns - 1) / columns
        
        // Calculate cell size based on proposal
        var cellWidth: Float = 0
        
        if let proposedWidth = proposal.width {
            cellWidth = (proposedWidth - Float(columns - 1) * horizontalSpacing) / Float(columns)
        }
        
        // Measure all children to find max sizes per row/column
        var columnWidths = [Float](repeating: 0, count: columns)
        var rowHeights = [Float](repeating: 0, count: rows)
        
        for (index, child) in children.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let childProposal = ProposedSize(
                width: cellWidth > 0 ? cellWidth : nil,
                height: nil
            )
            let childSize = child.sizeThatFits(childProposal)
            
            columnWidths[col] = max(columnWidths[col], childSize.width)
            rowHeights[row] = max(rowHeights[row], childSize.height)
        }
        
        let totalWidth = columnWidths.reduce(0, +) + Float(columns - 1) * horizontalSpacing
        let totalHeight = rowHeights.reduce(0, +) + Float(rows - 1) * verticalSpacing
        
        return Size(width: totalWidth, height: totalHeight)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !children.isEmpty else { return }
        
        let rows = (children.count + columns - 1) / columns
        
        // Calculate uniform cell size
        let cellWidth = (bounds.width - Float(columns - 1) * horizontalSpacing) / Float(columns)
        let cellHeight = (bounds.height - Float(rows - 1) * verticalSpacing) / Float(rows)
        
        for (index, child) in children.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let cellX = bounds.x + Float(col) * (cellWidth + horizontalSpacing)
            let cellY = bounds.y + Float(row) * (cellHeight + verticalSpacing)
            
            // Get child's preferred size
            let childProposal = ProposedSize(width: cellWidth, height: cellHeight)
            let childSize = child.sizeThatFits(childProposal)
            
            // Apply alignment within cell
            let alignedX: Float
            switch horizontalAlignment {
            case .leading:
                alignedX = cellX
            case .center:
                alignedX = cellX + (cellWidth - childSize.width) / 2
            case .trailing:
                alignedX = cellX + cellWidth - childSize.width
            }
            
            let alignedY: Float
            switch verticalAlignment {
            case .top:
                alignedY = cellY
            case .center:
                alignedY = cellY + (cellHeight - childSize.height) / 2
            case .bottom:
                alignedY = cellY + cellHeight - childSize.height
            }
            
            let childBounds = UIRect(
                x: alignedX,
                y: alignedY,
                width: min(childSize.width, cellWidth),
                height: min(childSize.height, cellHeight)
            )
            
            child.render(in: childBounds, context: context)
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !children.isEmpty else { return false }
        
        let rows = (children.count + columns - 1) / columns
        let cellWidth = (bounds.width - Float(columns - 1) * horizontalSpacing) / Float(columns)
        let cellHeight = (bounds.height - Float(rows - 1) * verticalSpacing) / Float(rows)
        
        for (index, child) in children.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let cellX = bounds.x + Float(col) * (cellWidth + horizontalSpacing)
            let cellY = bounds.y + Float(row) * (cellHeight + verticalSpacing)
            
            let childProposal = ProposedSize(width: cellWidth, height: cellHeight)
            let childSize = child.sizeThatFits(childProposal)
            
            let alignedX: Float
            switch horizontalAlignment {
            case .leading:
                alignedX = cellX
            case .center:
                alignedX = cellX + (cellWidth - childSize.width) / 2
            case .trailing:
                alignedX = cellX + cellWidth - childSize.width
            }
            
            let alignedY: Float
            switch verticalAlignment {
            case .top:
                alignedY = cellY
            case .center:
                alignedY = cellY + (cellHeight - childSize.height) / 2
            case .bottom:
                alignedY = cellY + cellHeight - childSize.height
            }
            
            let childBounds = UIRect(
                x: alignedX,
                y: alignedY,
                width: min(childSize.width, cellWidth),
                height: min(childSize.height, cellHeight)
            )
            
            if child.handleMouse(event, in: childBounds) {
                return true
            }
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        for child in children {
            if child.handleKeyboard(event) {
                return true
            }
        }
        return false
    }
}

/// A grid with flexible column definitions
@MainActor
public final class LazyVGrid: View {
    
    public enum GridItem {
        case fixed(Float)
        case flexible(minimum: Float = 10, maximum: Float = .infinity)
        case adaptive(minimum: Float)
    }
    
    private var children: [any View]
    private var gridItems: [GridItem]
    private var spacing: Float
    private var verticalSpacing: Float
    
    public init(
        columns: [GridItem],
        spacing: Float = 8,
        verticalSpacing: Float = 8,
        @ViewBuilder content: () -> [any View]
    ) {
        self.gridItems = columns
        self.spacing = spacing
        self.verticalSpacing = verticalSpacing
        self.children = content()
    }
    
    public init(
        columns: [GridItem],
        spacing: Float = 8,
        verticalSpacing: Float = 8,
        children: [any View]
    ) {
        self.gridItems = columns
        self.spacing = spacing
        self.verticalSpacing = verticalSpacing
        self.children = children
    }
    
    private func calculateColumnWidths(totalWidth: Float) -> [Float] {
        var widths = [Float](repeating: 0, count: gridItems.count)
        var remainingWidth = totalWidth - Float(gridItems.count - 1) * spacing
        var flexibleIndices: [Int] = []
        
        // First pass: allocate fixed widths
        for (index, item) in gridItems.enumerated() {
            switch item {
            case .fixed(let width):
                widths[index] = width
                remainingWidth -= width
            case .flexible, .adaptive:
                flexibleIndices.append(index)
            }
        }
        
        // Second pass: distribute remaining width to flexible columns
        if !flexibleIndices.isEmpty && remainingWidth > 0 {
            let flexWidth = remainingWidth / Float(flexibleIndices.count)
            for index in flexibleIndices {
                switch gridItems[index] {
                case .flexible(let minimum, let maximum):
                    widths[index] = min(maximum, max(minimum, flexWidth))
                case .adaptive(let minimum):
                    widths[index] = max(minimum, flexWidth)
                default:
                    break
                }
            }
        }
        
        return widths
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        guard !children.isEmpty else { return .zero }
        
        let totalWidth = proposal.width ?? 200
        let columnWidths = calculateColumnWidths(totalWidth: totalWidth)
        let columnCount = gridItems.count
        let rows = (children.count + columnCount - 1) / columnCount
        
        // Calculate row heights
        var rowHeights = [Float](repeating: 0, count: rows)
        for (index, child) in children.enumerated() {
            let row = index / columnCount
            let col = index % columnCount
            let childSize = child.sizeThatFits(ProposedSize(width: columnWidths[col], height: nil))
            rowHeights[row] = max(rowHeights[row], childSize.height)
        }
        
        let totalHeight = rowHeights.reduce(0, +) + Float(rows - 1) * verticalSpacing
        return Size(width: totalWidth, height: totalHeight)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        guard !children.isEmpty else { return }
        
        let columnWidths = calculateColumnWidths(totalWidth: bounds.width)
        let columnCount = gridItems.count
        let rows = (children.count + columnCount - 1) / columnCount
        
        // Calculate row heights
        var rowHeights = [Float](repeating: 0, count: rows)
        for (index, child) in children.enumerated() {
            let row = index / columnCount
            let col = index % columnCount
            let childSize = child.sizeThatFits(ProposedSize(width: columnWidths[col], height: nil))
            rowHeights[row] = max(rowHeights[row], childSize.height)
        }
        
        // Render children
        var currentY = bounds.y
        for row in 0..<rows {
            var currentX = bounds.x
            for col in 0..<columnCount {
                let index = row * columnCount + col
                guard index < children.count else { break }
                
                let child = children[index]
                let cellWidth = columnWidths[col]
                let cellHeight = rowHeights[row]
                
                let childBounds = UIRect(
                    x: currentX,
                    y: currentY,
                    width: cellWidth,
                    height: cellHeight
                )
                
                child.render(in: childBounds, context: context)
                currentX += cellWidth + spacing
            }
            currentY += rowHeights[row] + verticalSpacing
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        guard !children.isEmpty else { return false }
        
        let columnWidths = calculateColumnWidths(totalWidth: bounds.width)
        let columnCount = gridItems.count
        let rows = (children.count + columnCount - 1) / columnCount
        
        var rowHeights = [Float](repeating: 0, count: rows)
        for (index, child) in children.enumerated() {
            let row = index / columnCount
            let col = index % columnCount
            let childSize = child.sizeThatFits(ProposedSize(width: columnWidths[col], height: nil))
            rowHeights[row] = max(rowHeights[row], childSize.height)
        }
        
        var currentY = bounds.y
        for row in 0..<rows {
            var currentX = bounds.x
            for col in 0..<columnCount {
                let index = row * columnCount + col
                guard index < children.count else { break }
                
                let child = children[index]
                let cellWidth = columnWidths[col]
                let cellHeight = rowHeights[row]
                
                let childBounds = UIRect(x: currentX, y: currentY, width: cellWidth, height: cellHeight)
                
                if child.handleMouse(event, in: childBounds) {
                    return true
                }
                currentX += cellWidth + spacing
            }
            currentY += rowHeights[row] + verticalSpacing
        }
        
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        for child in children {
            if child.handleKeyboard(event) {
                return true
            }
        }
        return false
    }
}
