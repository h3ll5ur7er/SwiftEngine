import GameEngine

/// A comprehensive catalog demo scene showcasing all UI components
@MainActor
class UICatalogScene: GameObjectScene {
    private var uiRoot: UIRoot!
    
    // State for controls
    private var textFieldValue = "Hello"
    private var sliderValue: Float = 0.5
    private var toggleValue = true
    private var checkboxValue = false
    private var dropdownIndex = 0
    private var scrollOffset: Float = 0
    private var counter = 0
    private var counterText: Text?
    
    // Display texts for inputs tab
    private var textFieldDisplayText: Text?
    private var sliderDisplayText: Text?
    private var toggleDisplayText: Text?
    private var checkboxDisplayText: Text?
    private var dropdownDisplayText: Text?
    
    // Theme selection
    private var themeIndex = 0
    private let themes: [(String, Theme)] = [
        ("Dark", Theme.dark),
        ("Light", Theme.light),
        ("High Contrast", Theme.highContrastDark),
        ("Cyberpunk", Theme.cyberpunk),
        ("Forest", Theme.forest),
        ("Ocean", Theme.ocean)
    ]
    
    public override func onLoad(engine: Engine) {
        super.onLoad(engine: engine)
        buildUI()
    }
    
    private func buildUI() {
        uiRoot = UIRoot {
            VStack(spacing: 10) {
                // Header
                self.buildHeader()
                
                // Tab Panel with all categories
                TabPanel {
                    TabPanel.Tab("Text") {
                        ScrollView {
                            self.buildTextTab()
                        }
                    }
                    TabPanel.Tab("Buttons") {
                        ScrollView {
                            self.buildButtonsTab()
                        }
                    }
                    TabPanel.Tab("Inputs") {
                        ScrollView {
                            self.buildInputsTab()
                        }
                    }
                    TabPanel.Tab("Layout") {
                        ScrollView {
                            self.buildLayoutTab()
                        }
                    }
                    TabPanel.Tab("Containers") {
                        ScrollView {
                            self.buildContainersTab()
                        }
                    }
                    TabPanel.Tab("Theme") {
                        ScrollView {
                            self.buildThemeTab()
                        }
                    }
                }
                .tabStyle(
                    background: ThemeManager.shared.current.surfaceBackground,
                    backgroundSelected: ThemeManager.shared.current.elevatedBackground,
                    indicatorColor: ThemeManager.shared.current.primary
                )
                .contentBackground(ThemeManager.shared.current.background)
                .frame(width: 750, height: 480)
            }
            .padding(20)
        }
    }
    
    // MARK: - Header
    
    private func buildHeader() -> some View {
        let theme = ThemeManager.shared.current
        return HStack(spacing: 20) {
            Text("UI Component Catalog")
                .color(theme.primary)
            
            Spacer()
            
            Text("Theme:")
                .color(theme.textSecondary)
            
            Button("<") {
                self.previousTheme()
            }
            .foregroundColor(theme.textPrimary)
            .background(theme.buttonBackground)
            
            Text(self.themes[self.themeIndex].0)
                .color(theme.textPrimary)
            
            Button(">") {
                self.nextTheme()
            }
            .foregroundColor(theme.textPrimary)
            .background(theme.buttonBackground)
        }
    }
    
    // MARK: - Text Tab
    
    private func buildTextTab() -> some View {
        let theme = ThemeManager.shared.current
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Text Component")
            
            Text("Basic text rendering with bitmap font")
                .color(theme.textPrimary)
            
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Default text")
                        .color(theme.textPrimary)
                    Text("Primary color")
                        .color(theme.primary)
                    Text("Secondary text")
                        .color(theme.textSecondary)
                    Text("Success color")
                        .color(theme.success)
                    Text("Warning color")
                        .color(theme.warning)
                    Text("Error color")
                        .color(theme.error)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("With opacity 100%")
                        .color(theme.textPrimary)
                        .opacity(1.0)
                    Text("With opacity 75%")
                        .color(theme.textPrimary)
                        .opacity(0.75)
                    Text("With opacity 50%")
                        .color(theme.textPrimary)
                        .opacity(0.5)
                    Text("With opacity 25%")
                        .color(theme.textPrimary)
                        .opacity(0.25)
                }
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Divider Component")
            
