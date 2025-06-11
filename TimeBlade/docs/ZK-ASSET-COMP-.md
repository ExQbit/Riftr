# Asset-Management-Spezifikation (ZK-ASSET-COMP-v1.0-20250325)

## Änderungshistorie
- v1.0 (2025-03-25): Komprimierte Version von ZK-ASSET-v1.0-20250325

## Zusammenfassung
Standards und Prozesse für digitale Assets im Zeitklingen-Projekt: Benennungskonventionen, Ordnerstrukturen, Qualitätsrichtlinien und Workflows. Gewährleistet Konsistenz, Wiederauffindbarkeit und optimale Performance.

## 1. Asset-Benennungskonventionen

### 1.1 Allgemeine Regeln
- Nur englische Bezeichnungen
- Keine Umlaute/Sonderzeichen/Leerzeichen
- PascalCase für Hauptnamen, Unterstriche für Präfixe/Suffixe
- Nummerierung mit führenden Nullen (01, 02)
- Maximal 32 Zeichen

### 1.2 Präfixstruktur
| Asset-Typ | Präfix | Beispiel |
|-----------|--------|----------|
| Texturen | TEX_ | TEX_CardFrame |
| Materialien | MAT_ | MAT_TimeEffect |
| Modelle | MDL_ | MDL_TimeCrystal |
| Animationen | ANIM_ | ANIM_CardPlay |
| Partikeleffekte | FX_ | FX_TimeWarp |
| Sounds | SFX_ | SFX_CardDraw |
| Musik | MUS_ | MUS_Battle |
| Prefabs | PRF_ | PRF_Card |
| Szenen | SCN_ | SCN_MainMenu |
| Skripte | SCR_ | SCR_CardManager |
| Shader | SHD_ | SHD_TimeWarp |
| UI-Elemente | UI_ | UI_TimerBar |

### 1.3 Suffixsystem
| Suffix | Bedeutung | Beispiel |
|--------|-----------|----------|
| _SM | Small-Variante | TEX_CardFrame_SM |
| _MD | Medium-Variante | TEX_CardFrame_MD |
| _D | Diffuse-Map | TEX_TimeEffect_D |
| _N | Normal-Map | TEX_TimeEffect_N |
| _LOD0, _LOD1 | Level-of-Detail | MDL_Crystal_LOD0 |
| _01, _02 | Sequenzielle Varianten | ANIM_CardPlay_01 |

### 1.4 Element-Kennzeichnungen
| Element | Kennung | Beispiel |
|---------|---------|----------|
| Feuer | FIR | TEX_FIR_CardEffect |
| Eis | ICE | TEX_ICE_CardEffect |
| Blitz | LIT | TEX_LIT_CardEffect |
| Zeit | TIM | TEX_TIM_CardEffect |
| Neutral | NEU | TEX_NEU_CardEffect |

## 2. Ordnerstruktur

### 2.1 Hauptstruktur
```
Assets/
  ├── Art/
  │   ├── Textures/
  │   ├── Materials/
  │   ├── Models/
  │   ├── Animations/
  │   └── VFX/
  ├── Audio/
  │   ├── SFX/
  │   └── Music/
  ├── Prefabs/
  ├── Scenes/
  ├── Scripts/
  ├── Shaders/
  ├── UI/
  ├── Resources/
  └── StreamingAssets/
```

### 2.2 Asset-Paketierung
| Asset-Paket | Inhalt | Ladezeitpunkt |
|-------------|--------|---------------|
| CoreGameplay | Grundlegende Assets | Immer geladen |
| UI_Core | Essentielle UI-Elemente | Immer geladen |
| Cards_Common | Gemeinsame Kartenassets | Nach Tutorial |
| Cards_CHR | Chronomant-Assets | Bei Klassenauswahl |
| Cards_WAR | Zeitwächter-Assets | Bei Klassenauswahl |
| Cards_ROG | Schattenschreiter-Assets | Bei Klassenauswahl |
| Effects_* | Elementareffekte | Bei Bedarf |

## 3. Qualitätsrichtlinien

### 3.1 Texturoptimierung
| Asset-Typ | Format | Kompression | Auflösungen |
|-----------|--------|-------------|------------|
| UI-Elemente | PNG | UI-Kompression | 1x, 2x, 3x |
| Kartenrahmen | PNG | UI-Kompression | 256x384, 512x768 |
| Kartenillustration | JPG | Hohe Qualität | 256x384, 512x768 |
| Effekte | PNG mit Alpha | Standard | 256x256, 512x512 |
| Icons | PNG mit Alpha | UI-Kompression | 64x64, 128x128 |
| Hintergründe | JPG | Standard | 1280x720, 1920x1080 |

### 3.2 Audio-Standards
| Audio-Typ | Format | Qualität | Kanäle | Sample-Rate | Max. Größe |
|-----------|--------|----------|--------|-------------|------------|
| UI-Effekte | OGG | 70% | Mono | 22050 Hz | 50 KB |
| Karteneffekte | OGG | 80% | Stereo | 44100 Hz | 150 KB |
| Ambiente | OGG | 80% | Stereo | 44100 Hz | 1 MB |
| Musik | OGG | 85% | Stereo | 44100 Hz | 5 MB |

