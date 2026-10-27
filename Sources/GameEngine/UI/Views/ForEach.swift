

/// A view that creates views from a collection of data
@MainActor
public final class ForEach<Data: RandomAccessCollection>: View, ViewChildrenProvider where Data.Index == Int {
    
    private let data: Data
    private let content: (Data.Element) -> any View
    private var cachedViews: [any View]?
    
    public init(_ data: Data, @SingleViewBuilder content: @escaping (Data.Element) -> any View) {
        self.data = data
        self.content = content
    }
    
    /// Get all generated views (for container inspection)
    public func getViews() -> [any View] {
        if let cached = cachedViews {
            return cached
        }
        let views = data.map { content($0) }
        cachedViews = views
        return views
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Inside a view builder, containers receive the individual children instead.
        // Standalone, the children are stacked vertically (matching render)
        var width: Float = 0
        var height: Float = 0
        for view in getViews() {
            let size = view.sizeThatFits(ProposedSize(width: proposal.width, height: nil))
            width = max(width, size.width)
            height += size.height
        }
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        // ForEach doesn't render directly - it provides children to containers
        // This is a fallback if used standalone
        var y = bounds.y
        for view in getViews() {
            let size = view.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let viewBounds = UIRect(x: bounds.x, y: y, width: bounds.width, height: size.height)
            view.render(in: viewBounds, context: context)
            y += size.height
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        var y = bounds.y
        for view in getViews() {
            let size = view.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let viewBounds = UIRect(x: bounds.x, y: y, width: bounds.width, height: size.height)
            if view.handleMouse(event, in: viewBounds) {
                return true
            }
            y += size.height
        }
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        for view in getViews() {
            if view.handleKeyboard(event) {
                return true
            }
        }
        return false
    }
    
    /// Get the child views for use in containers
    public func children() -> [any View] {
        return getViews()
    }
}

// MARK: - Identifiable ForEach

/// ForEach for identifiable data
@MainActor
public final class ForEachIdentifiable<Data: RandomAccessCollection, ID: Hashable>: View, ViewChildrenProvider {
    
    private let data: Data
    private let idKeyPath: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> any View
    
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @SingleViewBuilder content: @escaping (Data.Element) -> any View) {
        self.data = data
        self.idKeyPath = id
        self.content = content
    }
    
    public func sizeThatFits(_ proposal: ProposedSize) -> Size {
        // Standalone, the children are stacked vertically (matching render)
        var width: Float = 0
        var height: Float = 0
        for element in data {
            let size = content(element).sizeThatFits(ProposedSize(width: proposal.width, height: nil))
            width = max(width, size.width)
            height += size.height
        }
        return Size(width: width, height: height)
    }
    
    public func render(in bounds: UIRect, context: UIRenderContext) {
        var y = bounds.y
        for element in data {
            let view = content(element)
            let size = view.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let viewBounds = UIRect(x: bounds.x, y: y, width: bounds.width, height: size.height)
            view.render(in: viewBounds, context: context)
            y += size.height
        }
    }
    
    public func handleMouse(_ event: MouseEvent, in bounds: UIRect) -> Bool {
        var y = bounds.y
        for element in data {
            let view = content(element)
            let size = view.sizeThatFits(ProposedSize(width: bounds.width, height: nil))
            let viewBounds = UIRect(x: bounds.x, y: y, width: bounds.width, height: size.height)
            if view.handleMouse(event, in: viewBounds) {
                return true
            }
            y += size.height
        }
        return false
    }
    
    public func handleKeyboard(_ event: KeyboardEvent) -> Bool {
        for element in data {
            if content(element).handleKeyboard(event) {
                return true
            }
        }
        return false
    }
    
    /// Get the child views for use in containers
    public func children() -> [any View] {
        return data.map { content($0) }
    }
}
