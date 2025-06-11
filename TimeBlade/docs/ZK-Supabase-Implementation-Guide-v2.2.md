# Schattenschreiter: Momentum-System Dokumentation (Überarbeitet V2.2) - Implementation Guide Supabase

## Änderungshistorie

* **v2.2 (2025-04-21):** Dokument umfassend an die Implementierung der Zeitwächter-Klasse (WAR) angepasst und generalisiert. WAR-spezifische Beispiele hinzugefügt (`classes.mechanics_config`, `cards.effect_data`, `card_evolutions.effect_data`, `class_evolution_mechanics`). Tabellenbeschreibungen präzisiert und aktualisiert (gültige `card_type`-Werte, erweiterte `mechanic_tags`, detaillierte `effect_data`-Nutzung, Trennung von Materialkosten/globalen Overrides). Umgang mit der (obsoleten) `chain_effectiveness`-Spalte dokumentiert. Hinweise im Pseudocode zur Generalisierung für verschiedene Klassen und spezifische WAR-Logik ergänzt. Abschnitt mit Implementierungsentscheidungen hinzugefügt.
* **v2.1 (2025-04-19):** Dokument vollständig an die Regeln aus `ZK-CLASS-ROG-v2.1-.md` und die finale Datenbankstruktur angepasst. Neue Tabellen `class_evolution_mechanics` und `evolution_requirements` eingeführt und beschrieben. `classes.mechanics_config` bereinigt. Logik für globale Mechanik-Overrides (Zeitsprung) und Materialkosten ausgelagert. Pseudocode und Erklärungen entsprechend aktualisiert. Hinweis zum Merging präzisiert. *(Basiert auf vorheriger v2.0)*
* **V1.0 (2025-04-19):** Hinweis zum korrekten Merging von JSON-Overrides bei `class_evolution_mechanics.mechanics_override` hinzugefügt. Dateiname angepasst zur Verdeutlichung des Inhalts (Implementation Guide). *(Basierte auf vorheriger Supabase-system-docs.md)*
* **V2.1 (16.04.2025):** *(Vorherige interne Änderungen)* Klärung/Umbenennung von `cost_reduction_amount`, Definition wichtiger Tags und `effect_data`-Schlüssel hinzugefügt.
* **V2 (16.04.2025):** *(Vorherige interne Änderungen)* Klarstellung: Kombos sind Strategien. Fokus auf allgemeine Karteneffekte & Synergien. Trennung der 0-Kosten-Mechaniken. Bereinigung der `effect_data`-Beispiele. Anpassung der Programmier-Guidelines.

## Grundlegende Klassenmechaniken (Beispiele: Schattenschreiter & Zeitwächter)

Die zentralen Parameter für klassenspezifische Mechaniken (z.B. Momentum/Zeitsplitter beim Schattenschreiter, Chrono-Energie/Zeitlicher Wächter beim Zeitwächter) sind in der `classes`-Tabelle in der Spalte `mechanics_config` als JSONB gespeichert. Globale Anpassungen dieser Mechaniken durch Signaturkarten-Evolutionen werden in `class_evolution_mechanics` gespeichert.

*(Die detaillierten Beschreibungen für ROG Momentum/Zeitsplitter und Schattensynergie bleiben wie in v2.1)*

### Beispiel: Momentum-System Funktionsweise (ROG)

*(Bleibt wie in v2.1)*

### Beispiel: Zeitsplitter Funktionsweise (ROG)

*(Bleibt wie in v2.1)*

*(Hier könnte man analoge Abschnitte für WAR Chrono-Energie hinzufügen, falls gewünscht)*

## Wichtige Tabellen & Spalten im Detail

### Tabelle: `classes`

Enthält die Basis-Definitionen für jede spielbare Klasse.