### 3.3 Modell- und Animationsrichtlinien
| Asset-Typ | Budget (Dreiecke) | LOD-Stufen |
|-----------|-------------------|------------|
| Karten (3D) | 500-1000 | 2 (LOD0: 100%, LOD1: 50%) |
| Effekte | 200-500 | 1 |
| UI-Elemente (3D) | 100-200 | 1 |

### 3.4 Plattformspezifische Optimierungen

#### 3.4.1 Mobile
- Texturen: ASTC, max. 1024x1024
- Modelle: 50% des Standard-Budgets
- Shader: Vereinfacht
- Audio: 70% Qualität

#### 3.4.2 Desktop
- Texturen: BC7, bis 2048x2048
- Modelle: Volles Budget
- Shader: Vollwertig
- Audio: 85% Qualität

## 4. Asset-Pipeline

### 4.1 Workflow
```
KONZEPTION → ERSTELLUNG → OPTIMIERUNG → INTEGRATION → TESTS → RELEASE
   │             │              │            │           │        │
Anforderung   Rohversion    Kompression   Unity-      Performance  Tags
Concept-Art   Arbeitsdateien   LODs      Import      Visueller Test Bundles
Tech-Vorgaben  Iterationen   Formate    Einbindung   Kompatibilität Dokument
```

### 4.2 Arbeitsdateistandards
| Asset-Typ | Arbeitsformat | Exportformat | Archivierung |
|-----------|---------------|--------------|--------------|
| Texturen | PSD | PNG/JPG | Arbeitsdateien |
| 3D-Modelle | FBX/Blender | FBX | Arbeitsdateien |
| Audio | WAV | OGG | Originale |
| VFX | VFX Graph | Prefab | Graph-Setups |

### 4.3 Kollaborationsprozess
1. Asset-Request-Ticket
2. Detaillierte Spezifikation
3. Umsetzung durch Asset-Ersteller
4. Review
5. Iteration bei Bedarf
6. Finale Freigabe und Integration

## 5. Kartenvisualisierung

### 5.1 Kartenrahmen-Spezifikation
```
┌─────────────────┐
│   Kartentitel   │ 25% der Höhe
├─────────────────┤
│                 │
│ Illustration    │ 50% der Höhe
│                 │
├─────────────────┤
│   Kartentext    │ 15% der Höhe
├─────────────────┤
│ Zeit: X.Xs      │ 10% der Höhe
└─────────────────┘
```

### 5.2 Elementare Farbcodierung
| Element | Primärfarbe | Sekundärfarbe | Glow-Farbe |
|---------|-------------|---------------|------------|
| Feuer | #FF5722 | #FFC107 | #FF9E80 |
| Eis | #29B6F6 | #B3E5FC | #80D8FF |
| Blitz | #7E57C2 | #D1C4E9 | #B388FF |
| Zeit | #00BCD4 | #E0F7FA | #84FFFF |
| Neutral | #9E9E9E | #F5F5F5 | #EEEEEE |

### 5.3 Evolutionsvisualisierung
- **Basis**: Subtile Farbverschiebung und Detailerhöhung
- **Zweite Evolution**: Elementareffekte und Formveränderung
- **Dritte Evolution**: Transformation mit konstanten Partikeleffekten
- **Animation**: 2s-Transformation mit Partikelexplosion

## 6. Asset-Validierung

### 6.1 Checkliste
- [ ] Korrekte Namenskonvention
- [ ] Richtige Ordnerplatzierung
- [ ] Optimierte Dateigröße
- [ ] Mobile-Kompatibilität
- [ ] Performance-Test
- [ ] Visuelle Prüfung in verschiedenen Auflösungen
- [ ] Plattformkompatibilität
- [ ] Vollständige Metadaten

### 6.2 Validierungskriterien
| Kriterium | Akzeptiertes Minimum | Optimum |
|-----------|----------------------|---------|
| Ladezeit | < 100ms | < 50ms |
| Speicherverbrauch | Klassenspezifisch | 25% unter Maximum |
| Visuelle Qualität | Keine Artefakte | Keine Kompressionsartefakte |
| Performance-Impact | < 1ms Renderzeit | < 0,5ms Renderzeit |

## 7. Asset-Metadaten

### 7.1 Metadaten-Informationen
- **Creation Date**: Erstellungsdatum
- **Author**: Asset-Ersteller
- **Version**: Versionsnummer (v1.0, v1.1)
- **Status**: WIP, Review, Approved, Deprecated
- **Dependencies**: Liste abhängiger Assets
- **Tags**: Suchbegriffe

### 7.2 Inventar-Struktur
- **Hauptkategorien**: Zeit, Elementar, Qualität, Spezial
- **Sortierung**: Name, Seltenheit, Menge, Neuheit, Element
- **Filter**: Seltenheit, Verwendbarkeit, Element, Zweck

## Quellendokumente
- ZK-PROJ-v1.0-20250325: Projektübersicht
- ZK-TECH-v1.0-20250325: Technischer Designleitfaden

## Abhängige Dokumente
- ZK-EVO-v1.0-20250325: Evolutionssystem
- ZK-CLASS-MAGE-CARDS-v1.0-20250325: Chronomant-Karten
- ZK-TIME-v1.0-20250325: Zeitsystem