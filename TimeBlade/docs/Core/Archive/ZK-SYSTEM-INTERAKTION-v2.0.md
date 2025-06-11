# Zeitklingen: System-Interaktions-Diagramm (ZK-SYSTEM-INTERAKTION-v2.0-20250521)

## Inhaltsverzeichnis
1. [Einführung](#1-einführung)
2. [Systemübersicht](#2-systemübersicht)
3. [Zeitkern-System: Zentrale Verbindungen](#3-zeitkern-system-zentrale-verbindungen)
4. [Interaktion mit dem Kartenleveling-System](#4-interaktion-mit-dem-kartenleveling-system)
5. [Interaktion mit dem Gate-System](#5-interaktion-mit-dem-gate-system)
6. [Interaktion mit dem Evolutions-System](#6-interaktion-mit-dem-evolutions-system)
7. [Interaktion mit dem Quest-System](#7-interaktion-mit-dem-quest-system)
8. [Interaktion mit dem Projekt-System](#8-interaktion-mit-dem-projekt-system)
9. [Interaktion mit dem Event-System](#9-interaktion-mit-dem-event-system)
10. [Interaktion mit dem Klassenstufen-System](#10-interaktion-mit-dem-klassenstufen-system)
11. [Interaktion mit Währungen und Shop](#11-interaktion-mit-währungen-und-shop)
12. [Technische Implementationshinweise](#12-technische-implementationshinweise)
13. [Abhängige Dokumente](#13-abhängige-dokumente)

---

## 1. Einführung

Dieses Dokument beschreibt die vielfältigen Interaktionen zwischen dem modernisierten Zeitkern-System, dem vereinfachten Materialsystem und den bestehenden Spielsystemen von Zeitklingen. Es dient als Leitfaden für Entwickler, um ein kohärentes und nahtlos integriertes Spielerlebnis zu gewährleisten.

---

## 2. Systemübersicht

```
┌─────────────────────────────────────────────────────────────┐
│                 ZEITKERN-SYSTEM                             │
│                                                             │
│  ┌───────────┐  ┌───────────┐  ┌───────────────────────┐   │
│  │Zeitkern   │  │Zeitkernkit│  │Zeitkern-Verwaltung    │   │
│  │(1 = 1 Lvl)│  │(Auswahl)  │  │(Inventar)             │   │
│  └───────────┘  └───────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         ▲              │                  │                ▲
         │              ▼                  │                │
┌────────┴─────┐ ┌─────────────┐ ┌────────┴─────────┐ ┌────┴─────┐
│Quest-System  │ │Kartenleveling│ │Gate-System      │ │Event-    │
│(Tagesquests, │ │(Direkt)      │ │(Seltene Essenz) │ │System    │
│Weekly) & Proj│ │              │ │                 │ │          │
└──────────────┘ └─────────────┘ └─────────────────┘ └──────────┘
         │              │                  │                │
         │              │                  │                │
┌────────┴──────────────┴──────────────────┴────────────────┴────┐
│                        UI-LAYER                                 │
│  ┌──────────────┐  ┌───────────────┐  ┌────────────────────┐   │
│  │Hauptdashboard│  │Kartenmanager  │  │Materialien-Übersicht│   │
│  └──────────────┘  └───────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         ▲                  │                  ▲
         │                  │                  │
┌────────┴─────────┐  ┌────┴─────┐    ┌───────┴────────┐
│Evolutions-System │  │Sockel-   │    │Klassenstufen & │
│(Elementarfragment│  │System    │    │Meisterschaft   │
│                  │  │          │    │                │
└──────────────────┘  └──────────┘    └────────────────┘
```

### 2.1 Grundprinzipien der Systeminteraktion

* **Ein Material, ein Zweck**: Jedes Material hat eine eindeutige, klare Funktion
* **Direkte Interaktionen**: Vereinfachte, intuitive Systeme mit klaren Verbindungen
* **Bidirektionale Kommunikation**: Systeme können Aktionen auslösen und auf Ereignisse reagieren
* **Datenkonsistenz**: Änderungen werden über eine zentrale Ereignis-Pipeline propagiert
* **Modulare Erweiterbarkeit**: Neue Interaktionen können ohne Änderung existierender Systeme hinzugefügt werden

---

## 3. Zeitkern-System: Zentrale Verbindungen

### 3.1 Hauptschnittstellen

```
                   ┌────── ZEITKERN-SYSTEM ──────┐
                   │                             │
┌─────────────┐    │  ┌────────────────────┐    │    ┌────────────────┐
│Kartensystem │<───┼─>│Zeitkern-Verwendung │    │    │Quest-/Event-   │
│(Direktes    │    │  │(1 Zeitkern = 1 Lvl)│    │<───┤System          │
│Leveling)    │    │  └────────────────────┘    │    │(Materialgewinn)│
└─────────────┘    │          ▲                 │    └────────────────┘
                   │          │                 │
┌─────────────┐    │  ┌───────┴──────────┐     │    ┌────────────────┐
│Gate-System  │<───┼─>│Zeitkernkit-      │<────┼───>│Währungssystem  │
│(Seltenheits-│    │  │Auswahl           │     │    │(Zeitkristalle) │
│upgrade)     │    │  └──────────────────┘     │    └────────────────┘
└─────────────┘    │                           │
                   │  ┌──────────────────┐     │    ┌────────────────┐
┌─────────────┐    │  │Zeitkern-Inventar │     │    │UI-System       │
│Evolutions-  │<───┼─>│Management        │<────┼───>│(Fortschritt,   │
│System       │    │  └──────────────────┘     │    │Feedback)       │
└─────────────┘    └───────────────────────────┘    └────────────────┘
```

### 3.2 Materialverteilung - Übersicht der fünf Materialtypen

```
┌────────────┬────────────────────┬────────────────────────────────────┐
│ Material   │ Ausschließlicher    │ Primäre Quellen                    │
│            │ Verwendungszweck    │                                    │
├────────────┼────────────────────┼────────────────────────────────────┤
│ Zeitkern   │ Kartenleveling      │ Kämpfe, Quests, Events, Projekte   │
│            │ (1 = 1 Level)       │                                    │
├────────────┼────────────────────┼────────────────────────────────────┤
│ Elementar- │ Kartenevolution     │ Elementare Gegner, Quests, Bosse,  │
│ fragment   │ (Stufe 1/2/3)       │ Events                             │
├────────────┼────────────────────┼────────────────────────────────────┤
│ Seltene    │ Gate-Durchbrüche    │ Boss-Kämpfe, Projekte, Weltab-     │
│ Essenz     │ (Level 10/20/30/40) │ schlüsse                           │
├────────────┼────────────────────┼────────────────────────────────────┤
│ Zeitfokus  │ Attribut-Rerolls    │ Zeitlose Kammer, Elite-Gegner,     │
│            │ (Standard/Gezielt/  │ spezielle Events                   │
│            │ Garantiert)         │                                    │
├────────────┼────────────────────┼────────────────────────────────────┤
│ Sockelstein│ Sockelfreischaltung │ Kristallwächter, Schatztruhen,     │
│            │ (Level 10/20)       │ Entdeckungs-Quests                 │
└────────────┴────────────────────┴────────────────────────────────────┘
```

### 3.3 Datenflüsse

* **Zeitkern-Erhalt**: Kampf/Quest/Event → Zeitkern-Gewinn → Inventar-Update
* **Direktes Leveling**: Zeitkern auswählen → Anwenden (zufällige Karte) oder Inventar
* **Gezieltes Leveling**: Zeitkernkit erhalten → Karte auswählen → Direktes Level-Up
* **Auto-Verwendung**: Optional aktivierbar, verwendet Zeitkerne automatisch

---

## 4. Interaktion mit dem Kartenleveling-System

### 4.1 Direktes Leveling mit Zeitkernen

Das alte XP-basierte System wird durch ein direktes Zeitkern-System ersetzt:

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│Spielaktivität │───>│Zeitkern       │───>│Direkte Level- │
│               │    │Erhalt         │    │erhöhung (1:1) │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 4.2 Interaktionsdetails

| Altes System | Vereinfachtes System | Interaktion |
|--------------|----------------------|-------------|
| XP-basiertes Leveling | Direktes Leveling | 1 Zeitkern = 1 Level-Aufstieg |
| Zufällige XP-Verteilung | Wahlweise zufällig/gezielt | Zeitkern = zufällige Karte, Zeitkernkit = ausgewählte Karte |
| XP-Boost-Items | Zeitkernkits | Ermöglichen gezieltes Leveln spezifischer Karten |
| XP-Kurve mit steigenden Anforderungen | Konstanter Wert | Jeweils 1 Zeitkern pro Level, unabhängig vom aktuellen Level |

### 4.3 Level-Gate-System

```
┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│ Level 1-9  │───>│ Level 10   │───>│ Level 11-19│───>│ Level 20   │───>│ Level 21+  │
│            │    │ GATE 1     │    │            │    │ GATE 2     │    │            │
└────────────┘    └────────────┘    └────────────┘    └────────────┘    └────────────┘
                        │                                   │
                        ▼                                   ▼
                 ┌────────────┐                     ┌────────────┐
                 │1× Seltene  │                     │2× Seltene  │
                 │Essenz      │                     │Essenz      │
                 └────────────┘                     └────────────┘
```

---

## 5. Interaktion mit dem Gate-System

### 5.1 Seltenheitsupgrades mit Seltener Essenz

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│Gate-Prüfung  │────>│Seltene Essenz  │────>│Seltenheits-   │
│(Level Check) │     │Anforderung     │     │upgrade        │
└──────────────┘     └────────────────┘     └───────────────┘
       │                                            │
       │                                            │
       └────────────────────────────────────────────┘
                     Attribut-Boost
```

### 5.2 Gate-Anforderungen

| Gate | Level | Material | Menge |
|------|-------|----------|-------|
| G1 (C→U) | 10 | Seltene Essenz | 1× |
| G2 (U→R) | 20 | Seltene Essenz | 2× |
| G3 (R→E) | 30 | Seltene Essenz | 3× |
| G4 (E→L) | 40 | Seltene Essenz | 4× |

### 5.3 Attribut-Boost

Bei jedem Gate-Durchbruch erhält die Karte einen zufälligen Attribut-Boost:

| Seltenheitsupgrade | Attribut-Boost | Attribut-Beispiele |
|--------------------|----------------|-------------------|
| Uncommon (G1) | +10% | Schaden, Zeitkosten, Dauer, etc. |
| Rare (G2) | +20% | Schaden, Zeitkosten, Dauer, Spezialeffekte |
| Epic (G3) | +30% | Schaden, Zeitkosten, Dauer, Spezialeffekte |
| Legendary (G4) | +45% | Schaden, Zeitkosten, Dauer, Spezialeffekte |

Attribut-Boosts können mit Zeitfokus neu gewürfelt werden (Reroll-System).

---

## 6. Interaktion mit dem Evolutions-System

### 6.1 Evolutionsintegration

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│Evolution     │────>│Elementarfragment│────>│Neue Karten-   │
│Anforderung   │     │Anforderung     │     │funktionalität │
└──────────────┘     └────────────────┘     └───────────────┘
```

### 6.2 Evolutions-Anforderungen

| Evolution | Level | Elementarfragment |
|-----------|-------|-------------------|
| Evo 1 | 9 | 1× |
| Evo 2 | 25 | 2× |
| Evo 3 | 35 | 3× |

### 6.3 Elementarpfade

* **Feuer**: Fokus auf DoT-Schaden und offensive Stärke
* **Eis**: Fokus auf Kontrolle und defensive Stärke
* **Blitz**: Fokus auf Tempo und Synergie-Effekte

Die Wahl des Elementarpfads bei Evolution 1 legt fest, welche Pfade bei Stufe 2 und 3 verfügbar sind.

---

## 7. Interaktion mit dem Quest-System

### 7.1 Quest-Struktur-Integration

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│Quest-Abschluss│────>│Materialbelohnungen│───>│Zeitkernkit bei│
│(Tagesquest)   │     │(Zeitkern etc.) │    │3 Quests       │
└──────────────┘     └────────────────┘     └───────────────┘
```

### 7.2 Materialbelohnungen pro Questtyp

| Quest-Kategorie | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus | Sockelstein |
|-----------------|----------|-------------------|---------------|-----------|------------|
| Kampf | 2-3 | 0-1 | - | 0-1 | - |
| Entdeckung | 1-2 | 0-1 | - | 1-2 | 0-1 |
| Element-spezifisch | 2-3 | 1 | - | - | - |
| Weltboss | 5-8 | 1-2 | 1 | 1-2 | 0-1 |
| Meisterschaftsquest | 3-5 | 1 | 0-1 | 1 | - |

### 7.3 Zeitkernkit-System

* **Erhalt**: Automatisch nach je 3 abgeschlossenen Tagesquests
* **Kapazität**: Max. 10 Zeitkernkits im Inventar
* **Wirkung**: Ermöglicht gezieltes Leveln einer ausgewählten Karte (+1 Level)
* **Premium-Option**: Zeitkristalle können zum Kauf von Zeitkernkits verwendet werden (150 ZK pro Kit)

---

## 8. Interaktion mit dem Projekt-System

### 8.1 Projektintegration

```
┌───────────────┐     ┌────────────────┐     ┌───────────────┐
│Projekt-       │────>│Meilenstein-    │────>│Materialbelohn-│
│Fortschritt    │     │Belohnungen     │     │ungen & Kits   │
└───────────────┘     └────────────────┘     └───────────────┘
```

### 8.2 Projekt-Belohnungsmatrix

| Projektgröße | Dauer | Meilensteine | Zeitkern | Andere Materialien |
|--------------|-------|--------------|---------|-------------------|
| Klein | 2-3 Tage | 3 | 8-12 | 1-3× Elementarfragment, 0-1× Seltene Essenz |
| Mittel | 5-7 Tage | 5 | 15-25 | 2-5× Elementarfragment, 1-2× Seltene Essenz, 1-3× Zeitfokus |
| Groß | 10-14 Tage | 7 | 30-40 | 5-8× Elementarfragment, 2-3× Seltene Essenz, 3-5× Zeitfokus, 1× Sockelstein |
| Episch | 20-30 Tage | 10 | 50-75 | 10-15× Elementarfragment, 3-5× Seltene Essenz, 5-8× Zeitfokus, 2-3× Sockelstein |

### 8.3 Projekttypen und Spezialisierungen

* **Elementar-Projekte**: Auf ein Element spezialisiert, bieten mehr Elementarfragmente
* **Zeit-Anomalien**: Fokus auf Zeitfokus und Seltene Essenz
* **Ausrüstungs-Projekte**: Fokus auf Sockelsteine
* **Welt-Projekte**: Weltspezifisch, bieten ausgeglichene Materialbelohnungen

---

## 9. Interaktion mit dem Event-System

### 9.1 Eventintegration

```
┌───────────────┐     ┌────────────────┐     ┌───────────────┐
│Event-Teilnahme│────>│Materialgewinne │────>│Spezielle Event│
│& Fortschritt  │     │& Belohnungen   │     │-Mechaniken    │
└───────────────┘     └────────────────┘     └───────────────┘
```

### 9.2 Event-Materialbelohnungen

| Event-Typ | Häufigkeit | Primäre Materialien | Sekundäre Materialien |
|-----------|------------|---------------------|------------------------|
| Stündlich | 24/Tag | 2-5× Zeitkern | 0-1× Elementarfragment |
| Täglich | 1/Tag | 5-10× Zeitkern, 1-3× Elementarfragment | 0-1× Seltene Essenz, 1-2× Zeitfokus |
| Wöchentlich | 1/Woche | 15-25× Zeitkern, 3-5× Elementarfragment | 1-2× Seltene Essenz, 2-4× Zeitfokus, 0-1× Sockelstein |
| Zeit-Anomalie | Mi/Do | 20-35× Zeitkern, 5-8× Elementarfragment | 2-3× Seltene Essenz, 3-6× Zeitfokus, 1× Sockelstein |
| Weltenboss | Fr-So | 30-50× Zeitkern, 5-10× Elementarfragment | 2-4× Seltene Essenz, 5-10× Zeitfokus, 1-2× Sockelstein |
| Saisonal | Alle 4-6 Wochen | 50-100× Zeitkern, 10-20× Elementarfragment | 5-10× Seltene Essenz, 10-20× Zeitfokus, 2-5× Sockelstein |

### 9.3 Event-Spezialeffekte

* **Zeit-Fluss**: Während bestimmter Events werden Zeitkern-Drops um 50-100% erhöht
* **Element-Resonanz**: Elementar-Events erhöhen Elementarfragment-Drops um 100-200%
* **Essenz-Schauer**: Spezielle Events mit erhöhten Seltene-Essenz-Drops
* **Fokus-Sammlung**: Events mit Fokus auf Zeitfokus-Materialien
* **Sockeljagd**: Speziell für Sockelstein-Beschaffung

---

## 10. Interaktion mit dem Klassenstufen-System

### 10.1 Klassenstufen-Integration

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│Klassenstufen-│────>│Max-Level-      │────>│Erweiterte     │
│Erhöhung      │     │Erhöhung        │     │Materialnutzung│
└──────────────┘     └────────────────┘     └───────────────┘
```

### 10.2 Klassenstufen-Limitierungen

| Klassenstufe | Max Kartenlevel | System-Limitierung |
|--------------|-----------------|-------------------|
| 1-5 | 10 | Gate 1 ist maximal erreichbar |
| 6-10 | 20 | Gate 2 ist maximal erreichbar |
| 11-15 | 30 | Gate 3 ist maximal erreichbar |
| 16-20 | 40 | Gate 4 ist maximal erreichbar |
| 21-25 | 50 | Maximales Level erreichbar |

### 10.3 Klassenspezifische Material-Interaktionen

* **Zeitwächter**: Erhöhte Effektivität für Seltene Essenz (+25% Chance auf Bonus-Effekt)
* **Schattenschreiter**: Verbesserte Elementarfragment-Nutzung (25% Chance, nicht verbraucht zu werden)
* **Chronomant**: Stärkere Zeitfokus-Effekte (25% erhöhte Wahrscheinlichkeit für gewünschtes Attribut)

---

## 11. Interaktion mit Währungen und Shop

### 11.1 Währungsintegration

```
┌──────────────┐     ┌────────────────┐     ┌───────────────┐
│Zeitkristall- │────>│Premium-        │────>│Beschleunigte  │
│Verwendung    │     │Optionen        │     │Progression    │
└──────────────┘     └────────────────┘     └───────────────┘
```

### 11.2 Premium-Optionen im vereinfachten System

| Option | Zeitkristall-Kosten | Effekt | Einschränkung |
|--------|---------------------|--------|---------------|
| Zeitkernkit kaufen | 150 ZK | +1 Zeitkernkit (gezieltes Level-Up) | Max. 3/Tag |
| Elementarfragment kaufen | 100 ZK | +1 Elementarfragment | Max. 5/Woche |
| Seltene Essenz kaufen | 250 ZK | +1 Seltene Essenz | Max. 3/Woche |
| Zeitfokus kaufen | 50 ZK | +1 Zeitfokus | Max. 10/Woche |
| Sockelstein kaufen | 200 ZK | +1 Sockelstein | Max. 2/Woche |

### 11.3 Balance-Überlegungen

* **F2P-Pfad**: Vollständige Progression ohne Zeitkristalle möglich, aber langsamer
* **Soft-Monetarisierung**: Beschleunigung, nicht Freischaltung exklusiver Inhalte
* **Wert-Relation**: Kosteneffizienz von Materialien zu Zeitkristallen ist ausbalanciert
* **Zeitersparnis**: Premium-Optionen sparen Zeit, nicht Spielinhalte

---

## 12. Technische Implementationshinweise

### 12.1 Datenbank-Erweiterungen

Folgende Tabellen müssen zur Supabase-Datenbank hinzugefügt werden:
* `player_materials` (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus, Sockelstein)
* `material_transactions` (Erhalt, Verwendung, Transaktionshistorie)
* `zeitkernkit_inventar` (Spieler-Kits)
* `player_settings` (Auto-Verwendung, UI-Präferenzen)

### 12.2 Client-Server-Kommunikation

* **Material-Events**: WebSocket für Echtzeit-Aktualisierungen
* **Verwendungs-Transaktionen**: REST-API mit Optimistic UI-Updates
* **Batch-Operationen**: Unterstützung für Massen-Verwendung von Materialien
* **Offline-Unterstützung**: Lokale Queuing von Material-Operationen

### 12.3 UI-Anforderungen

* **Material-Widget**: Permanente Anzeige im Hauptbildschirm
* **Detailansicht**: Verwaltungsinterface für alle Materialien
* **Animation**: Flüssige Visualisierung von Materialverwendung
* **Sound-Design**: Akustisches Feedback für Material-Ereignisse

---

## 13. Abhängige Dokumente

* `ZK-ZEITKERN-SYSTEM-v1.0.md`: Detaillierte Beschreibung des modernisierten Zeitkern-Systems
* `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`: Definition des vereinfachten 5-Material-Systems
* `ZK-KARTENPROGRESSION-v2.0.md`: Aktualisierte Informationen zum Kartenleveling-System
* `ZK-DROP-RATEN-v2.0.md`: Detaillierte Drop-Raten für das vereinfachte Materialsystem
* `ZK-ECONOMY-BALANCING-v2.0.md`: Wirtschaftliches Balancing des Materialsystems
* `ZK-Klassenstufen- und Meisterschaftssystem-v1.0-.md`: Details zum Klassenstufen-System
* `Zeitklingen: Progression & Hook-Mechaniken-v1.3-.md`: Pacing und Hook-Definitionen
* `ZK-TIME-.md`: Grundlegendes Zeitmechanik-Konzept