* `id` (uuid): PK
* `name` (text), `code_name` (text), `description` (text), `deck_size` (integer), `class_passive` (text), `specialty_mechanic` (text), `recommended_playstyle` (text), etc.
* `mechanics_config` (jsonb): Enthält die **Basis-Konfigurationsparameter** für die Kernmechaniken der jeweiligen Klasse. Diese Konfiguration wird zur Laufzeit geladen und kann durch Einträge in `class_evolution_mechanics` modifiziert werden.
    * **Beispielstruktur (ROG - Schattenschreiter):**
        ```json
        {
          "momentum": { // Momentum-System für ROG
            "max": 5,
            "bruch": { // Basis-Bruch-Effekt (Schattenrausch)
              "effect": "shadow_rush",
              "duration": 5,
              "threshold": 5,
              "momentum_reset": 0,
              "effect_multiplier_value": 0.25
            },
            "decay_time": 3,
            "threshold_shift": 0,
            "thresholds": [
              {"value": 2, "effect": "attack_damage_boost", "multiplier": 0.1},
              {"value": 3, "effect": "shadow_free_cast", "cost_reduction": 1.0},
              {"value": 4, "effect": "time_gain_per_card", "time_gain": 0.5}
            ],
            "free_cast_momentum_cost": 2,
            // Weitere ROG-spezifische Parameter...
          },
          "zeitsplitter": { // Zeitsplitter-System für ROG
            "theft_boost": 0.5,
            "max_theft_gain": 12,
            "trigger_card_id": "816ec03a-3011-4f99-986a-083127eaa24c",
            "health_threshold": 0.3,
            "theft_count_trigger": 3
          }
        }
        ```
    * **Beispielstruktur (WAR - Zeitwächter):**
        ```json
        {
          "zeitlicher_waechter": { // Phasen-Mechanik für WAR
            "initial_theft_reduction": 0.3,
            "initial_protection_duration": 20,
            "defense_time_gain_threshold": 30,
            "defense_time_gain": 0.5,
            "low_time_threshold": 15,
            "next_card_cost_reduction": 0.15
          },
          "chrono_energie": { // Chrono-Energie-System für WAR
            "max_points": 5,
            "base_gain_per_block": 1,
            "bruch_reset_value": 0,
            "bruch_effect": { // Basis-Bruch-Effekt "Zeitliche Entladung"
              "name": "zeitliche_entladung",
              "damage": 15,
              "time_steal": 2.0
            },
            "thresholds": [ // Passive Boni
              { "value": 2, "effect": "block_time_gain", "time_gain": 0.5 },
              { "value": 3, "effect": "attack_damage_boost", "damage_boost": 1 },
              { "value": 4, "effect": "theft_immunity", "count": 1 }
            ]
          }
        }
        ```
* `created_at`, `updated_at`: Standard-Zeitstempel (falls vorhanden in der Tabelle).

### Tabelle: `cards`

Enthält die Definitionen der Basis-Karten für alle Klassen.

* `id` (uuid): Primärschlüssel der Karte.
* `name` (text): Angezeigter Name der Karte.
* `card_type` (text): Typ der Karte. Muss einem der im `cards_card_type_check` Constraint definierten Werte entsprechen. Gültige Werte (Stand 21.04.2025): `'Basiszauber'`, `'Zeitmanipulation'`, `'Signatur'`, `'Verteidigung'`.
* `class_id` (uuid, FK -> classes.id): Zugehörige Klasse.
* `base_time_cost` (numeric): Grundlegende Zeitkosten der Karte.
* `effect_description` (text): Textuelle Beschreibung des Effekts für die Anzeige im Spiel.
* `element` (text): Element der Basiskarte (i.d.R. 'neutral').
* `rarity` (text): Seltenheit der Basiskarte ('common', 'rare', 'epic').
* `image_url` (text): URL zum Kartenbild (optional).
* `deck_count` (integer): Wie oft diese Karte im Standard-Startdeck der Klasse vorkommt.
* `evolution_level` (integer): Immer `0` für Basis-Karten.
* `mechanic_tags` (text[]): Array von Tags, die die Mechaniken der Karte beschreiben und von der Spiellogik genutzt werden. Beispiele: `{ATTACK}`, `{DEFENSE}`, `{BLOCK}`, `{REFLECTION}`, `{BUFF}`, `{DEBUFF}`, `{TIME_GAIN}`, `{DRAW_CARD}`, `{COST_REDUCTION}`, `{DOT}`, `{SLOW}` (für WAR); `{shadow}`, `{momentum}`, `{zeitsplitter}` (für ROG). Wichtig z.B. für den Schild-Schwert-Zyklus (WAR), der auf `{ATTACK}` und `{DEFENSE}` Tags prüft und dessen Logik **nicht** in `classes.mechanics_config` gespeichert wird.
* `dot_category_id` (uuid, FK -> dot_categories.id): Verweis auf eine DoT-Kategorie, falls die Basiskarte direkt einen DoT verursacht (selten, meist `NULL` für Basiskarten).
* `effect_data` (jsonb): JSON-Objekt zur strukturierten Speicherung von **karten-spezifischen** Effektparametern, Boni, Bedingungen oder Triggern, die über die reine Textbeschreibung hinausgehen oder für die Spiellogik direkt auslesbar sein sollen. Enthält **keine** globalen Regeln. Der Inhalt variiert stark je nach Karte.
    * **Beispiel (WAR - Schildschlag):** Speichert Basisschaden und den Buff.
        ```json
        {"damage": 5, "buff": {"type": "time_theft_protection", "value": 0.15, "duration": 2}}
        ```
    * **Beispiel (WAR - Zeitblock):** Speichert Blockdauer und Zeitgewinn.
        ```json
        {"block": {"duration": 4}, "time_gain": 0.5}
        ```
    * **Beispiel (WAR - Zeitwächter-Fokus):** Speichert Trigger und Effekt.
        ```json
        {"trigger": {"condition": "successful_defense"}, "effect": {"type": "time_gain", "value": 1.5}}
        ```
    * **Beispiel (ROG - Schattendolch):** Speichert Momentum-abhängigen Bonus.
        ```json
        {"damage": 3, "momentum_effects": {"threshold": 4, "bonus_damage": 2, "draw_cards": 1}}
        ```
