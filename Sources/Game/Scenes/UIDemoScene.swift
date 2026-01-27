import GameEngine

// MARK: - Demo ViewModel

/// A simple view model demonstrating reactive state
@MainActor
final class DemoViewModel: ViewModel {
    var counter: Int = 0 {
        didSet { notifyChange() }
    }
    
    var items: [String] = ["Apple", "Banana", "Cherry", "Date", "Elderberry"] {
        didSet { notifyChange() }
    }
    
    var currentThemeIndex: Int = 0 {
        didSet { notifyChange() }
    }
    
    let themes: [(String, Theme)] = [
        ("Dark", .dark),
        ("Light", .light),
        ("Cyberpunk", .cyberpunk),
        ("Forest", .forest),
        ("Ocean", .ocean)
    ]
    
    func increment() {
        counter += 1
    }
    
    func decrement() {
        if counter > 0 { counter -= 1 }
    }
    
    func nextTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % themes.count
        ThemeManager.shared.setTheme(themes[currentThemeIndex].1)
    }
    
    func previousTheme() {
        currentThemeIndex = (currentThemeIndex - 1 + themes.count) % themes.count
        ThemeManager.shared.setTheme(themes[currentThemeIndex].1)
    }
    
    var currentThemeName: String {
        themes[currentThemeIndex].0
    }
}

/// Demo scene showcasing the UI framework
@MainActor
public final class UIDemoScene: GameObjectScene {
    
    private var ui: UIRoot!
    private var viewModel: DemoViewModel!
    
    // UI elements that need updating
    private var counterText: Text!
    private var itemCountText: Text!
    private var themeNameText: Text!
    
    // Theme-dependent elements
    private var titleText: Text!
    private var subtitleText: Text!
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        
        // Create view model
        viewModel = DemoViewModel()
        
        let theme = ThemeManager.shared.current
        
        // Create dynamic text elements
        counterText = Text("0")
            .foregroundColor(theme.primary)
            .fontSize(2)
        
        itemCountText = Text("5 items")
            .foregroundColor(theme.textSecondary)
        
        themeNameText = Text("Dark")
            .foregroundColor(theme.primary)
            .fontSize(1)
        
        titleText = Text("UI Framework Demo")
            .foregroundColor(theme.textPrimary)
            .fontSize(2)
        
        subtitleText = Text("Phase 5: Theming")
            .foregroundColor(theme.textSecondary)
        
        // Observe view model changes
        viewModel.onChanged { [weak self] in
            self?.updateUI()
        }
        
        // Observe theme changes
        ThemeManager.shared.onThemeChanged { [weak self] in
            self?.applyTheme()
        }
        
