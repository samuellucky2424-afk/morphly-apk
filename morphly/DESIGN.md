---
name: Morphly
colors:
  surface: '#090909'
  surface-dim: '#12131a'
  surface-bright: '#383940'
  surface-container-lowest: '#0c0e14'
  surface-container-low: '#1a1b22'
  surface-container: '#1e1f26'
  surface-container-high: '#282a31'
  surface-container-highest: '#33343c'
  on-surface: '#e2e1eb'
  on-surface-variant: '#cfc2d6'
  inverse-surface: '#e2e1eb'
  inverse-on-surface: '#2f3037'
  outline: '#988d9f'
  outline-variant: '#4d4354'
  surface-tint: '#ddb7ff'
  primary: '#ddb7ff'
  on-primary: '#490080'
  primary-container: '#b76dff'
  on-primary-container: '#400071'
  inverse-primary: '#842bd2'
  secondary: '#4ae176'
  on-secondary: '#003915'
  secondary-container: '#00b954'
  on-secondary-container: '#004119'
  tertiary: '#ffb3ad'
  on-tertiary: '#68000a'
  tertiary-container: '#ff5451'
  on-tertiary-container: '#5c0008'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#f0dbff'
  primary-fixed-dim: '#ddb7ff'
  on-primary-fixed: '#2c0051'
  on-primary-fixed-variant: '#6900b3'
  secondary-fixed: '#6bff8f'
  secondary-fixed-dim: '#4ae176'
  on-secondary-fixed: '#002109'
  on-secondary-fixed-variant: '#005321'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#050505'
  on-background: '#e2e1eb'
  surface-variant: '#33343c'
  card-bg: '#111111'
  border: '#27272A'
  text-white: '#FFFFFF'
typography:
  app-title:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  page-title:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  button-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
  button-sm:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  margin-mobile: 20px
  gutter: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

This design system is engineered for a high-fidelity, futuristic AI camera experience. It merges the playful, tactile nature of social media capture tools with the sophisticated, "dark mode" aesthetic of high-end fintech apps. The brand personality is tech-forward, premium, and clean, focusing on the magical quality of AI transformations.

The visual style is **Futuristic / Minimalist**, utilizing deep blacks, vibrant neon glows, and precision-engineered typography. It leverages high-contrast accents against a monochromatic base to create a sense of depth and cinematic atmosphere, ensuring that the user's AI-generated content remains the focal point while the interface feels like a sophisticated piece of hardware.

## Colors

The palette is anchored in true blacks to ensure OLED efficiency and visual depth. **Primary Purple** serves as the "magic" color, used for AI interactions, avatars, and premium states. **Neon Green** is utilized for utility and confirmation, specifically for capture states and positive financial transactions (credits).

Dark surfaces are layered using tiered shades of gray (#050505 to #111111) to define hierarchy without relying on heavy borders. A "Glow" mechanic is essential: primary buttons and active states should emit a 20-30px soft outer blur using their respective accent color at 40% opacity.

## Typography

This design system uses **Inter** for all roles to maintain a clean, technical, and highly legible appearance. The scale relies on weight contrast—using Bold for titles to convey authority and Semi-Bold for buttons to ensure clear calls to action. 

For the App Title, a tighter letter-spacing is applied to give it a "logo-like" appearance within the floating top bar. Labels and small metadata should use the `label-caps` style with increased tracking to maintain a premium, architectural feel.

## Layout & Spacing

The layout is optimized for single-handed mobile use. It follows a **4px baseline grid** with a standard **20px side margin** for content containers. 

The primary navigation and capture controls are concentrated in the bottom "active zone" (bottom 35% of the screen), while informational headers and credit balances reside in a **floating top bar**. This top bar should have a 16px margin from the screen edges and use a backdrop-blur (20px) to separate it from the camera feed.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** and **Luminous Depth**:
1. **Level 0 (Base):** #050505 (The camera view or deep background).
2. **Level 1 (Drawers/Sheets):** #090909 (For settings or filters that slide up).
3. **Level 2 (Cards):** #111111 with a 1px solid border of #27272A.
4. **Level 3 (Floating Elements):** #111111 with a subtle 15% opacity white inner glow to simulate a glass edge.

Shadows are rarely used as "black-on-black." Instead, depth is communicated via "Glows." Elements that need to stand out (like the credit wallet or primary capture button) use a colored outer shadow (Purple or Green) to lift them off the dark canvas.

## Shapes

The shape language is consistently **Rounded**, leaning towards pill-shapes for interactive elements. 
- **Standard Cards:** 1rem (16px) corner radius.
- **Action Buttons:** Full pill-shape (height / 2).
- **Secondary Items:** 0.5rem (8px) for list items and smaller inputs.

Avoid sharp 0px corners entirely to maintain the approachable, modern aesthetic. The Primary Action Button (Capture) must be a perfect circle to differentiate it from navigational pill buttons.

## Components

### Buttons
- **Primary Action (Capture):** Large 80x80px circular button. Neon Green (#22C55E) background with a 20px green glow. On tap, it should scale down by 10%.
- **Secondary Pill:** Purple outline (1.5px), no fill, white text. High-radius (pill).
- **Ghost Button:** Muted text (#A1A1AA), no background or border, used for less critical actions like "Cancel."

### Cards
- **Credit Wallet Card:** #111111 background with a 1.5px gradient border (Primary Purple to Neon Green). Includes a subtle "mesh gradient" background at 10% opacity.
- **Content Card:** #111111 with #27272A border.

### Inputs & Toggles
- **Input Fields:** #090909 fill with a subtle #27272A border. On focus, the border transitions to Primary Purple with a 4px soft outer glow.
- **Toggles:** Use the Neon Green for the "On" state. The track should be #27272A.

### Navigation
- **Floating Top Bar:** A container with 20px blur, #111111 background at 70% opacity, and rounded-xl corners. 
- **List Items:** Rounded rectangles with #111111 background, separated by 8px of vertical spacing rather than horizontal dividers.