* *(Hinweis: Diese Tabelle scheint keine `created_at`/`updated_at`-Spalten zu haben.)*

### Tabelle: `card_evolutions`

Enthält die Definitionen der weiterentwickelten Formen der Basis-Karten.

* `id` (uuid): Primärschlüssel der Evolution.
* `card_id` (uuid, FK -> cards.id): Verweis auf die zugehörige Basis-Karte.
* `evolution_path` (text): Der gewählte Entwicklungspfad (z.B. 'fire', 'ice', 'lightning', 'neutral').
* `evolution_level` (integer): Die Stufe der Evolution (üblicherweise 1, 2, 3).
* `name` (text): Der Name der spezifischen Evolution (z.B. 'Flammenschwert').
* `time_cost` (numeric): Die Zeitkosten dieser Evolutionsstufe (können sich von der Basis unterscheiden).
* `effect_description` (text): Textuelle Beschreibung des Effekts dieser Evolution für die Anzeige im Spiel.
* `mechanic_tags` (text[]): Array von Tags für diese Evolutionsstufe. Kann sich zur Basis-Karte ändern (z.B. Hinzufügen von `{DOT}`, `{SLOW}`, `{SCALING}`, `{CHRONO_ENERGY_INTERACT}`, `{IMMUNITY}`).
* `dot_category_id` (uuid, FK -> dot_categories.id): Verweis auf eine DoT-Kategorie, falls diese Evolution einen DoT-Effekt hinzufügt oder ändert.
* `effect_data` (jsonb): JSON-Objekt zur strukturierten Speicherung der spezifischen Effektparameter dieser Evolution. Überschreibt oder ergänzt die `effect_data` der Basiskarte. Enthält **keine** globalen Mechanik-Overrides (diese gehören in `class_evolution_mechanics`) und **keine** Materialkosten (diese gehören in `evolution_requirements`).
    * **Beispiel (WAR - Rächerschwert):** Schaden, DoT und skalierender Bonusschaden.
        ```json
        {"damage": 5, "dot": {"category_id": "ed08f7d9..."}, "scaling_damage": {"condition": "per_block_in_combat", "value": 1}}
        ```
    * **Beispiel (WAR - Blitzschild):** Block, Kartenziehen mit Kostenreduktion für gezogene Karten.
        ```json
        {"block": {"duration": 4}, "card_draw": 2, "buff": {"target": "drawn_cards", "effect": "cost_reduction", "value": 0.5}}
        ```
    * **Beispiel (WAR - Zeitfestung Evo - *Nur direkte Effekte*):** Zeitgewinn, Buffs, Kartenziehen. Die Modifikation der globalen Chrono-Energie steht in `class_evolution_mechanics`.
        ```json
        {"time_gain": 4, "buff": [{"type": "time_theft_reduction", ...}, {"type": "time_theft_immunity", ...}], "card_draw": 1, "next_combo_buff": ...}
        ```
    * **Beispiel (Kettenblitz):** Informationen zu Kettenblitzen (Ziele, Effektivität) werden ebenfalls hier gespeichert, z.B.:
        ```json
        {"damage": ..., "chain_lightning": {"targets": 2, "damage_transfer_percent": 70}}
        ```
