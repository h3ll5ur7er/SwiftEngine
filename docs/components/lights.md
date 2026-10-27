# Lighting System

GameEngine provides directional and ambient lighting for illuminating your 3D scenes.

## Light Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LIGHTING SYSTEM                                  │
│                                                                          │
│  ┌─────────────────────────┐    ┌─────────────────────────┐            │
│  │    DirectionalLight     │    │      AmbientLight       │            │
│  │                         │    │                         │            │
│  │  ☀ ───────────────▶     │    │    ░░░░░░░░░░░░░░░░    │            │
│  │                         │    │    ░░░░░░░░░░░░░░░░    │            │
│  │  Parallel rays          │    │    ░░░░░░░░░░░░░░░░    │            │
│  │  Like the sun           │    │    ░░░░░░░░░░░░░░░░    │            │
│  │  Casts shadows (future) │    │                         │            │
│  │                         │    │  Even illumination      │            │
│  │  direction: Vec3d       │    │  everywhere             │            │
│  │  intensity: Float       │    │                         │            │
│  │  color: Color           │    │  intensity: Float       │            │
│  │                         │    │  color: Color           │            │
│  └─────────────────────────┘    └─────────────────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## DirectionalLight

Simulates distant light sources like the sun - all rays are parallel.

### Setup

```swift
let lightObject = createGameObject(name: "Sun")

let sun = lightObject.addComponent(DirectionalLight.self)
sun.direction = Vec3d(0.5, 1.0, 0.3)  // Points toward the light
sun.intensity = 1.0
sun.color = .white
```

### Properties

```swift
// Direction the light comes FROM (normalized automatically)
sun.direction = Vec3d(1, 1, 0)  // Becomes (0.707, 0.707, 0)

// Light brightness (0 to 1+, can exceed 1 for HDR)
sun.intensity = 1.0

// Light color (tints surfaces)
sun.color = Color(r: 255, g: 240, b: 220)  // Warm sunlight
sun.color = Color(r: 200, g: 200, b: 255)  // Cool moonlight

// Future feature
sun.castsShadows = true
```

### Static Access

```swift
// Get the primary directional light
if let mainLight = DirectionalLight.main {
    print("Light direction: \(mainLight.direction)")
}

// Get all directional lights
let allLights = DirectionalLight.all
```

### Visual Effect

```
Light Direction →

         ┌────────────┐
         │████████████│ ← Facing light (bright)
         │████████████│
         │            │
         │▒▒▒▒▒▒▒▒▒▒▒▒│ ← Angled (medium)
         │▒▒▒▒▒▒▒▒▒▒▒▒│
         │            │
         │░░░░░░░░░░░░│ ← Away from light (dark)
         │░░░░░░░░░░░░│
         └────────────┘

Brightness = max(0, dot(normal, lightDirection)) × intensity
```

## AmbientLight

Provides uniform base illumination - prevents completely black shadows. Without an `AmbientLight` component, the renderer uses a default ambient intensity of `0.1` (`AmbientLight.defaultIntensity`) with white color.

### Setup

```swift
let lightObject = createGameObject(name: "Environment")

let ambient = lightObject.addComponent(AmbientLight.self)
ambient.intensity = 0.2  // 20% base illumination
ambient.color = .white
```

### Properties

```swift
// Base illumination level (0 to 1)
ambient.intensity = 0.3  // 30% minimum brightness

// Tint all surfaces
ambient.color = Color(r: 100, g: 100, b: 150)  // Bluish ambient (indoor)
ambient.color = Color(r: 150, g: 140, b: 120)  // Warm ambient (sunset)
```

### Static Access

```swift
// Get current ambient light
if let ambient = AmbientLight.current {
    print("Ambient intensity: \(ambient.intensity)")
}

// Use defaults if no component
let intensity = AmbientLight.effectiveIntensity  // Returns 0.1 if no component
let color = AmbientLight.effectiveColor          // Returns .white if no component
```

### Visual Effect

```
No AmbientLight (default 0.1):  With Ambient Light (0.3):

         ┌────────────┐              ┌────────────┐
         │████████████│              │████████████│
         │████████████│              │████████████│
         │            │              │            │
         │▒▒▒▒▒▒▒▒▒▒▒▒│              │▒▒▒▒▒▒▒▒▒▒▒▒│
         │▒▒▒▒▒▒▒▒▒▒▒▒│              │▒▒▒▒▒▒▒▒▒▒▒▒│
         │            │              │            │
         │            │ ← Dim (0.1)  │░░░░░░░░░░░░│ ← Still visible
         │            │              │░░░░░░░░░░░░│
         └────────────┘              └────────────┘
```

## Lighting Calculation

The `RenderPipeline` calculates lighting according to the material's `shadingModel`:

- `.flat` (default): once per triangle, using the face normal
- `.gouraud`: once per vertex, using the vertex normals; colors are interpolated across the triangle
- `.unlit`: no lighting, the base color is used as-is

