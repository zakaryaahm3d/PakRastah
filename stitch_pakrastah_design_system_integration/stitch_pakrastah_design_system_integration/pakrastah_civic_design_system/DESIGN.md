---
name: PakRastah Civic Design System
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1b1b1b'
  on-surface-variant: '#404944'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#707973'
  outline-variant: '#bfc9c2'
  surface-tint: '#2c6951'
  primary: '#003021'
  on-primary: '#ffffff'
  primary-container: '#004933'
  on-primary-container: '#7ab89b'
  inverse-primary: '#95d4b6'
  secondary: '#426741'
  on-secondary: '#ffffff'
  secondary-container: '#c4eebd'
  on-secondary-container: '#486d47'
  tertiary: '#222c24'
  on-tertiary: '#ffffff'
  tertiary-container: '#384239'
  on-tertiary-container: '#a3aea2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b1f0d1'
  primary-fixed-dim: '#95d4b6'
  on-primary-fixed: '#002115'
  on-primary-fixed-variant: '#0d513a'
  secondary-fixed: '#c4eebd'
  secondary-fixed-dim: '#a8d1a3'
  on-secondary-fixed: '#002105'
  on-secondary-fixed-variant: '#2b4f2b'
  tertiary-fixed: '#dbe6d9'
  tertiary-fixed-dim: '#bfc9bd'
  on-tertiary-fixed: '#141e16'
  on-tertiary-fixed-variant: '#3f4940'
  background: '#fcf9f8'
  on-background: '#1b1b1b'
  surface-variant: '#e5e2e1'
typography:
  h1:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  h3:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
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
  data-label:
    fontFamily: IBM Plex Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  data-mono:
    fontFamily: IBM Plex Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  button:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  gutter: 24px
  margin-mobile: 16px
  sidebar-width: 256px
  container-max: 1440px
---

## Brand & Style

The design system is engineered for **PakRastah**, a professional waste management platform for Pakistan. The brand personality is institutional, authoritative, and reliable, reflecting the critical nature of civic infrastructure. 

The aesthetic follows a **Corporate / Modern** approach with a high-fidelity civic-tech polish. It prioritizes clarity, systematic organization of complex data, and a sense of permanence. By utilizing a deep, forest-inspired palette and structured typography, the UI evokes a sense of government-level stability and environmental stewardship. The visual language is intentionally restrained—avoiding trendy embellishments in favor of precise utility and legibility.

## Colors

This design system utilizes a palette rooted in "Deep Forest" green to signify both authority and ecology. 

- **Primary (#004933):** Reserved for high-level navigation, primary actions, and institutional branding. 
- **Surface (#E3EEE1):** The "Sage Mist" background provides a soft, low-strain canvas for prolonged data entry and monitoring.
- **Accents (#62885F):** Used for icons and active states to provide visual feedback without breaking the professional tone.
- **Semantic Colors:** Warning (#D97706) and Danger (#DC2626) follow international standards for alerts and violations, ensuring immediate cognitive recognition.
- **Typography:** Primary text uses a near-black (#1C1C1C) for maximum contrast, while secondary metadata uses a muted grey (#6B7280).

## Typography

The system employs a dual-typeface strategy to separate narrative UI from technical data.

- **Inter:** The workhorse for all interface text, headings, and labels. It provides a neutral, highly legible foundation that scales perfectly from mobile screens to desktop dashboards.
- **IBM Plex Mono:** Strictly used for data-heavy elements including IDs, timestamps, coordinates, and numerical values. This monospace treatment ensures that figures align vertically in tables and creates a clear "technical" distinction for operational data.

Headings should use tighter tracking (-0.01em to -0.02em) to maintain a dense, professional appearance.

## Layout & Spacing

The layout is built on an **8px base grid** with a standard **24px spacing** rhythm for major component gaps. 

**Dashboard Layout:**
- **Sidebar:** A fixed 256px width sidebar in Deep Forest (#004933) houses the primary navigation.
- **Main Content:** Occupies the remaining viewport width on a Sage Mist (#E3EEE1) background. 

**Responsive Rules:**
- **Desktop:** 12-column grid with 24px gutters.
- **Tablet:** 8-column grid with 16px gutters; sidebar may collapse into a drawer.
- **Mobile:** 4-column grid with 16px margins. Landing pages reflow to a single column.

White space should be used generously between distinct cards, while internal card padding should strictly follow the 24px rule to maintain a consistent density.

## Elevation & Depth

This design system uses **Tonal Layers** and **Subtle Shadows** rather than high-contrast depth. 

- **Surface Tier 0:** Page Background (#E3EEE1).
- **Surface Tier 1 (Cards/Panels):** White (#FFFFFF) with a 1px border (#D1D9D0).
- **Shadows:** A single, soft shadow level is used for cards: `0px 1px 3px rgba(0, 0, 0, 0.05), 0px 1px 2px rgba(0, 0, 0, 0.1)`. 
- **Interactions:** On hover, cards do not lift; instead, the 1px border may slightly darken to #62885F to indicate interactivity.

This approach creates a "flat-plus" look that feels grounded and professional, avoiding the playfulness of heavy blurs or deep shadows.

## Shapes

The shape language is disciplined and geometric. A **Soft (4px)** radius is applied to all primary UI elements including buttons, input fields, and cards. 

- **No Pill Shapes:** All buttons and tags must maintain the 4px corner radius. Rounded-full/pill shapes are strictly prohibited to preserve the institutional aesthetic.
- **Consistency:** If a container has a 4px radius, nested elements (like selection indicators) should use a 2px radius to maintain visual harmony.

## Components

### Buttons
- **Primary:** Background #004933, Text #FFFFFF. 4px radius. 
- **Secondary:** Background #FFFFFF, Border 1px #D1D9D0, Text #1C1C1C.
- **Transition:** 150ms ease-out on all hover/active states.

### Data Tables
- **Header:** Sticky, Background #004933, Text #FFFFFF, Weight 600.
- **Rows:** Alternating background colors (White / #F4F9F3).
- **Cells:** Use IBM Plex Mono for all numerical data and IDs.

### Input Fields
- **Default:** Background #E3EEE1 (blends slightly with page) or #FFFFFF (inside cards), 1px #D1D9D0 border.
- **Focus:** 1px #62885F border with a subtle 2px outer glow.

### Cards
- Always #FFFFFF background with 1px #D1D9D0 border and subtle shadow.
- Header sections within cards should be separated by a 1px horizontal rule.

### Status Chips
- **Pending:** #D97706 text on a 10% opacity background of the same color. 
- **Danger:** #DC2626 text on a 10% opacity background. 
- Chips must be rectangular with a 4px radius (not pill-shaped).