* *(Hinweis: Eine separate Spalte `chain_effectiveness` wird nicht verwendet/ist obsolet. Diese Information ist Teil von `effect_data`.)*
* *(Hinweis: Auch diese Tabelle scheint keine `created_at`/`updated_at`-Spalten zu haben.)*

### Tabelle: `class_evolution_mechanics`

* **Zweck:** Speichert **globale** Änderungen an den Basis-Klassenmechaniken (definiert in `classes.mechanics_config`), die durch die Wahl eines bestimmten Evolutionspfades einer **Signaturkarte** aktiv werden. Diese Overrides modifizieren die Funktionsweise der Klassenmechanik für den Spieler, solange der entsprechende Pfad aktiv ist.
* **Spalten:**
    * `id` (uuid, PK): Eindeutige ID für den Override-Eintrag.
    * `class_id` (uuid, FK -> classes.id): Die Klasse, zu der dieser Override gehört.
    * `evolution_path` (text): Der Elementarpfad der Signaturkarten-Evolution, der den Override auslöst (z.B. 'fire', 'ice', 'lightning').
    * `evolution_level` (integer): Die Stufe (1, 2 oder 3) der Signaturkarten-Evolution, die den Override auslöst.
    * `mechanic_config_override` (jsonb): Ein JSON-Objekt, das **nur die geänderten Teile** der Basis-`mechanics_config` der Klasse enthält. Die Struktur spiegelt die der Basis-Konfiguration wider, enthält aber nur die Keys und Werte, die überschrieben oder hinzugefügt werden sollen.
        * **Beispiel (ROG - Zeitsprung Eis Lvl 3 -> Momentum-Änderung):** Ändert Schwellenverschiebung, Verfallszeit und einen spezifischen Threshold-Effekt.
            ```json
            { "momentum": { "threshold_shift": -1, "decay_time": 5, "thresholds": [ { "value": 4, "effect": "time_gain_per_card", "time_gain": 1.0 } ] } }
            ```
        * **Beispiel (WAR - Zeitfestung Eis Lvl 2 -> Chrono-Energie-Änderung):** Ändert die Aktivierungsschwelle der Passivboni und den Effekt des Zeitgewinn-Bonus bei 2 Punkten.
            ```json
            { "chrono_energie": { "passive_thresholds_min_active": 1, "thresholds": [ { "value": 2, "effect": "block_time_gain", "time_gain": 1.0 } ] } }
            ```
        * **Beispiel (WAR - Zeitfestung Blitz Lvl 1 -> Chrono-Energie-Änderung):** Fügt einen Modifikator für die Energie-Generierung hinzu.
            ```json
            { "chrono_energie": { "generation_modifier": { "condition": "every_nth_block", "n": 2, "energy_gain": 1 } } }
            ```
    * `created_at`, `updated_at`: Standard-Zeitstempel (falls vorhanden).
* **Wichtiger Hinweis zum Merging:** Die Spiellogik **muss** das `mechanic_config_override` **intelligent** mit der Basis-`mechanics_config` aus der `classes`-Tabelle zusammenführen (rekursives Merging). Einfaches Ersetzen von Top-Level-Schlüsseln ist nicht ausreichend!
    * Skalarwerte (z.B. `"decay_time": 5`) überschreiben den Basiswert.
    * Objekte werden rekursiv gemerged.
    * **Arrays (z.B. `thresholds`) müssen besonders behandelt werden:** Die Logik sollte Einträge im Basis-Array anhand eines eindeutigen Schlüssels (z.B. `value` bei Thresholds) identifizieren und nur die Felder dieses spezifischen Eintrags mit den Werten aus dem Override aktualisieren. Das gesamte Array darf **nicht** einfach ersetzt werden, da sonst andere Thresholds verloren gehen! Der Pseudocode im Guide illustriert dieses Prinzip.

### Tabelle: `evolution_requirements`