```
Final Color = Base Color × (Ambient + Σ Directional)

Ambient Term:
  ambientIntensity × ambientColor

Directional Term (per light):
  max(0, dot(normal, lightDirection)) × lightIntensity × lightColor
```

### Code Equivalent

```swift
// Pseudocode (colors treated as 0-1 RGB vectors)
var totalLight = AmbientLight.effectiveIntensity * AmbientLight.effectiveColor

for light in DirectionalLight.all {
    let nDotL = max(0, normal.dot(light.direction))
    totalLight += nDotL * light.intensity * light.color
}

finalColor = baseColor * totalLight
```

## Common Lighting Setups

### Outdoor Daylight

```swift
let light = createGameObject(name: "Light")

// Bright sun from above
let sun = light.addComponent(DirectionalLight.self)
sun.direction = Vec3d(0.3, 1.0, 0.2)
sun.intensity = 1.0
sun.color = Color(r: 255, g: 250, b: 240)  // Warm white

// Sky ambient
let ambient = light.addComponent(AmbientLight.self)
ambient.intensity = 0.3
ambient.color = Color(r: 180, g: 200, b: 255)  // Sky blue tint
```

### Indoor Scene

```swift
let light = createGameObject(name: "Light")

// Weaker directional (window light)
let window = light.addComponent(DirectionalLight.self)
window.direction = Vec3d(1, 0.5, 0)
window.intensity = 0.7
window.color = .white

// Higher ambient (bounced light)
let ambient = light.addComponent(AmbientLight.self)
ambient.intensity = 0.4
ambient.color = Color(r: 240, g: 230, b: 220)  // Warm interior
```

### Night Scene

```swift
let light = createGameObject(name: "Light")

// Dim moonlight
let moon = light.addComponent(DirectionalLight.self)
moon.direction = Vec3d(-0.3, 1.0, 0.5)
moon.intensity = 0.3
moon.color = Color(r: 180, g: 180, b: 220)  // Blue-ish

// Very low ambient
let ambient = light.addComponent(AmbientLight.self)
ambient.intensity = 0.05
ambient.color = Color(r: 50, g: 50, b: 80)  // Dark blue
```

### Multiple Light Sources

```swift
// Main sun
let sunObj = createGameObject(name: "Sun")
let sun = sunObj.addComponent(DirectionalLight.self)
sun.direction = Vec3d(0.5, 1, 0.3)
sun.intensity = 1.0
sun.color = Color(r: 255, g: 250, b: 230)

// Secondary fill light (reduces harsh shadows)
let fillObj = createGameObject(name: "Fill")
let fill = fillObj.addComponent(DirectionalLight.self)
fill.direction = Vec3d(-0.5, 0.5, -0.3)
fill.intensity = 0.3
fill.color = Color(r: 200, g: 200, b: 255)

// Ambient
let ambientObj = createGameObject(name: "Ambient")
ambientObj.addComponent(AmbientLight.self).intensity = 0.15
```

## Dynamic Lighting

### Day/Night Cycle

```swift
public final class DayNightCycle: Component {
    var timeOfDay: Float = 0  // 0-1 (0=midnight, 0.5=noon)
    var cycleSpeed: Float = 0.01  // Full cycle per 100 seconds
    
    public override func update(deltaTime: Float) {
        timeOfDay = (timeOfDay + cycleSpeed * deltaTime).truncatingRemainder(dividingBy: 1)
        
        guard let sun = DirectionalLight.main,
              let ambient = AmbientLight.current else { return }
        
        // Rotate sun
        let angle = timeOfDay * Float.pi * 2
        sun.direction = Vec3d(cos(angle), sin(angle), 0.3)
        
        // Adjust intensity (dim at night)
        let dayFactor = max(0, sin(timeOfDay * Float.pi * 2))
        sun.intensity = dayFactor
        ambient.intensity = 0.1 + dayFactor * 0.2
        
        // Shift colors
        if timeOfDay < 0.25 || timeOfDay > 0.75 {
            // Night - blue tint
            sun.color = Color(r: 150, g: 150, b: 200)
        } else if timeOfDay < 0.3 || timeOfDay > 0.7 {
            // Sunrise/sunset - orange
            sun.color = Color(r: 255, g: 180, b: 100)
        } else {
            // Day - white
            sun.color = .white
        }
    }
}
```

### Flickering Light

```swift
public final class FlickerLight: Component {
    var baseIntensity: Float = 1.0
    var flickerAmount: Float = 0.2
    
    public override func update(deltaTime: Float) {
        guard let light = gameObject?.getComponent(DirectionalLight.self) else { return }
        
        let flicker = Float.random(in: -flickerAmount...flickerAmount)
        light.intensity = max(0, baseIntensity + flicker)
    }
}
```

## Best Practices

1. **Add an AmbientLight** - Controls the base illumination (otherwise a dim default of 0.1 is used)
2. **Keep ambient low** - 0.1-0.3 is usually enough
3. **Use colored lights sparingly** - Subtle tints work best
4. **One main directional light** - Additional lights are fills
5. **Match light to scene mood** - Warm for comfort, cool for tension