            Text("Horizontal dividers:")
                .color(theme.textSecondary)
            Divider().color(theme.primary).thickness(1)
            Divider().color(theme.success).thickness(2)
            Divider().color(theme.warning).thickness(3)
        }
        .padding(15)
    }
    
    // MARK: - Buttons Tab
    
    private func buildButtonsTab() -> some View {
        let theme = ThemeManager.shared.current
        
        // Create counter text outside ViewBuilder context
        let countText = Text("Count: \(self.counter)")
            .color(theme.primary)
        self.counterText = countText
        
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Button Styles")
            
            HStack(spacing: 10) {
                ThemedButton("Primary", style: .primary, action: {
                    self.counter += 1
                })
                ThemedButton("Secondary", style: .secondary, action: {
                    self.counter += 1
                })
                Button("Custom", action: { })
                    .foregroundColor(.black)
                    .background(theme.primary)
                    .padding(8)
                    .cornerRadius(4)
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Button Colors")
            
            HStack(spacing: 10) {
                Button("Success", action: { })
                    .foregroundColor(.white)
                    .background(theme.success)
                    .padding(8)
                
                Button("Warning", action: { })
                    .foregroundColor(.black)
                    .background(theme.warning)
                    .padding(8)
                
                Button("Error", action: { })
                    .foregroundColor(.white)
                    .background(theme.error)
                    .padding(8)
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Interactive Demo")
            
            HStack(spacing: 20) {
                Button("-5") {
                    self.counter -= 5
                    self.counterText?.content = "Count: \(self.counter)"
                }
                    .foregroundColor(theme.textPrimary)
                    .background(theme.buttonBackground)
                    .padding(8)
                
                Button("-1") {
                    self.counter -= 1
                    self.counterText?.content = "Count: \(self.counter)"
                }
                    .foregroundColor(theme.textPrimary)
                    .background(theme.buttonBackground)
                    .padding(8)
                
                countText
                
                Button("+1") {
                    self.counter += 1
                    self.counterText?.content = "Count: \(self.counter)"
                }
                    .foregroundColor(theme.textPrimary)
                    .background(theme.buttonBackground)
                    .padding(8)
                
                Button("+5") {
                    self.counter += 5
                    self.counterText?.content = "Count: \(self.counter)"
                }
                    .foregroundColor(theme.textPrimary)
                    .background(theme.buttonBackground)
                    .padding(8)
            }
        }
        .padding(15)
    }
    
    // MARK: - Inputs Tab
    
    private func buildInputsTab() -> some View {
        let theme = ThemeManager.shared.current
        
        // Create display texts outside ViewBuilder context
        let tfDisplay = Text("Value: \(self.textFieldValue)")
            .color(theme.textPrimary)
        self.textFieldDisplayText = tfDisplay
        
        let sliderDisplay = Text(String(format: "%.2f", self.sliderValue))
            .color(theme.textPrimary)
        self.sliderDisplayText = sliderDisplay
        
        let toggleDisplay = Text(self.toggleValue ? "ON" : "OFF")
            .color(self.toggleValue ? theme.success : theme.error)
        self.toggleDisplayText = toggleDisplay
        
        let checkboxDisplay = Text(self.checkboxValue ? "Checked" : "Unchecked")
            .color(theme.textPrimary)
        self.checkboxDisplayText = checkboxDisplay
        
        let dropdownDisplay = Text("Selected: \(self.dropdownIndex)")
            .color(theme.textPrimary)
        self.dropdownDisplayText = dropdownDisplay
        
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("TextField")
            
            HStack(spacing: 15) {
                Text("Text:")
                    .color(theme.textSecondary)
                TextField(text: self.textFieldBinding, placeholder: "Enter text...")
                    .frame(width: 200, height: 28)
                tfDisplay
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Slider")
            
            HStack(spacing: 15) {
                Text("Value:")
                    .color(theme.textSecondary)
                Slider(value: self.sliderBinding, range: 0...1)
                    .trackColor(theme.sliderTrack)
                    .fillColor(theme.sliderFill)
                    .frame(width: 200, height: 20)
                sliderDisplay
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Toggle")
            
            HStack(spacing: 15) {
                Text("Enabled:")
                    .color(theme.textSecondary)
                Toggle(isOn: self.toggleBinding)
                toggleDisplay
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Checkbox")
            
            HStack(spacing: 15) {
                Checkbox(isChecked: self.checkboxBinding)
                checkboxDisplay
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("ProgressBar")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text("25%:")
                        .color(theme.textSecondary)
                    ProgressBar(progress: 0.25)
                        .frame(width: 200, height: 16)
                }
                HStack(spacing: 10) {
                    Text("50%:")
                        .color(theme.textSecondary)
                    ProgressBar(progress: 0.50)
                        .fillColor(theme.warning)
                        .frame(width: 200, height: 16)
                }
                HStack(spacing: 10) {
                    Text("75%:")
                        .color(theme.textSecondary)
                    ProgressBar(progress: 0.75)
                        .fillColor(theme.success)
                        .frame(width: 200, height: 16)
                }
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Dropdown")
            
            HStack(spacing: 15) {
                Text("Select:")
                    .color(theme.textSecondary)
                Dropdown(
                    options: ["Option A", "Option B", "Option C", "Option D"],
                    selectedIndex: self.dropdownBinding
                )
                .frame(width: 150, height: 28)
                dropdownDisplay
            }
        }
        .padding(15)
    }
    
    // MARK: - Layout Tab
    
    private func buildLayoutTab() -> some View {
        let theme = ThemeManager.shared.current
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("HStack (Horizontal)")
            
            HStack(spacing: 10) {
                colorBox(theme.error, "R")
                colorBox(theme.warning, "Y")
                colorBox(theme.success, "G")
                colorBox(theme.primary, "B")
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("VStack (Vertical)")
            
            HStack(spacing: 20) {
                VStack(spacing: 5) {
                    colorBox(theme.error, "1")
                    colorBox(theme.warning, "2")
                    colorBox(theme.success, "3")
                }
                
                Text("Alignment options:\n.leading\n.center\n.trailing")
                    .color(theme.textSecondary)
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("ZStack (Overlay)")
            
            ZStack {
                UIRectangle().fill(theme.primary.darker(by: 0.5))
                    .frame(width: 100, height: 60)
                UIRectangle().fill(theme.primary.darker(by: 0.25))
                    .frame(width: 70, height: 40)
                UIRectangle().fill(theme.primary)
                    .frame(width: 40, height: 20)
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Spacer")
            
            HStack(spacing: 5) {
                Text("Left")
                    .color(theme.textPrimary)
                    .background(theme.surfaceBackground)
                    .padding(5)
                Spacer()
                Text("Right")
                    .color(theme.textPrimary)
                    .background(theme.surfaceBackground)
                    .padding(5)
            }
            .frame(width: 300, height: 30)
            .background(theme.elevatedBackground)
        }
        .padding(15)
    }
    
    // MARK: - Containers Tab
    
    private func buildContainersTab() -> some View {
        let theme = ThemeManager.shared.current
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Grid")
            
            Grid(columns: 4, horizontalSpacing: 5, verticalSpacing: 5) {
                ForEach(0..<8) { i in
                    UIRectangle().fill(theme.primary.lighter(by: Float(i) * 0.1))
                        .frame(width: 40, height: 40)
                }
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("LazyVGrid")
            
            LazyVGrid(columns: [.fixed(50), .fixed(50), .fixed(50), .fixed(50)], spacing: 5) {
                ForEach(0..<8) { i in
                    Text("\(i + 1)")
                        .color(theme.textPrimary)
                        .background(theme.surfaceBackground)
                        .padding(10)
                }
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("ScrollView")
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<10) { i in
                        Text("Scrollable item \(i + 1)")
                            .color(theme.textPrimary)
                            .background(theme.elevatedBackground)
                            .padding(8)
                    }
                }
            }
            .frame(width: 200, height: 120)
            .background(theme.surfaceBackground)
            
            Divider().color(theme.divider)
            
            sectionHeader("TabPanel")
            
            Text("You're using one right now!")
                .color(theme.primary)
        }
        .padding(15)
    }
    
    // MARK: - Theme Tab
    
    private func buildThemeTab() -> some View {
        let theme = ThemeManager.shared.current
        return VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Current Theme: \(themes[themeIndex].0)")
            
            Divider().color(theme.divider)
            
            sectionHeader("Background Colors")
            HStack(spacing: 10) {
                colorSwatch(theme.background, "Background")
                colorSwatch(theme.surfaceBackground, "Surface")
                colorSwatch(theme.elevatedBackground, "Elevated")
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Text Colors")
            HStack(spacing: 10) {
                colorSwatch(theme.textPrimary, "Primary")
                colorSwatch(theme.textSecondary, "Secondary")
                colorSwatch(theme.primary, "Accent")
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Semantic Colors")
            HStack(spacing: 10) {
                colorSwatch(theme.success, "Success")
                colorSwatch(theme.warning, "Warning")
                colorSwatch(theme.error, "Error")
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("UI Element Colors")
            HStack(spacing: 10) {
                colorSwatch(theme.buttonBackground, "Button BG")
                colorSwatch(theme.buttonBackgroundHover, "Btn Hover")
                colorSwatch(theme.border, "Border")
            }
            
            Divider().color(theme.divider)
            
            sectionHeader("Available Themes")
            HStack(spacing: 8) {
                ForEach(0..<themes.count) { i in
                    Button(self.themes[i].0) {
                        self.themeIndex = i
                        ThemeManager.shared.current = self.themes[i].1
                        self.buildUI()
                    }
                    .foregroundColor(i == self.themeIndex ? .black : theme.textPrimary)
                    .background(i == self.themeIndex ? theme.primary : theme.buttonBackground)
                    .padding(6)
                }
            }
        }
        .padding(15)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> any View {
        let theme = ThemeManager.shared.current
        return Text("▸ \(title)")
            .color(theme.primary)
    }
    
    private func colorBox(_ color: Color, _ label: String) -> any View {
        let theme = ThemeManager.shared.current
        let rect = UIRectangle().fill(color).frame(width: 40, height: 40) as any View
        let text = Text(label).color(theme.textPrimary) as any View
        return ZStack(children: [rect, text])
    }
    
    private func colorSwatch(_ color: Color, _ name: String) -> any View {
        let theme = ThemeManager.shared.current
        let rect = UIRectangle().fill(color).frame(width: 60, height: 30) as any View
        let text = Text(name).color(theme.textSecondary) as any View
        return VStack(spacing: 4, children: [rect, text])
    }
    
    // MARK: - Theme Navigation
    
    private func nextTheme() {
        themeIndex = (themeIndex + 1) % themes.count
        ThemeManager.shared.current = themes[themeIndex].1
        buildUI()
    }
    
    private func previousTheme() {
        themeIndex = (themeIndex - 1 + themes.count) % themes.count
        ThemeManager.shared.current = themes[themeIndex].1
        buildUI()
    }
    
    // MARK: - Bindings
    
    private var textFieldBinding: Binding<String> {
        Binding(
            get: { self.textFieldValue },
            set: {
                self.textFieldValue = $0
                self.textFieldDisplayText?.content = "Value: \($0)"
            }
        )
    }
    
    private var sliderBinding: Binding<Float> {
        Binding(
            get: { self.sliderValue },
            set: {
                self.sliderValue = $0
                self.sliderDisplayText?.content = String(format: "%.2f", $0)
            }
        )
    }
    
    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { self.toggleValue },
            set: {
                self.toggleValue = $0
                self.toggleDisplayText?.content = $0 ? "ON" : "OFF"
                let theme = ThemeManager.shared.current
                self.toggleDisplayText?.color = $0 ? theme.success : theme.error
            }
        )
    }
    
    private var checkboxBinding: Binding<Bool> {
        Binding(
            get: { self.checkboxValue },
            set: {
                self.checkboxValue = $0
                self.checkboxDisplayText?.content = $0 ? "Checked" : "Unchecked"
            }
        )
    }
    
    private var dropdownBinding: Binding<Int> {
        Binding(
            get: { self.dropdownIndex },
            set: {
                self.dropdownIndex = $0
                self.dropdownDisplayText?.content = "Selected: \($0)"
            }
        )
    }
    
    // MARK: - Scene Lifecycle
    
    public override func update(context: FrameContext, input: Input) {
        super.update(context: context, input: input)
    }
    
    public override func render(context: RenderContext) {
        context.renderer.clear(ThemeManager.shared.current.background)
        
        // Handle UI input
        if let engine = engine {
            uiRoot.handleInput(engine.input, screenWidth: Float(context.width), screenHeight: Float(context.height))
        }
        
        uiRoot.render(context)
    }
}