* **Zweck:** Speichert die Materialkosten für jede einzelne Karten-Evolution. Die genauen Kosten pro Evolutionsstufe und Kartentyp (Normal vs. Signatur) sind in `ZK-MAT-v1.0-.md` definiert.
* **Spalten:**
    * `id` (uuid, PK): Eindeutige ID des Anforderungseintrags.
    * `card_evolution_id` (uuid, FK -> card_evolutions.id): Verweis auf die Evolution, die diese Materialien benötigt.
    * `material_id` (uuid, FK -> materials.id): Verweis auf das benötigte Material.
    * `amount_required` (integer): Die benötigte Anzahl des Materials.
* **Hinweis & Beispiel:** Für eine Evolution, die z.B. 2 Materialtypen kostet, gibt es 2 Zeilen in dieser Tabelle mit derselben `card_evolution_id`.
    * *Beispiel:* `Zeitwächter-Fokus -> Feuer 1` (Evo-ID sei `473f...`) benötigt `3x Funkenfragment` (Mat-ID `f932...`) und `1x Zeitfragment` (Mat-ID `bd90...`). Das ergibt zwei Zeilen:
        1. `(id: uuid1, card_evolution_id: '473f...', material_id: 'f932...', amount_required: 3)`
        2. `(id: uuid2, card_evolution_id: '473f...', material_id: 'bd90...', amount_required: 1)`

### Tabelle: `materials`

Enthält die Definitionen aller sammelbaren Materialien im Spiel.

* `id` (uuid): Primärschlüssel des Materials. *(Hinweis: Auch wenn Design-Dokumente wie `ZK-MAT-v1.0-.md` beschreibende IDs wie `MAT-ELEM-FIR-COM-001` verwenden, enthält diese Spalte in der Datenbank die tatsächliche UUID, wie in `materials.csv` zu sehen).*
* `name` (text): Angezeigter Name des Materials (z.B. 'Funkenfragment').
* `element` (text): Element des Materials ('fire', 'ice', 'lightning', 'neutral').
* `rarity` (text): Seltenheit ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic').
* `category` (text): Hauptkategorie ('time', 'elemental', 'quality', 'special').
* `description` (text): Kurze Beschreibung.
* `icon_url` (text): Optionaler Pfad zum Icon.
* `acquisition_info` (text): Hinweis zur Herkunft (optional).

*(Die vollständige Liste der Materialien, deren Klassifizierung und Eigenschaften sind in `ZK-MAT-v1.0-.md` definiert.)*

### Tabelle: `dot_categories`

Definiert die verschiedenen Stufen von Damage-over-Time (DoT)-Effekten.

* `id` (uuid): Primärschlüssel der DoT-Kategorie.
* `name` (text): Name der Kategorie (z.B. 'Schwach', 'Mittel', 'Stark', 'Stark+').
* `damage_per_tick` (numeric): Schaden pro Tick, den dieser DoT verursacht.
* `time_gain` (numeric): Zeitgewinn pro Tick (falls zutreffend, siehe `ZK-MAT-v1.0-.md`).
* `duration` (numeric): Standarddauer des DoTs in Sekunden (kann von Karten überschrieben werden).
* `color_hex` (text): Farbcode für die visuelle Darstellung im UI (z.B. '#FFC107').

*(Das DoT-Kategorie-System und dessen Interaktionen sind detailliert in `ZK-MAT-v1.0-.md`, Abschnitt 5, beschrieben.)*

---

*(Neuer Abschnitt)*
### Wichtige Implementierungsentscheidungen (Zusammenfassung)

Während des Abgleichs der Datenbankstruktur mit den Klassendokumenten (insbesondere WAR v1.8.2) wurden folgende Punkte geklärt oder festgelegt:

