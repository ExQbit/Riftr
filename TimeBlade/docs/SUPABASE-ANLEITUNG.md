# Supabase-Anleitung für Zeitklingen

## Verbindungsdaten

Die korrekten Verbindungsdaten für den Supabase-Server sind:

- **URL**: `https://slvxtnfmktzjgomwqmxk.supabase.co`
- **API-Key**: Der Service-Role-Key wird aus der `.env`-Datei geladen

## Skripte für den Datenzugriff

### Karten herunterladen

Das Skript `download_cards_from_supabase.py` lädt alle Karten aus der Supabase-Datenbank und speichert sie in JSON-Dateien:

```python
# Verbindung zu Supabase herstellen
url = "https://slvxtnfmktzjgomwqmxk.supabase.co"
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

# Karten laden
response = supabase.table("cards").select("*").execute()
cards = response.data
```

### Karten hochladen

Zum Hochladen von Karten kann das Skript `update_supabase_cards.py` verwendet werden.

## Wichtige Hinweise

1. **Umgebungsvariablen**: Die Verbindungsdaten werden aus der `.env`-Datei geladen.
2. **Kartenformat**: Elemente sind auf Englisch (Water, Fire, Lightning, Neutral), während andere Felder auf Deutsch sind.
3. **Kartentypen**: Die Karten sind in drei Typen unterteilt: Chronomant, Schattenschreiter und Zeitwächter.

## Fehlerbehebung

Bei Verbindungsproblemen:
1. Überprüfe, ob die `.env`-Datei vorhanden ist und die richtigen Werte enthält
2. Stelle sicher, dass die Supabase-Bibliothek installiert ist: `pip install supabase`
3. Überprüfe die Internetverbindung

## Beispiel für Kartenstruktur

```json
{
  "id": "585f534f-f7fd-4f32-9023-03e30ad3f085",
  "name": "Zeitstillklinge",
  "type": "Schattenschreiter",
  "element": "Water",
  "evolution_level": 3,
  "power": 4,
  "health": null,
  "effect": "2,5s, 4 Schaden + 2 DoT, 40% Slow, Zeitgewinn 1,0s",
  "flavor_text": "Eis-Evolution der Giftklinge, Stufe 3",
  "base_cost": null,
  "created_at": "2025-04-09T12:57:30.083957+00:00",
  "updated_at": "2025-04-09T12:57:30.083957+00:00"
}
```