        buildUI()
    }
    
    private func buildUI() {
        let theme = ThemeManager.shared.current
        
        // Build the UI
        ui = UIRoot(padding: EdgeInsets(16)) {
            VStack(alignment: .center, spacing: 10, children: [
                // Title
                titleText!,
                subtitleText!,
                
                Divider().color(theme.divider),
                
                // === Theme Selector ===
                HStack(spacing: 12, children: [
                    Text("Theme:").foregroundColor(theme.textSecondary),
                    
                    Button("<") { [weak self] in
                        self?.viewModel.previousTheme()
                    }
                    .backgroundColor(theme.surfaceBackground)
                    .foregroundColor(theme.textPrimary)
                    .padding(6),
                    
                    themeNameText!.frame(width: 80, height: 20),
                    
                    Button(">") { [weak self] in
                        self?.viewModel.nextTheme()
                    }
                    .backgroundColor(theme.surfaceBackground)
                    .foregroundColor(theme.textPrimary)
                    .padding(6)
                ])
                .padding(8)
                .background(theme.elevatedBackground),
                
                Divider().color(theme.divider),
                
                // === Main Content ===
                HStack(alignment: .top, spacing: 16, children: [
                    // Left - Counter
                    VStack(alignment: .center, spacing: 8, children: [
                        Text("Counter").foregroundColor(theme.secondary),
                        counterText!,
                        HStack(spacing: 8, children: [
                            Button("-") { [weak self] in
                                self?.viewModel.decrement()
                            }
                            .backgroundColor(theme.error)
                            .padding(8),
                            
                            Button("+") { [weak self] in
                                self?.viewModel.increment()
                            }
                            .backgroundColor(theme.success)
                            .padding(8)
                        ])
                    ])
                    .padding(12)
                    .background(theme.surfaceBackground)
                    .frame(width: 120, height: 130),
                    
                    // Middle - List
                    VStack(alignment: .leading, spacing: 6, children: [
                        Text("Items").foregroundColor(theme.secondary),
                        itemCountText!,
                        
                        ScrollView(content:
                            VStack(alignment: .leading, spacing: 4, children:
                                viewModel.items.enumerated().map { index, item in
                                    Text("\(index + 1). \(item)").foregroundColor(theme.textPrimary)
                                }
                            )
                        )
                        .showsIndicators(vertical: true)
                        .indicatorStyle(color: theme.scrollbarThumb, width: 6)
                        .frame(width: 120, height: 70)
                        .background(theme.elevatedBackground)
                    ])
                    .padding(12)
                    .background(theme.surfaceBackground),
                    
                    // Right - Color Palette
                    VStack(alignment: .center, spacing: 8, children: [
                        Text("Theme Colors").foregroundColor(theme.secondary),
                        
                        Grid(columns: 2, horizontalSpacing: 4, verticalSpacing: 4, children: [
                            colorSwatch("Primary", theme.primary),
                            colorSwatch("Secondary", theme.secondary),
                            colorSwatch("Success", theme.success),
                            colorSwatch("Warning", theme.warning),
                            colorSwatch("Error", theme.error),
                            colorSwatch("Info", theme.info)
                        ])
                    ])
                    .padding(12)
                    .background(theme.surfaceBackground)
                ]),
                
                Divider().color(theme.divider),
                
                // === Controls Row ===
                HStack(spacing: 16, children: [
                    Toggle("Feature", isOn: true)
                        .onColor(theme.success),
                    
                    Checkbox("Option", isChecked: true)
                        .checkColor(theme.primary),
                    
                    Button("Action") { }
                        .backgroundColor(theme.primary)
                        .foregroundColor(theme.textOnPrimary)
                        .padding(8)
                ]),
                
                Spacer(),
                
                // Footer
                Text("Use < > to cycle through themes")
                    .foregroundColor(theme.textDisabled)
            ])
        }
    }
    
    private func colorSwatch(_ name: String, _ color: Color) -> VStack {
        VStack(spacing: 2, children: [
            UIRectangle().fill(color).frame(width: 50, height: 20),
            Text(name).foregroundColor(ThemeManager.shared.current.textSecondary)
        ])
    }
    
    /// Update UI elements based on view model state
    private func updateUI() {
        
        // Update counter display
        counterText.content = "\(viewModel.counter)"
        
        // Update item count
        itemCountText.content = "\(viewModel.items.count) items"
        
        // Update theme name
        themeNameText.content = viewModel.currentThemeName
    }
    
    /// Apply current theme to UI elements
    private func applyTheme() {
        let theme = ThemeManager.shared.current
        
        // Update colors based on new theme
        counterText.color = theme.primary
        itemCountText.color = theme.textSecondary
        themeNameText.color = theme.primary
        titleText.color = theme.textPrimary
        subtitleText.color = theme.textSecondary
        
        // Rebuild UI to apply theme to all components
        buildUI()
    }
    
    public override func update(context: FrameContext, input: Input) {
        super.update(context: context, input: input)
    }
    
    public override func render(context: RenderContext) {
        let theme = ThemeManager.shared.current
        
        // Clear with theme background
        context.renderer.clear(theme.background)
        
        // Handle UI input
        if let engine = engine {
            ui.handleInput(engine.input, screenWidth: Float(context.width), screenHeight: Float(context.height))
        }
        
        // Render UI
        ui.render(context)
    }
}