* **`card_type`-Werte:** Die gültigen Werte für die `card_type`-Spalte in der `cards`-Tabelle werden durch das `cards_card_type_check`-Constraint bestimmt. Zum Zeitpunkt der Dokumentation waren dies: `'Basiszauber'`, `'Zeitmanipulation'`, `'Signatur'`, `'Verteidigung'`.
* **`chain_effectiveness`-Spalte:** Eine separate `chain_effectiveness`-Spalte in `card_evolutions` wird als obsolet betrachtet. Informationen zu Ketteneffekten (Ziele, Schadensübertragung) werden stattdessen strukturiert im `effect_data`-JSON gespeichert (z.B. unter dem Schlüssel `chain_lightning`). Es wird empfohlen, die redundante Spalte ggf. zu entfernen oder auf `NULL` zu setzen.
* **Globale Mechanik-Overrides:** Änderungen an Basis-Klassenmechaniken (z.B. Momentum durch ROG-Zeitsprung, Chrono-Energie durch WAR-Zeitfestung), die durch Signaturkarten-Evolutionen ausgelöst werden, gehören in die `class_evolution_mechanics`-Tabelle als JSON-Overrides. Sie sollten **nicht** im `effect_data` der `card_evolutions`-Tabelle dupliziert werden.
* **`effect_data` Struktur:** Die Struktur innerhalb des `effect_data`-JSONs (für `cards` und `card_evolutions`) hängt vom spezifischen Effekt ab und sollte konsistent von der Spiellogik interpretiert werden. Beispiele für WAR wurden im Dokument ergänzt.
* **Zeitstempel:** Die Tabellen `cards`, `card_evolutions`, `evolution_requirements`, `materials` und `dot_categories` schienen zum Zeitpunkt der Prüfung keine `created_at`/`updated_at`-Spalten zu haben, im Gegensatz zur `classes`-Tabelle.
* **Schild-Schwert-Zyklus (WAR):** Diese Mechanik wird als reine Spiellogik behandelt, die auf `mechanic_tags` (`{ATTACK}`, `{DEFENSE}`) prüft, und nicht über `classes.mechanics_config` konfiguriert.

---

## Programmier-Guidelines (Konzeptionell)

**Hinweis:** Die folgenden Pseudocode-Beispiele illustrieren die Kernlogik primär am Beispiel des Schattenschreiters (ROG) und dessen Momentum-System. Die Prinzipien gelten analog für andere Klassen, müssen aber deren spezifische Mechaniken (z.B. Chrono-Energie, Schild-Schwert-Zyklus für WAR) berücksichtigen und entsprechend erweitert werden.

### Laden der effektiven Klassen-Konfiguration

