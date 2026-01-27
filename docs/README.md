# GameEngine Documentation

A lightweight, software-rendered 3D game engine written in Swift for Windows.

```
   ___                      ___             _            
  / _ \__ _ _ __ ___   ___ / _ \_ __   __ _(_)_ __   ___ 
 / /_\/ _` | '_ ` _ \ / _ \ /_)/| '_ \ / _` | | '_ \ / _ \
/ /_\\ (_| | | | | | |  __/ / _ \ | | | (_| | | | | |  __/
\____/\__,_|_| |_| |_|\___\_| \_/_| |_|\__, |_|_| |_|\___|
                                       |___/              
```

## Overview

GameEngine is a component-based game framework featuring:

- **GameObject/Component Architecture** - Unity-style entity system
- **Software 3D Rendering** - No GPU required, runs everywhere
- **Built-in Primitives** - Cubes, planes, quads out of the box
- **Material System** - Colors, textures, and shading models
- **Lighting** - Directional and ambient lights
- **Camera System** - Perspective and orthographic projections

## Quick Start

```swift
import GameEngine

@main
@MainActor
struct MyGame {
    static func main() {
        let config = EngineConfig(
            title: "My Game",
            width: 800,
            height: 600
        )
        
        let engine = Engine(config: config)
        engine.loadScene(MyScene())
        engine.run()
    }
}
```

## Documentation Structure

```
docs/
├── README.md                    ← You are here
├── getting-started.md           ← Installation and first scene
├── architecture/
│   ├── overview.md              ← System architecture
│   └── game-loop.md             ← Frame lifecycle
├── core/
│   ├── gameobject-component.md  ← Entity-component system
│   ├── transform.md             ← Position, rotation, scale
│   └── scenes.md                ← Scene management
├── graphics/
│   ├── math.md                  ← Vectors, matrices, quaternions
│   ├── rendering.md             ← Render pipeline
│   ├── materials.md             ← Materials and shading
│   └── meshes.md                ← Mesh system and primitives
├── components/
│   ├── camera.md                ← Camera component
│   ├── mesh-renderer.md         ← Rendering meshes
│   ├── lights.md                ← Lighting system
│   └── built-in.md              ← PlayerController, Rotator
├── ui/
│   ├── overview.md              ← UI framework introduction
│   ├── containers.md            ← VStack, HStack, Grid, TabPanel
│   ├── views.md                 ← Text, Spacer, Divider, ForEach
│   ├── controls.md              ← Button, TextField, Slider, etc.
│   ├── theming.md               ← Theme system and customization
│   ├── state.md                 ← Bindings and state management
│   └── overlay.md               ← UIOverlay component for GameObjects
└── examples/
    ├── basic-scene.md           ← Complete scene example
    └── custom-components.md     ← Creating your own components
```

## Module Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Game                                        │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Your Scenes, Custom Components, Game Logic                        │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                │                                         │
│                         import GameEngine                                │
│                                ▼                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                           GameEngine                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Engine  │  │ Graphics │  │ Platform │  │Components│  │    UI    │  │
│  │          │  │          │  │          │  │          │  │          │  │
│  │ Engine   │  │ Color    │  │ Window   │  │ Camera   │  │ UIRoot   │  │
│  │ Config   │  │ Vec/Mat  │  │ Input    │  │ Mesh     │  │ View     │  │
│  │ Component│  │ Renderer │  │ Backbuff │  │ Renderer │  │ VStack   │  │
│  │ GameObject│ │ Pipeline │  │ Keys     │  │ Lights   │  │ HStack   │  │
│  │ Transform│  │ Material │  │          │  │ Rotator  │  │ Button   │  │
│  │ Scene    │  │ Mesh     │  │          │  │ Player   │  │ TabPanel │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Requirements

- Swift 6.0+
- Windows 10/11
- Visual Studio 2022 Build Tools

## Building

```powershell
# Debug build
.\build.ps1 build

# Release build  
.\build.ps1 build-release

# Run game
.\build.ps1 run-release

# Run tests
.\build.ps1 test
```

## License

MIT License - See LICENSE file for details.
