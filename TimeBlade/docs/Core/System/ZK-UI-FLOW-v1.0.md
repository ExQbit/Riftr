# Zeitklingen: UI-Flow & Design-System (ZK-UI-FLOW-v1.0-20250522)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Design-System & Komponenten-Bibliothek](#2-design-system--komponenten-bibliothek)
3. [Responsive-Layout & Breakpoints](#3-responsive-layout--breakpoints)
4. [Animation-System & Specs](#4-animation-system--specs)
5. [Kern-Aufladungs-Flow](#5-kern-aufladungs-flow)
6. [Kern-Verwendungs-Flow](#6-kern-verwendungs-flow)
7. [Kern-Umwandlungs-Flow](#7-kern-umwandlungs-flow)
8. [Zeit-Kit-Interaktions-Flow](#8-zeit-kit-interaktions-flow)
9. [Error-States & Loading-Patterns](#9-error-states--loading-patterns)
10. [Notification-System](#10-notification-system)
11. [Mobile-UI-Optimierungen](#11-mobile-ui-optimierungen)
12. [Zugänglichkeit und UX-Richtlinien](#12-zugänglichkeit-und-ux-richtlinien)
13. [Performance-Guidelines](#13-performance-guidelines)
14. [Zeitkosten-UI-System](#14-zeitkosten-ui-system)
15. [Implementation-Guidelines](#15-implementation-guidelines)

---

## 1. Einführung und Übersicht

Dieses Dokument beschreibt das komplette UI-System für Zeitklingen, von grundlegenden Design-Komponenten bis zu komplexen Interaktionsflows. Es dient als vollständige Implementierungs-Referenz für Frontend-Entwickler und stellt sicher, dass alle UI-Elemente konsistent und entwicklerfreundlich sind.

### 1.1 Kernprinzipien der UI-Gestaltung

* **Klarheit über Komplexität**: Die UI muss die Tiefe des Systems zugänglich machen, ohne Details zu verstecken
* **Flüssige Übergänge**: Nahtlose Übergänge zwischen allen Kern-Interaktionen ohne unnötige Ladescreens
* **Visuelles Feedback**: Deutliche, sofortige Rückmeldung bei allen Aktionen durch Animation, Farbe und Ton
* **Progressive Offenlegung**: Komplexe Optionen werden erst angezeigt, wenn sie relevant werden
* **Konsistente Metaphern**: Einheitliche visuelle Sprache für alle Zeit-Kern-bezogenen Elemente

### 1.2 Haupt-UI-Elemente des Zeit-Kern-Systems

- **Kern-Widget**: Permanent sichtbare Kompaktanzeige im Hauptbildschirm
- **Kern-Management-Bildschirm**: Zentrale Verwaltungsoberfläche für alle Kern-Operationen
- **Aufladungs-Fortschrittsbalken**: Visuelle Darstellung der Kern-Aufladung
- **Element-Indikatoren**: Farbcodierung und Symbolik zur Unterscheidung der Elemente
- **Stufen-Repräsentation**: Größe, Helligkeit und Animation zeigen die Kern-Stufe an

---

## 2. Design-System & Komponenten-Bibliothek

### 2.1 Farbpalette und Bedeutung

| Element | Primärfarbe | Sekundärfarbe | Hover/Active | Disabled | Kontrast-Ratio |
|---------|-------------|---------------|--------------|----------|----------------|
| Neutral | #3A7BF7 | #E0E5F2 | #5A8BF9 | #C0C5D2 | 4.8:1 |
| Feuer | #FF5722 | #FFEBE8 | #FF7744 | #FFB8A3 | 5.2:1 |
| Eis | #00BCD4 | #E0FDFF | #22CAD6 | #80DDE4 | 4.9:1 |
| Blitz | #6200EA | #F3E5FF | #7722EC | #B988F5 | 5.1:1 |
| Success | #4CAF50 | #E8F5E8 | #6CBF70 | #A6D7A8 | 4.7:1 |
| Warning | #FF9800 | #FFF3E0 | #FFB74D | #FFCC80 | 4.5:1 |
| Error | #F44336 | #FFEBEE | #E57373 | #FFCDD2 | 5.0:1 |

### 2.2 Typography-System

```css
/* Basis-Schriftarten */
--font-primary: 'Roboto', system-ui, sans-serif;
--font-display: 'Orbitron', 'Roboto', sans-serif; /* Für Zeit-Elemente */
--font-monospace: 'Roboto Mono', monospace; /* Für Zahlen/Statistiken */

/* Schriftgrößen-Skala */
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
--text-4xl: 2.25rem;   /* 36px */

/* Line Heights */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### 2.3 Spacing-System

```css
/* Spacing-Skala (4px Basis-Einheit) */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
```

### 2.4 Kern-Komponenten-Bibliothek

#### 2.4.1 Zeit-Kern-Component
```tsx
interface TimeCore {
  id: string;
  element: 'neutral' | 'fire' | 'ice' | 'lightning';
  level: 1 | 2 | 3 | 4 | 5;
  chargePercentage: number; // 0-100
  isActive: boolean;
  size: 'small' | 'medium' | 'large'; // 32px, 48px, 64px
  showTooltip?: boolean;
  onClick?: () => void;
}

// Größen-Spezifikationen
const CORE_SIZES = {
  small: { width: 32, height: 32, glow: 2 },
  medium: { width: 48, height: 48, glow: 4 },
  large: { width: 64, height: 64, glow: 6 }
};
```

#### 2.4.2 Fortschrittsbalken-Component
```tsx
interface ProgressBar {
  current: number;
  max: number;
  variant: 'time-core' | 'xp' | 'health' | 'material';
  size: 'sm' | 'md' | 'lg'; // 4px, 8px, 12px height
  showLabel: boolean;
  animated: boolean;
  segments?: number; // Für segmentierte Anzeige
}

// Segment-Konfiguration
const PROGRESS_SEGMENTS = {
  'time-core': 10, // 10% Segmente
  'xp': 1,         // Kontinuierlich
  'material': 5    // 20% Segmente
};
```

#### 2.4.3 Button-System
```tsx
interface GameButton {
  variant: 'primary' | 'secondary' | 'danger' | 'success' | 'ghost';
  size: 'sm' | 'md' | 'lg'; // 32px, 40px, 48px height
  element?: 'neutral' | 'fire' | 'ice' | 'lightning';
  disabled?: boolean;
  loading?: boolean;
  icon?: ReactNode;
  fullWidth?: boolean;
}

// Button-Größen-Specs
const BUTTON_SPECS = {
  sm: { height: 32, padding: '6px 12px', fontSize: 14 },
  md: { height: 40, padding: '8px 16px', fontSize: 16 },
  lg: { height: 48, padding: '12px 24px', fontSize: 18 }
};
```

#### 2.4.4 Modal/Dialog-System
```tsx
interface GameModal {
  title: string;
  size: 'sm' | 'md' | 'lg' | 'xl'; // 400px, 600px, 800px, 1000px
  showCloseButton: boolean;
  preventClose?: boolean; // Für kritische Aktionen
  backdrop: 'blur' | 'dark' | 'transparent';
  animation: 'slide-up' | 'fade' | 'scale';
}
```

---

## 3. Responsive-Layout & Breakpoints

### 3.1 Breakpoint-System

```css
/* Mobile-First Breakpoints */
--breakpoint-xs: 320px;  /* Minimum mobile */
--breakpoint-sm: 480px;  /* Large mobile */
--breakpoint-md: 768px;  /* Tablet */
--breakpoint-lg: 1024px; /* Desktop */
--breakpoint-xl: 1440px; /* Large desktop */
--breakpoint-2xl: 1920px; /* Ultra-wide */

/* Container-Größen */
--container-xs: 100%;
--container-sm: 100%;
--container-md: 728px;
--container-lg: 984px;
--container-xl: 1200px;
--container-2xl: 1400px;
```

### 3.2 Layout-Grid-System

```css
/* 12-Spalten-Grid-System */
.grid-container {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: var(--space-4);
  max-width: var(--container-xl);
  margin: 0 auto;
  padding: 0 var(--space-4);
}

/* Responsive Grid-Spalten */
.col-1 { grid-column: span 1; }
.col-2 { grid-column: span 2; }
/* ... bis col-12 */

@media (max-width: 768px) {
  .col-md-12 { grid-column: span 12; }
  .col-md-6 { grid-column: span 6; }
}
```

### 3.3 Kern-Widget Responsive-Verhalten

| Breakpoint | Position | Größe | Extras |
|------------|----------|-------|--------|
| xs (320px) | Bottom-left, 16px margin | 48px | Nur Icon, kein Text |
| sm (480px) | Bottom-left, 20px margin | 56px | Icon + Zähler |
| md (768px) | Bottom-right, 24px margin | 64px | Icon + Text + Zähler |
| lg (1024px+) | Top-right, 32px margin | 72px | Vollständige Anzeige |

---

## 4. Animation-System & Specs

### 4.1 Animation-Timing-Funktionen

```css
/* Easing-Funktionen */
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
--ease-in-out-back: cubic-bezier(0.68, -0.55, 0.265, 1.55);
--ease-out-elastic: cubic-bezier(0.68, 0, 0.265, 1.55);
--ease-game: cubic-bezier(0.4, 0, 0.2, 1); /* Standard Game-Easing */

/* Durations */
--duration-fast: 150ms;
--duration-base: 250ms;
--duration-slow: 400ms;
--duration-celebration: 800ms;
```

### 4.2 Kern-Aufladungs-Animationen

```css
/* Aufladungs-Pulse-Animation */
@keyframes core-charge-pulse {
  0% { 
    transform: scale(1);
    box-shadow: 0 0 0 0 var(--core-color-50);
  }
  50% { 
    transform: scale(1.05);
    box-shadow: 0 0 0 8px var(--core-color-20);
  }
  100% { 
    transform: scale(1);
    box-shadow: 0 0 0 0 var(--core-color-0);
  }
}

/* Vollständige Aufladung */
@keyframes core-fully-charged {
  0% { transform: scale(1) rotate(0deg); }
  25% { transform: scale(1.15) rotate(5deg); }
  50% { transform: scale(1.1) rotate(-5deg); }
  75% { transform: scale(1.05) rotate(2deg); }
  100% { transform: scale(1) rotate(0deg); }
}
```

### 4.3 Level-Up-Celebration-Animation

```css
@keyframes level-up-celebration {
  0% { 
    transform: scale(1) translateY(0);
    opacity: 1;
  }
  20% { 
    transform: scale(1.2) translateY(-10px);
    opacity: 1;
  }
  40% { 
    transform: scale(1.1) translateY(-5px);
    opacity: 0.9;
  }
  100% { 
    transform: scale(1) translateY(0);
    opacity: 1;
  }
}

/* Partikel-Effekt für Level-Up */
@keyframes particle-burst {
  0% { 
    transform: translate(0, 0) scale(0);
    opacity: 1;
  }
  50% { 
    transform: translate(var(--random-x), var(--random-y)) scale(1);
    opacity: 0.8;
  }
  100% { 
    transform: translate(calc(var(--random-x) * 2), calc(var(--random-y) * 2)) scale(0);
    opacity: 0;
  }
}
```

### 4.4 Touch-Feedback-Animationen

```css
/* Button-Touch-Feedback */
@keyframes button-press {
  0% { transform: scale(1); }
  50% { transform: scale(0.95); }
  100% { transform: scale(1); }
}

/* Ripple-Effekt */
@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 0.6;
  }
  100% {
    transform: scale(2);
    opacity: 0;
  }
}
```

---

## 5. Kern-Aufladungs-Flow

### 5.1 Passiver Aufladungs-Flow (nach Spielaktionen)

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│Spielaktivität  │────>│Aufladungs-     │────>│Kern-Widget     │
│(Kampf/Quest)   │     │Animation       │     │Update          │
└────────────────┘     └────────────────┘     └────────────────┘
                                │
                                ▼
┌────────────────┐     ┌────────────────┐
│Benachrichtigung│<────│100% Aufladung  │
│(optional)      │     │erreicht?       │
└────────────────┘     └────────────────┘
```

#### 5.1.1 UI-Elemente und Interaktionen

**Aufladungsanimation-Specs:**
- **Timing**: 700ms mit `ease-out-quart`
- **Partikel-Pfad**: Vom Ursprungsort (z.B. besiegter Gegner) zum Kern-Widget
- **Farbe**: Element-spezifisch mit 80% Opazität
- **Performance**: Max. 8 Partikel gleichzeitig, CSS-Animationen bevorzugt

**Kern-Widget Update-Specs:**
- **Fortschrittsbalken**: Smooth-Animation über 500ms
- **Numerische Anzeige**: Counter-Animation mit `tabular-nums`
- **Hervorhebung**: Bei >10% Sprüngen, 300ms Glow-Effekt
- **Accessibility**: Screen-Reader-Ansage bei kritischen Schwellenwerten

**Vollständige Aufladung-Specs:**
- **Animation**: 1200ms Celebration mit Skalierung und Rotation
- **Haptik**: 100ms starke Vibration (iOS/Android)
- **Sound**: Element-spezifischer Aufladungsklang (0.8s)
- **Visual**: 2s Glow-Effekt mit pulsierender Intensität

### 5.2 Zeit-Kit-Anwendungs-Flow

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│Kern-Widget     │────>│Zeit-Kit        │────>│Kern-Auswahl    │
│Antippen        │     │Option wählen   │     │Dialog          │
└────────────────┘     └────────────────┘     └────────────────┘
                                                       │
                                                       ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│Erfolgs-        │<────│Kit-Anwendungs- │<────│Bestätigungs-   │
│Animation       │     │Animation       │     │Dialog          │
└────────────────┘     └────────────────┘     └────────────────┘
```

**Kit-Dialog-Specs:**
- **Größe**: 400px (Mobile), 600px (Desktop)
- **Animation**: Slide-up von unten (Mobile), Fade + Scale (Desktop)
- **Backdrop**: 60% schwarzer Blur-Effekt
- **Auto-Empfehlung**: Niedrigste Ladung wird visuell hervorgehoben

---

## 6. Kern-Verwendungs-Flow

### 6.1 Karten-Leveling-Interface

**Kartenauswahl-Specs:**
```tsx
interface CardLevelingInterface {
  filterOptions: {
    element: ElementType[];
    level: { min: number; max: number };
    rarity: RarityType[];
    compatibility: 'all' | 'compatible' | 'optimal';
  };
  sortOptions: 'level' | 'compatibility' | 'recent' | 'alphabetical';
  viewMode: 'grid' | 'list';
  batchMode: boolean; // Multi-Auswahl für Massen-Leveling
}
```

**Kompatibilitäts-Anzeige:**
- **Optimal-Match**: Grüner Rahmen + 3 Sterne + "2× XP" Badge
- **Element-Match**: Blauer Rahmen + 2 Sterne + "1.5× XP" Badge  
- **Standard**: Grauer Rahmen + 1 Stern + "1× XP" Badge
- **Nicht-kompatibel**: Rot gestrichelte Linie + Warning-Icon

**Level-Vorschau-Component:**
```tsx
interface LevelPreview {
  currentLevel: number;
  newLevel: number;
  xpGain: number;
  powerIncrease: number;
  gateReached?: {
    from: RarityType;
    to: RarityType;
    bonusAttribute: string;
  };
}
```

---

## 7. Kern-Umwandlungs-Flow

### 7.1 Umwandlungs-Interface-Specs

**Umwandlungstyp-Auswahl:**
- **Layout**: 2×1 Grid (Desktop), Stacked (Mobile)
- **Karten-Design**: 280×180px, abgerundete Ecken (12px)
- **Hover-Effekt**: 5px Elevation + subtle Glow
- **Success-Rate-Anzeige**: Große Zahl (36px) + Prozent-Balken

**Quellkern-Selektor:**
```tsx
interface SourceCoreSelector {
  availableCores: TimeCore[];
  requiredAmount: number;
  autoSelectOptimal: boolean;
  showEfficiencyRating: boolean; // Effizienz-Score pro Kern
  allowOverSelection: boolean; // Für höhere Erfolgsraten
}
```

**Umwandlungs-Animation-Specs:**
- **Dauer**: 1500-2000ms je nach Komplexität
- **Stufen**:
  1. Cores verschmelzen (500ms)
  2. Transformation (800ms)
  3. Ergebnis-Reveal (700ms)
- **Failure-Animation**: 400ms "Shake" + Particle-Scatter
- **Success-Animation**: 1200ms mit Scale + Glow + Partikel

---

## 8. Zeit-Kit-Interaktions-Flow

### 8.1 Kit-Inventory-Management

**Kit-Anzeige-Specs:**
```tsx
interface KitInventory {
  maxKits: 10;
  currentKits: number;
  kitSources: {
    dailyQuests: { completed: number; required: 3 };
    events: { available: number };
    premium: { dailyLimit: 3; purchased: number };
  };
  autoUseThreshold?: number; // Auto-Use bei x% niedrigster Ladung
}
```

**Kit-Anwendungs-Strategien:**
- **Smart-Apply**: Auf niedrigste Ladungen verteilen
- **Balanced-Apply**: Gleichmäßige Verteilung
- **Targeted-Apply**: Manuell ausgewählte Kerne
- **Overflow-Protection**: Warnung bei >100% Aufladung

---

## 9. Error-States & Loading-Patterns

### 9.1 Loading-States

**Skeleton-Loading für Karten:**
```tsx
interface CardSkeleton {
  count: number; // Anzahl der Skeleton-Karten
  animation: 'pulse' | 'shimmer';
  aspectRatio: '3:4'; // Standard-Kartenverhältnis
}
```

**Loading-Spinner-Specs:**
- **Size**: 24px (inline), 48px (modal), 64px (full-screen)
- **Animation**: 1.5s rotation mit `linear` easing
- **Colors**: Element-spezifisch oder neutral (#3A7BF7)
- **Accessibility**: `aria-label="Loading..."` + `role="status"`

### 9.2 Error-States

**Connection-Error-Component:**
```tsx
interface ConnectionError {
  type: 'offline' | 'timeout' | 'server' | 'unknown';
  retryable: boolean;
  retryDelay: number; // Sekunden bis nächster Auto-Retry
  customMessage?: string;
  showSupportLink: boolean;
}
```

**Validation-Error-Specs:**
- **Inline-Errors**: Unter Input-Feldern, rot (#F44336)
- **Field-Highlighting**: Roter Rahmen + Error-Icon
- **Error-Timing**: Erscheint sofort, verschwindet nach Korrektur
- **Bulk-Errors**: Toast-Notification für System-Fehler

### 9.3 Empty-States

**Empty-Inventory-Component:**
```tsx
interface EmptyState {
  illustration: 'empty-cores' | 'empty-kits' | 'empty-materials';
  title: string;
  description: string;
  primaryAction?: {
    label: string;
    action: () => void;
  };
  secondaryAction?: {
    label: string;
    action: () => void;
  };
}
```

---

## 10. Notification-System

### 10.1 Toast-Notifications

**Toast-Specs:**
```tsx
interface Toast {
  id: string;
  type: 'success' | 'warning' | 'error' | 'info';
  title: string;
  message?: string;
  duration: number; // ms, 0 = persistent
  position: 'top-right' | 'top-center' | 'bottom-right';
  dismissable: boolean;
  actions?: Array<{
    label: string;
    action: () => void;
    style?: 'primary' | 'secondary';
  }>;
}
```

**Toast-Positionen:**
- **Mobile**: Bottom-center, full-width mit safe-area-inset
- **Desktop**: Top-right, 400px width, max 5 gleichzeitig
- **Stacking**: Neuste oben, ältere nach unten geschoben
- **Auto-Dismiss**: 5s (success), 8s (warning), permanent (error)

### 10.2 In-Game-Notifications

**Material-Gewinn-Notification:**
```tsx
interface MaterialGainNotification {
  materials: Array<{
    type: MaterialType;
    amount: number;
    rarity?: 'common' | 'rare' | 'epic';
  }>;
  source: string; // "Combat Victory", "Quest Complete", etc.
  celebration: boolean; // Für seltene/große Gewinne
}
```

**Progression-Celebration:**
- **Level-Up**: 2s Full-Screen-Overlay mit Kartenvorschau
- **Gate-Reached**: 1.5s Modal mit neuer Rarity-Anzeige
- **Evolution-Unlocked**: 2.5s Celebration mit Pfad-Auswahl-Teaser

---

## 11. Mobile-UI-Optimierungen

### 11.1 Touch-Optimierte Layouts

**Touch-Target-Specs:**
- **Minimum**: 44×44px (Apple), 48×48px (Material)
- **Recommended**: 56×56px für primäre Aktionen
- **Spacing**: Min. 8px zwischen Touch-Targets
- **Hit-Box**: 8px größer als visuelles Element

**Gesture-Support:**
```tsx
interface GestureConfig {
  swipeNavigation: {
    enabled: boolean;
    directions: ('left' | 'right' | 'up' | 'down')[];
    threshold: number; // px
  };
  longPress: {
    duration: number; // ms
    feedbackType: 'haptic' | 'visual' | 'both';
  };
  pinchZoom: {
    enabled: boolean;
    minScale: number;
    maxScale: number;
  };
}
```

### 11.2 Bottom-Sheet-Implementation

**Bottom-Sheet-Specs:**
```tsx
interface BottomSheet {
  heights: {
    peek: number;      // 120px - Mini-Vorschau
    partial: number;   // 60vh - Hauptinhalt
    full: number;      // 90vh - Vollständige Ansicht
  };
  snapPoints: ('peek' | 'partial' | 'full')[];
  backdropDismiss: boolean;
  dragIndicator: boolean;
  keyboardAware: boolean; // Auto-Anpassung bei Tastatur
}
```

### 11.3 One-Handed-Usage-Optimierungen

**Thumb-Zone-Layout:**
- **Primary Actions**: Untere 25% des Bildschirms
- **Secondary Actions**: Mittlere 50%
- **Information Only**: Obere 25%
- **Quick-Access-Floating-Button**: Bottom-right, 24px margin

---

## 12. Zugänglichkeit und UX-Richtlinien

### 12.1 WCAG-Compliance-Specs

**Farbkontrast-Matrix:**
| Textgröße | Normal | Large (18px+) | Bold |
|-----------|--------|---------------|------|
| AA | 4.5:1 | 3:1 | 4.5:1 |
| AAA | 7:1 | 4.5:1 | 7:1 |

**Screen-Reader-Labels:**
```tsx
// Beispiel für Zeit-Kern-Accessibility
<div
  role="button"
  aria-label={`Time core, ${element} element, level ${level}, ${chargePercentage}% charged`}
  aria-describedby="core-tooltip"
  tabIndex={0}
  onKeyDown={handleKeyPress}
>
  <TimeCore {...props} />
</div>
```

### 12.2 Keyboard-Navigation

**Focus-Management:**
- **Tab-Order**: Logische Reihenfolge von links-oben nach rechts-unten
- **Focus-Indicator**: 2px blaue Outline mit 2px Offset
- **Skip-Links**: "Springe zu Hauptinhalt" für Screen-Reader
- **Escape-Key**: Schließt Modals/Dropdowns
- **Arrow-Keys**: Navigation in Grids/Listen

### 12.3 Reduced-Motion-Support

```css
@media (prefers-reduced-motion: reduce) {
  /* Alle Animationen auf 0.2s begrenzen */
  * {
    animation-duration: 0.2s !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.2s !important;
  }
  
  /* Partikel-Effekte komplett deaktivieren */
  .particle-effect {
    display: none;
  }
}
```

---

## 13. Performance-Guidelines

### 13.1 Animation-Performance

**CSS-Animation-Regeln:**
- **Verwende nur**: `transform`, `opacity`, `filter`
- **Vermeide**: `width`, `height`, `top`, `left`, `background-position`
- **will-change**: Nur für aktive Animationen setzen
- **Hardware-Acceleration**: `transform: translateZ(0)` für kritische Elemente

**JavaScript-Animation-Optimierung:**
```tsx
// Verwende requestAnimationFrame für smooth Animationen
const animateCounter = (start: number, end: number, duration: number) => {
  const startTime = performance.now();
  
  const animate = (currentTime: number) => {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    
    const value = start + (end - start) * easeOutQuart(progress);
    updateCounter(Math.round(value));
    
    if (progress < 1) {
      requestAnimationFrame(animate);
    }
  };
  
  requestAnimationFrame(animate);
};
```

### 13.2 Memory-Management

**Component-Lifecycle-Management:**
- **useEffect-Cleanup**: Alle Event-Listener und Timers entfernen
- **Image-Lazy-Loading**: Für Karten-Assets außerhalb des Viewports
- **Component-Unmounting**: Laufende Animationen stoppen
- **Memory-Leaks**: Zirkuläre Referenzen vermeiden

### 13.3 Render-Optimierung

**React-Performance-Patterns:**
```tsx
// Memoization für teure Berechnungen
const CoreStats = React.memo(({ core }) => {
  const powerLevel = useMemo(() => 
    calculatePowerLevel(core.level, core.rarity, core.bonuses), 
    [core.level, core.rarity, core.bonuses]
  );
  
  return <div>Power: {powerLevel}</div>;
});

// Virtualisierung für große Listen
const CoreInventory = ({ cores }) => {
  return (
    <FixedSizeList
      height={400}
      itemCount={cores.length}
      itemSize={80}
      itemData={cores}
    >
      {CoreItem}
    </FixedSizeList>
  );
};
```

---

## 14. Zeitkosten-UI-System

### 14.1 Zeitkosten-Anzeige-Überblick

Das Zeitkosten-System verwendet eine zweistufige Darstellung: gerundete Werte (auf 0,5s) für die Übersichtlichkeit in der Haupt-UI und präzise Werte (auf 0,01s) für strategische Entscheidungen in der Detailansicht.

### 14.2 Haupt-UI-Zeitkosten-Anzeige

#### 14.2.1 Visuelle Darstellung auf Karten

```tsx
interface TimeCoastDisplay {
  rawValue: number;      // Interner präziser Wert (z.B. 2.34)
  displayValue: number;  // Gerundeter Wert (z.B. 2.5)
  variant: 'card' | 'tooltip' | 'detail';
  showTrendIndicator?: boolean; // Zeigt Änderungen durch Modifikatoren
  elementType?: ElementType; // Für element-spezifisches Styling
}

// Visuelle Specs für Karten-Display
const TIMECOST_CARD_SPECS = {
  position: 'top-right',
  background: 'rgba(0, 0, 0, 0.8)',
  borderRadius: '12px 0 8px 0',
  padding: '4px 8px',
  fontSize: '18px',
  fontWeight: 'bold',
  fontFamily: 'var(--font-monospace)'
};
```

**Design-Details:**
- **Position**: Oben-rechts auf der Karte
- **Hintergrund**: Semi-transparentes Schwarz mit Element-Akzent-Rahmen
- **Schriftart**: Monospace für bessere Zahlenlesbarkeit
- **Format**: "2.5s" mit dem "s" in kleinerer Schriftgröße (14px)
- **Farb-Coding**: 
  - Normal: Weiß (#FFFFFF)
  - Reduziert (durch Effekte): Grün (#4CAF50)
  - Erhöht (durch Effekte): Rot (#FF5722)

#### 14.2.2 Trend-Indikatoren

```tsx
// Visuelle Indikatoren für temporäre Modifikationen
interface TrendIndicator {
  type: 'reduced' | 'increased' | 'neutral';
  percentage: number; // z.B. -15% oder +20%
  source?: string; // "Chronomant Bonus", "Shadow Card Penalty"
}

// Anzeige-Specs
const TREND_INDICATOR_SPECS = {
  reduced: {
    icon: '▼',
    color: '#4CAF50',
    animation: 'pulse-green 2s infinite'
  },
  increased: {
    icon: '▲', 
    color: '#FF5722',
    animation: 'pulse-red 2s infinite'
  }
};
```

### 14.3 Detailansicht-Zugriff

#### 14.3.1 Touch/Klick-Interaktionen

```tsx
interface DetailViewTrigger {
  mobile: {
    gesture: 'long-press';
    duration: 400; // ms
    feedback: 'haptic-light';
  };
  desktop: {
    trigger: 'hover' | 'click-info-icon';
    delay: 200; // ms für Hover
  };
  accessibility: {
    keyboardShortcut: 'Enter' | 'Space';
    ariaLabel: 'Show precise time cost details';
  };
}
```

**Mobile-Interaktion:**
1. **Long-Press** (400ms) auf die Zeitkosten-Anzeige
2. Leichtes haptisches Feedback beim Auslösen
3. Smooth-Transition (200ms) zur Detailansicht
4. Swipe-down oder Tap-außerhalb zum Schließen

**Desktop-Interaktion:**
1. **Info-Icon** (ⓘ) neben der Zeitkosten-Anzeige
2. Hover zeigt kleinen Tooltip mit präzisem Wert
3. Klick öffnet erweiterte Detailansicht
4. ESC-Taste oder Klick-außerhalb zum Schließen

#### 14.3.2 Info-Icon-Design

```css
.timecost-info-icon {
  width: 14px;
  height: 14px;
  margin-left: 4px;
  opacity: 0.6;
  transition: opacity 200ms ease;
  cursor: pointer;
}

.timecost-info-icon:hover {
  opacity: 1;
  transform: scale(1.1);
}

/* Mobile-Anpassung */
@media (max-width: 768px) {
  .timecost-info-icon {
    width: 18px;
    height: 18px;
    opacity: 0.8; /* Besser sichtbar auf Mobile */
  }
}
```

### 14.4 Detailansicht-Design

#### 14.4.1 Modal/Popover-Struktur

```tsx
interface TimeCostDetailView {
  baseValue: number;        // Original-Zeitkosten (2.34s)
  currentValue: number;     // Aktueller Wert nach Modifikatoren
  displayValue: number;     // Gerundeter Anzeige-Wert (2.5s)
  modifiers: Array<{
    source: string;         // "Arkanpuls Bonus"
    effect: number;         // -15 (für -15%)
    type: 'percentage' | 'flat';
    active: boolean;
  }>;
  breakdown: {
    calculation: string;    // "2.34s × 0.85 = 1.989s"
    finalPrecise: string;   // "1.99s"
    finalRounded: string;  // "2.0s"
  };
}
```

#### 14.4.2 Visuelle Gestaltung der Detailansicht

```css
/* Desktop Popover */
.timecost-detail-popover {
  position: absolute;
  background: rgba(20, 20, 30, 0.95);
  border: 1px solid var(--element-color-dim);
  border-radius: 12px;
  padding: 16px;
  min-width: 280px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(12px);
}

/* Mobile Bottom Sheet */
.timecost-detail-sheet {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--bg-surface);
  border-radius: 24px 24px 0 0;
  padding: 24px;
  max-height: 50vh;
  overflow-y: auto;
  box-shadow: 0 -4px 24px rgba(0, 0, 0, 0.2);
}
```

#### 14.4.3 Detailansicht-Inhalt

**Layout-Struktur:**

```tsx
const TimeCostDetailContent = () => (
  <div className="timecost-detail">
    {/* Header mit präzisem Wert */}
    <div className="detail-header">
      <h3>Präzise Zeitkosten</h3>
      <div className="precise-value">1.99s</div>
      <div className="rounded-value-note">
        (Anzeige: 2.0s)
      </div>
    </div>
    
    {/* Basis-Wert */}
    <div className="detail-section">
      <div className="label">Basis-Zeitkosten:</div>
      <div className="value">2.34s</div>
    </div>
    
    {/* Aktive Modifikatoren */}
    <div className="detail-section modifiers">
      <h4>Aktive Modifikatoren:</h4>
      <div className="modifier-item positive">
        <span className="icon">✦</span>
        <span className="name">Arkanpuls-Bonus</span>
        <span className="effect">-15%</span>
      </div>
    </div>
    
    {/* Berechnung */}
    <div className="detail-section calculation">
      <h4>Berechnung:</h4>
      <code>2.34s × 0.85 = 1.989s → 1.99s</code>
    </div>
    
    {/* Rundungs-Hinweis */}
    <div className="rounding-note">
      <InfoIcon size={14} />
      <span>Intern wird mit 0.01s Genauigkeit gerechnet</span>
    </div>
  </div>
);
```

### 14.5 Animation und Transitions

#### 14.5.1 Wert-Änderungs-Animationen

```css
/* Smooth Value Transition */
@keyframes value-change-highlight {
  0% { 
    transform: scale(1);
    filter: brightness(1);
  }
  50% { 
    transform: scale(1.1);
    filter: brightness(1.3);
  }
  100% { 
    transform: scale(1);
    filter: brightness(1);
  }
}

.timecost-display.value-changed {
  animation: value-change-highlight 600ms ease-out;
}

/* Modifier Applied Effect */
@keyframes modifier-applied {
  0% { 
    opacity: 0;
    transform: translateY(-10px);
  }
  100% { 
    opacity: 1;
    transform: translateY(0);
  }
}
```

#### 14.5.2 Detail-View-Transitions

```css
/* Desktop Popover Animation */
.timecost-detail-popover {
  animation: popover-appear 200ms ease-out;
  transform-origin: top right;
}

@keyframes popover-appear {
  0% {
    opacity: 0;
    transform: scale(0.95) translateY(-5px);
  }
  100% {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* Mobile Sheet Animation */
.timecost-detail-sheet {
  animation: sheet-slide-up 300ms ease-out;
}

@keyframes sheet-slide-up {
  0% {
    transform: translateY(100%);
  }
  100% {
    transform: translateY(0);
  }
}
```

### 14.6 Accessibility-Features

```tsx
// Screen Reader Announcements
const TimeCostAccessibility = ({ displayValue, preciseValue, modifiers }) => (
  <>
    {/* Visuell versteckter Text für Screen Reader */}
    <span className="sr-only">
      Zeit-Kosten: {displayValue} Sekunden angezeigt, 
      präziser Wert {preciseValue} Sekunden.
      {modifiers.length > 0 && (
        `${modifiers.length} Modifikatoren aktiv.`
      )}
    </span>
    
    {/* ARIA Live Region für Änderungen */}
    <div 
      role="status" 
      aria-live="polite"
      aria-atomic="true"
      className="sr-only"
    >
      {/* Wird bei Wertänderungen aktualisiert */}
    </div>
  </>
);
```

### 14.7 Performance-Optimierungen

```tsx
// Memoized Rounding Function
const useRoundedTimeCost = (rawValue: number) => {
  return useMemo(() => {
    // Runde auf 0.5s
    return Math.round(rawValue * 2) / 2;
  }, [rawValue]);
};

// Debounced Detail View Updates
const useDetailViewData = (cardId: string) => {
  const [detailData, setDetailData] = useState(null);
  
  const fetchDetailData = useMemo(
    () => debounce((id: string) => {
      // Fetch precise calculations
      calculatePreciseTimeCost(id).then(setDetailData);
    }, 100),
    []
  );
  
  useEffect(() => {
    fetchDetailData(cardId);
  }, [cardId, fetchDetailData]);
  
  return detailData;
};
```

### 14.8 Testing-Szenarien

```tsx
// Beispiel-Tests für Zeitkosten-UI
describe('TimeCost Display', () => {
  test('zeigt gerundeten Wert in Haupt-UI', () => {
    render(<TimeCostDisplay rawValue={2.34} />);
    expect(screen.getByText('2.5s')).toBeInTheDocument();
  });
  
  test('öffnet Detailansicht bei Long-Press', async () => {
    const { getByTestId } = render(<TimeCostDisplay rawValue={2.34} />);
    const display = getByTestId('timecost-display');
    
    fireEvent.touchStart(display);
    await waitFor(() => {
      expect(screen.getByText('1.99s')).toBeInTheDocument();
    }, { timeout: 500 });
  });
  
  test('zeigt korrekte Modifikatoren in Detailansicht', () => {
    const modifiers = [{ source: 'Arkanpuls', effect: -15, type: 'percentage' }];
    render(<TimeCostDetailView modifiers={modifiers} />);
    expect(screen.getByText('Arkanpuls-Bonus')).toBeInTheDocument();
    expect(screen.getByText('-15%')).toBeInTheDocument();
  });
});
```

---

## 15. Implementation-Guidelines

### 14.1 Code-Organisation

**Component-Struktur:**
```
src/
├─ components/
│  ├─ ui/           # Basis-Komponenten (Button, Modal, etc.)
│  ├─ game/         # Game-spezifische Komponenten
│  ├─ forms/        # Form-Controls
│  └─ layout/       # Layout-Komponenten
├─ hooks/           # Custom React Hooks
├─ utils/           # Helper-Funktionen
├─ styles/          # CSS/SCSS-Dateien
├─ assets/          # Bilder, Icons, Sounds
└─ types/           # TypeScript-Typen
```

### 14.2 State-Management

**Zustand-Architektur:**
```tsx
// Global State (Redux/Zustand)
interface GameState {
  player: PlayerState;
  materials: MaterialState;
  cards: CardState;
  ui: UIState;
}

// Local Component State
interface ComponentState {
  loading: boolean;
  error: string | null;
  selectedItems: string[];
  filters: FilterState;
}
```

### 14.3 Testing-Guidelines

**Component-Testing:**
```tsx
// Beispiel-Test für Zeit-Kern-Component
describe('TimeCore Component', () => {
  it('zeigt korrekte Ladung an', () => {
    render(<TimeCore charge={75} element="fire" />);
    expect(screen.getByLabelText(/75% charged/)).toBeInTheDocument();
  });
  
  it('führt Klick-Handler aus', () => {
    const handleClick = jest.fn();
    render(<TimeCore onClick={handleClick} />);
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalled();
  });
});
```

### 14.4 Build & Deployment

**Performance-Budgets:**
- **Initial Bundle**: <250KB (gzipped)
- **JavaScript**: <200KB (gzipped)
- **CSS**: <50KB (gzipped)
- **Images**: WebP mit Fallback, max 100KB pro Asset
- **First Contentful Paint**: <1.5s
- **Time to Interactive**: <3s

Das ist das **komplette UI-Flow & Design-System** für Zeitklingen - production-ready und vollständig implementierbar für Frontend-Entwickler!