```csharp
// Funktion zum Laden der finalen Mechanik-Konfiguration für einen Spieler
JsonDocument GetEffectiveClassMechanics(Player player) {
    // 1. Lade Basis-Konfig der Klasse (enthält z.B. Basis-Momentum ODER Basis-Chrono-Energie)
    JsonDocument baseConfig = Database.Query("SELECT mechanics_config FROM classes WHERE id = @classId", new { classId = player.ClassId });

    // 2. Prüfe aktive Signaturkarten-Evolution (Pfad & Level, z.B. vom Zeitsprung (ROG) ODER Zeitfestung (WAR))
    string activePath = player.GetActiveSignatureEvolutionPath(); // Annahme: Liefert "fire", "ice", "lightning" oder null
    int activeLevel = player.GetActiveSignatureEvolutionLevel(); // Annahme: Liefert 1, 2, 3 oder 0

    if (activePath != null && activeLevel > 0) {
        // 3. Lade Override-Konfig für diesen Pfad/Level aus class_evolution_mechanics
        JsonDocument overrideConfig = Database.QueryFirstOrDefault(
            "SELECT mechanic_config_override FROM class_evolution_mechanics WHERE class_id = @classId AND evolution_path = @path AND evolution_level = @level",
            new { classId = player.ClassId, path = activePath, level = activeLevel }
        );

        if (overrideConfig != null) {
            // 4. Merge Override über Basis (Intelligent! Siehe Hinweis unten)
            baseConfig = MergeConfigsRecursively(baseConfig, overrideConfig);
        }
    }

    return baseConfig; // Gib die finale, effektive Konfiguration zurück (z.B. Momentum ODER Chrono-Energie mit Overrides)
}

// Rekursive Funktion zum Mergen (vereinfacht...)
JsonDocument MergeConfigsRecursively(JsonDocument baseJson, JsonDocument overrideJson) {
    // ... Implementation des intelligenten Mergens ...
    // Wichtig: Behandle Arrays wie "thresholds" (für ROG Momentum UND WAR Chrono-Energie) speziell,
    // um Einträge zu aktualisieren statt das ganze Array zu ersetzen!
    // Siehe wichtigen Hinweis bei der Beschreibung der Tabelle class_evolution_mechanics!
    throw new NotImplementedException("Implement proper JSON merging logic!");
}
Zugriff auf Zeitkosten & Klassenspezifische Kosten (Logik)

C#
// Beispielhafte Logik zur Kostenberechnung - STARK ROG-SPEZIFISCH!
(float timeCost, int momentumCost) CalculateCardCosts_ROG_Example(CardData card, Player player, GameState gameState, JsonDocument effectiveRogConfig) {
    float baseTimeCost = card.base_time_cost;
    float finalTimeCost = baseTimeCost;
    int finalMomentumCost = 0; // Nur für ROG relevant

    // --- ROG Momentum Logik ---
    int currentMomentum = player.GetMomentum(); // ROG-spezifisch
    var momentumConfig = effectiveRogConfig.RootElement.GetProperty("momentum");
    // ... (Restliche ROG Momentum-Checks für 0 Kosten / Momentum-Verbrauch) ...
    bool isShadowCard = card.mechanic_tags != null && card.mechanic_tags.Contains("shadow"); // ROG
    bool isAttackCard = card.mechanic_tags != null && card.mechanic_tags.Contains("angriff"); // ROG/WAR (aber Tag prüfen!)
    bool shadowSynergyActive = gameState.LastCardPlayedHadTag("shadow"); // ROG
    // ... (Prüfung 0-Kosten Bedingungen: Karteigen, Schattensynergie, Momentum 3+) ...

    // --- HIER MÜSSTE KLASSENSPEZIFISCHE LOGIK FÜR ANDERE KLASSEN HINZU ---
    // Beispiel WAR:
    // if (player.ClassCode == "WAR") {
    //    var warConfig = effectiveWarConfig.RootElement; // effektive config für WAR laden
    //    // Prüfe Zeitlicher Wächter Kostenreduktion (<15s Restzeit + Def-Karte?)
    //    if (gameState.RemainingTime < warConfig.GetProperty("zeitlicher_waechter").GetProperty("low_time_threshold").GetInt32() && card.mechanic_tags.Contains("DEFENSE")) {
    //       // Logik für 15% Kostenreduktion auf nächste Karte implementieren (braucht gameState Tracking)
    //    }
    //    // Chrono-Energie Boni (z.B. +1 Schaden ab 3 Energie) würden hier nicht die Kosten, aber den Effekt beeinflussen und müssten bei der Effekt-Anwendung geprüft werden.
    // }

    // Optional: Andere Kostenreduktionen (z.B. durch Buffs von Karten wie Zeitliche Effizienz Lvl3) hier anwenden
    // finalTimeCost = ApplyGeneralBuffs(finalTimeCost, player, card);

    return (finalTimeCost, finalMomentumCost); // MomentumCost ist für WAR 0
}

// UI-Anzeige für Zeitkosten (Logik bleibt ähnlich, prüft Ergebnis von CalculateCardCosts)
void UpdateCostDisplay(CardUI ui, CardData card, Player player, GameState gameState, JsonDocument effectiveClassConfig) {
    // Rufe die passende CalculateCardCosts-Funktion für die Spielerklasse auf!
    (float timeCost, int classSpecificCost) = CalculateCardCosts_For_PlayerClass(card, player, gameState, effectiveClassConfig);

    Color costColor = Color.white; // Standardfarbe
    string additionalCostText = "";

    if (timeCost == 0) {
        // Unterscheide visuell, warum die Karte 0 kostet
        if (player.ClassCode == "ROG" && classSpecificCost > 0) { // classSpecificCost ist hier momentumCost
             costColor = Color.yellow; // Gelb: Kostet 0 Zeit, aber Momentum (ROG)
             additionalCostText = $"-{classSpecificCost} Mom";
        } else if (player.ClassCode == "ROG" /* && war Schattensynergie aktiv? */) { // Bessere Logik zur Unterscheidung nötig
             costColor = Color.cyan; // Cyan für Synergie-0-Kosten (ROG)?
        } else {
             costColor = Color.green; // Grün für andere 0-Zeit-Kosten (z.B. Karteneffekt)
        }
    } else if (timeCost < card.base_time_cost) {
        // Optional: Farbe für reduzierte Kosten (nicht 0) - z.B. durch Zeitlicher Wächter (WAR)
        // costColor = Color.blue;
    }

    ui.costText.color = costColor;
    ui.costText.text = card.base_time_cost.ToString("0.0") + "s";
    // Zeige zusätzliche Kosten nur an, wenn sie > 0 sind (z.B. Momentum bei ROG)
    ui.additionalCostText.gameObject.SetActive(classSpecificCost > 0);
    ui.additionalCostText.text = additionalCostText;
}