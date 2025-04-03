# TASK.md für "Zeitklingen" Kartenspiel

## 📌 Aktuelle Aufgaben & Prioritäten

Diese Datei dient zur Nachverfolgung der aktuellen Entwicklungsaufgaben für das "Zeitklingen" Kartenspiel. Aufgaben werden priorisiert und nach Abschluss als erledigt markiert.

## 🚀 Phase 1: Konzeptionelle Grundlagen

### Spielregeln & Mechaniken
- [ ] **HOCH**: Detaillierte Spielregeln dokumentieren
  - [ ] Grundlegende Spielmechaniken definieren
  - [ ] Zugablauf festlegen
  - [ ] Ressourcensystem konzipieren (Mana, Energie, etc.)
  - [ ] Siegbedingungen definieren
- [ ] **HOCH**: Zeitmanipulationsmechaniken im Detail ausarbeiten
  - [ ] "Zurückspulen"-Mechanik konzipieren
  - [ ] "Vorausschau"-Mechanik definieren
  - [ ] Interaktion mit anderen Spielmechaniken dokumentieren
- [ ] **MITTEL**: Papierprototyp erstellen und testen
  - [ ] Basiskartenset für Prototyp entwerfen
  - [ ] Testspiele durchführen und Feedback sammeln
  - [ ] Spielregeln basierend auf Testerkenntnissen anpassen

### Kartendesign
- [ ] **HOCH**: Kartentypen definieren
  - [ ] Hauptkategorien festlegen (z.B. Angriff, Verteidigung, Zeit, Utility)
  - [ ] Karteneigenschaften und Attribute definieren
  - [ ] Seltenheitsstufen und Balancing-Rahmen festlegen
- [ ] **HOCH**: Initiales Kartenset von 30 Karten entwerfen
  - [ ] 10 Basiskarten konzipieren
  - [ ] 10 Zeitmanipulationskarten entwerfen
  - [ ] 10 fortgeschrittene/spezielle Karten entwickeln
- [ ] **MITTEL**: Karteninteraktionen und Synergien dokumentieren
  - [ ] Kombo-Möglichkeiten identifizieren
  - [ ] Potenzielle Balance-Probleme vorhersehen

## 🔧 Phase 2: Unity-Grundlagen & Architektur

### Projekt-Setup
- [ ] **HOCH**: Unity-Projekt einrichten
  - [ ] Passende Unity-Version auswählen (2022.3 LTS)
  - [ ] Git-Repository erstellen und .gitignore konfigurieren
  - [ ] Ordnerstruktur gemäß Modularisierungsplan einrichten
- [ ] **MITTEL**: Unity-Packages und Erweiterungen installieren
  - [ ] Notwendige Asset-Packages identifizieren und installieren
  - [ ] UI-Toolkit vs. uGUI evaluieren und Entscheidung treffen
  - [ ] Test-Framework einrichten

### Grundarchitektur
- [ ] **HOCH**: Kernklassen und -interfaces definieren
  - [ ] Model-View-Controller-Struktur implementieren
  - [ ] Spielzustands-Manager erstellen
  - [ ] Event-System für Karteninteraktionen entwickeln
- [ ] **HOCH**: Scriptable Objects für Kartendaten erstellen
  - [ ] Basisklasse für alle Karten definieren
  - [ ] Vererbungshierarchie für verschiedene Kartentypen entwerfen
  - [ ] Editor-Tools für einfache Kartenerstellung konzipieren
- [ ] **MITTEL**: Serialisierungssystem für Spielzustände entwerfen
  - [ ] Anforderungen für Zeitmanipulation berücksichtigen
  - [ ] Effiziente Speicherung von Spielzuständen implementieren

## 🎮 Phase 3: Grundlegende Spielmechaniken

### Spiellogik
- [ ] **HOCH**: Grundlegende Spielschleife implementieren
  - [ ] Rundenbasiertes System umsetzen
  - [ ] Spieler-Wechsel-Logik implementieren
  - [ ] Siegbedingungen prüfen
- [ ] **HOCH**: Kartenspielmechaniken entwickeln
  - [ ] Handkarten-Management implementieren
  - [ ] Kartenzieh- und Abwerfmechaniken erstellen
  - [ ] Ressourcensystem (Mana/Energie) implementieren
- [ ] **MITTEL**: Kampfsystem entwickeln
  - [ ] Schadensberechnung implementieren
  - [ ] Verteidigungsmechanismen einbauen
  - [ ] Statuseffekte (Buff/Debuff) umsetzen

### Zeitmanipulation
- [ ] **HOCH**: Command-Pattern für reversible Aktionen implementieren
  - [ ] Aktion-Historie-System entwickeln
  - [ ] Methoden für Rückgängigmachen von Aktionen erstellen
- [ ] **HOCH**: "Zurückspulen"-Mechanik programmieren
  - [ ] Zustand auf vorherigen Stand zurücksetzen
  - [ ] Visuelle Effekte für Zeitmanipulation konzipieren
- [ ] **MITTEL**: "Vorausschau"-Mechanik entwickeln
  - [ ] Zustandssimulation für mögliche Züge implementieren
  - [ ] UI für Vorschau zukünftiger Spielzustände

## 💻 Phase 4: Benutzeroberfläche

### UI-Grundlagen
- [ ] **HOCH**: Spielfeld-Layout designen
  - [ ] Handkartenbereich gestalten
  - [ ] Spielfeld-Zonen definieren
  - [ ] Spielerinformationsbereiche entwerfen
- [ ] **HOCH**: Kartendesign und -darstellung
  - [ ] Kartenvorlage erstellen
  - [ ] Datenanbindung für dynamische Kartenwerte
  - [ ] Hover- und Auswahleffekte implementieren
- [ ] **MITTEL**: Menüsysteme konzipieren
  - [ ] Hauptmenü entwerfen
  - [ ] Optionsmenü planen
  - [ ] Deck-Editor-UI konzipieren

### Interaktionen
- [ ] **HOCH**: Drag & Drop-System für Karten implementieren
  - [ ] Kartenauswahl und -bewegung programmieren
  - [ ] Legale Spielzonen hervorheben
  - [ ] Fehlerhafte Züge verhindern
- [ ] **MITTEL**: Visuelle Feedback-Mechanismen
  - [ ] Animationen für Kartenspieleffekte
  - [ ] Schadensanzeigen und Heilungseffekte
  - [ ] Zeitmanipulations-Visualisierungen

## 🤖 Phase 5: KI-Gegner

### KI-Grundlagen
- [ ] **HOCH**: Basis-KI-System implementieren
  - [ ] KI-Entscheidungsfindungsframework erstellen
  - [ ] Zugbewertungssystem entwickeln
- [ ] **MITTEL**: Einfache KI-Strategien programmieren
  - [ ] Offensive Strategie implementieren
  - [ ] Defensive Strategie implementieren
  - [ ] Konter-Strategie gegen Zeitmanipulation entwickeln

## 🧪 Phase 6: Testframework

### Unit-Tests
- [ ] **HOCH**: Test-Suite für Kernmechaniken einrichten
  - [ ] Tests für Karteninteraktionen erstellen
  - [ ] Tests für Spielzustandsänderungen implementieren
  - [ ] Zeitmanipulationstests entwickeln
- [ ] **MITTEL**: Regressionstests implementieren
  - [ ] CI/CD-Pipeline für automatisierte Tests konfigurieren

---

## ✅ Erledigte Aufgaben

*Erledigte Aufgaben werden hier aufgeführt mit Abschlussdatum*

---

*Diese Aufgabenliste wird regelmäßig aktualisiert, um den Projektfortschritt widerzuspiegeln.*
