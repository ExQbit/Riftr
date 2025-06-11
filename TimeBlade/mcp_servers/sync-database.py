#!/usr/bin/env python3
"""
Zeitklingen Supabase-Datenbank Synchronisierungsskript

Dieses Skript synchronisiert lokale Kartendefinitionen mit der Supabase-Datenbank.
Es unterstützt verschiedene Umgebungen (dev, staging, prod) und kann im Dry-Run-Modus
ausgeführt werden, um Änderungen anzuzeigen, ohne sie anzuwenden.

Verwendung:
    python3 sync-database.py [--env ENV] [--dry-run] [--verbose]

Optionen:
    --env ENV       Umgebung (dev, staging, prod), Standard: dev
    --dry-run       Zeigt Änderungen an, ohne sie anzuwenden
    --verbose       Ausführliche Ausgabe
"""

import os
import sys
import json
import argparse
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from dotenv import load_dotenv

try:
    from supabase import create_client, Client
except ImportError:
    print("Supabase-Bibliothek nicht gefunden. Bitte installieren Sie sie mit 'pip install supabase'.")
    sys.exit(1)

# Konfiguration
ICLOUD_PATH = Path("/Users/exqbitmac/Library/Mobile Documents/com~apple~CloudDocs/Zeitklingen")
ENV_PATH = ICLOUD_PATH / ".env"
CARDS_DIR = ICLOUD_PATH / "Assets/ScriptableObjects/Cards"
CONFIG_DIR = ICLOUD_PATH / "Assets/ScriptableObjects/Config"

# Logger einrichten
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("sync-database")

# Umgebungsvariablen laden
load_dotenv(dotenv_path=ENV_PATH)

class SupabaseSync:
    """Klasse zur Synchronisierung von Daten mit Supabase"""
    
    def __init__(self, environment: str = "dev", dry_run: bool = False, verbose: bool = False):
        """Initialisiert die Supabase-Verbindung"""
        self.environment = environment
        self.dry_run = dry_run
        
        if verbose:
            logger.setLevel(logging.DEBUG)
        
        # Umgebungsspezifische Variablen
        env_suffix = "" if environment == "prod" else f"_{environment.upper()}"
        self.supabase_url = os.getenv(f"SUPABASE_URL{env_suffix}")
        self.supabase_key = os.getenv(f"SUPABASE_KEY{env_suffix}")
        
        if not self.supabase_url or not self.supabase_key:
            logger.error(f"Supabase-Konfiguration für Umgebung '{environment}' nicht gefunden.")
            sys.exit(1)
        
        logger.info(f"Verwende Supabase-Umgebung: {environment}")
        
        if not dry_run:
            try:
                self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
                logger.info("Verbindung zu Supabase hergestellt.")
            except Exception as e:
                logger.error(f"Fehler beim Verbinden mit Supabase: {e}")
                sys.exit(1)
        else:
            logger.info("DRY-RUN-MODUS: Keine Änderungen werden angewendet.")
            self.supabase = None
    
    def sync_cards(self) -> None:
        """Synchronisiert Kartendefinitionen mit der Supabase-Datenbank"""
        logger.info("Synchronisiere Kartendefinitionen...")
        
        # Lokale Karten laden
        local_cards = self._load_local_cards()
        logger.info(f"{len(local_cards)} lokale Karten gefunden.")
        
        if self.dry_run:
            logger.info("DRY-RUN: Würde folgende Karten synchronisieren:")
            for card in local_cards:
                logger.info(f"  - {card['name']} (Typ: {card['type']})")
            return
        
        # Bestehende Karten aus der Datenbank abrufen
        try:
            response = self.supabase.table("cards").select("*").execute()
            db_cards = {card["name"]: card for card in response.data}
            logger.info(f"{len(db_cards)} Karten in der Datenbank gefunden.")
        except Exception as e:
            logger.error(f"Fehler beim Abrufen der Karten aus der Datenbank: {e}")
            return
        
        # Karten synchronisieren
        cards_updated = 0
        cards_created = 0
        
        for card in local_cards:
            card_name = card["name"]
            
            if card_name in db_cards:
                # Karte aktualisieren
                db_card = db_cards[card_name]
                card_id = db_card["id"]
                
                # Aktualisierungszeitstempel hinzufügen
                card["updated_at"] = datetime.now().isoformat()
                
                # Nur aktualisieren, wenn sich etwas geändert hat
                if self._card_needs_update(card, db_card):
                    try:
                        self.supabase.table("cards").update(card).eq("id", card_id).execute()
                        logger.debug(f"Karte aktualisiert: {card_name}")
                        cards_updated += 1
                    except Exception as e:
                        logger.error(f"Fehler beim Aktualisieren der Karte {card_name}: {e}")
                else:
                    logger.debug(f"Keine Änderungen für Karte: {card_name}")
            else:
                # Neue Karte erstellen
                try:
                    # Erstellungs- und Aktualisierungszeitstempel hinzufügen
                    card["created_at"] = datetime.now().isoformat()
                    card["updated_at"] = datetime.now().isoformat()
                    
                    self.supabase.table("cards").insert(card).execute()
                    logger.debug(f"Neue Karte erstellt: {card_name}")
                    cards_created += 1
                except Exception as e:
                    logger.error(f"Fehler beim Erstellen der Karte {card_name}: {e}")
        
        logger.info(f"Synchronisierung abgeschlossen: {cards_created} Karten erstellt, {cards_updated} Karten aktualisiert.")
    
    def sync_game_config(self) -> None:
        """Synchronisiert Spielkonfigurationen mit der Supabase-Datenbank"""
        logger.info("Synchronisiere Spielkonfigurationen...")
        
        # Lokale Konfigurationen laden
        local_configs = self._load_local_configs()
        logger.info(f"{len(local_configs)} lokale Konfigurationen gefunden.")
        
        if self.dry_run:
            logger.info("DRY-RUN: Würde folgende Konfigurationen synchronisieren:")
            for key, config in local_configs.items():
                logger.info(f"  - {key}")
            return
        
        # Bestehende Konfigurationen aus der Datenbank abrufen
        try:
            response = self.supabase.table("game_config").select("*").execute()
            db_configs = {config["key"]: config for config in response.data}
            logger.info(f"{len(db_configs)} Konfigurationen in der Datenbank gefunden.")
        except Exception as e:
            logger.error(f"Fehler beim Abrufen der Konfigurationen aus der Datenbank: {e}")
            return
        
        # Konfigurationen synchronisieren
        configs_updated = 0
        configs_created = 0
        
        for key, config in local_configs.items():
            if key in db_configs:
                # Konfiguration aktualisieren
                db_config = db_configs[key]
                
                # Aktualisierungszeitstempel hinzufügen
                config["updated_at"] = datetime.now().isoformat()
                
                # Nur aktualisieren, wenn sich etwas geändert hat
                if json.dumps(config["value"]) != json.dumps(db_config["value"]):
                    try:
                        self.supabase.table("game_config").update(config).eq("key", key).execute()
                        logger.debug(f"Konfiguration aktualisiert: {key}")
                        configs_updated += 1
                    except Exception as e:
                        logger.error(f"Fehler beim Aktualisieren der Konfiguration {key}: {e}")
                else:
                    logger.debug(f"Keine Änderungen für Konfiguration: {key}")
            else:
                # Neue Konfiguration erstellen
                try:
                    # Aktualisierungszeitstempel hinzufügen
                    config["updated_at"] = datetime.now().isoformat()
                    
                    self.supabase.table("game_config").insert(config).execute()
                    logger.debug(f"Neue Konfiguration erstellt: {key}")
                    configs_created += 1
                except Exception as e:
                    logger.error(f"Fehler beim Erstellen der Konfiguration {key}: {e}")
        
        logger.info(f"Synchronisierung abgeschlossen: {configs_created} Konfigurationen erstellt, {configs_updated} Konfigurationen aktualisiert.")
    
    def _load_local_cards(self) -> List[Dict[str, Any]]:
        """Lädt lokale Kartendefinitionen aus JSON-Dateien"""
        cards = []
        
        if not CARDS_DIR.exists():
            logger.warning(f"Kartenverzeichnis nicht gefunden: {CARDS_DIR}")
            return cards
        
        for card_file in CARDS_DIR.glob("*.json"):
            try:
                with open(card_file, "r", encoding="utf-8") as f:
                    card_data = json.load(f)
                    cards.append(card_data)
            except Exception as e:
                logger.error(f"Fehler beim Laden der Karte {card_file.name}: {e}")
        
        return cards
    
    def _load_local_configs(self) -> Dict[str, Dict[str, Any]]:
        """Lädt lokale Spielkonfigurationen aus JSON-Dateien"""
        configs = {}
        
        if not CONFIG_DIR.exists():
            logger.warning(f"Konfigurationsverzeichnis nicht gefunden: {CONFIG_DIR}")
            return configs
        
        for config_file in CONFIG_DIR.glob("*.json"):
            try:
                key = config_file.stem
                with open(config_file, "r", encoding="utf-8") as f:
                    value = json.load(f)
                    configs[key] = {
                        "key": key,
                        "value": value,
                        "description": f"Konfiguration aus {config_file.name}"
                    }
            except Exception as e:
                logger.error(f"Fehler beim Laden der Konfiguration {config_file.name}: {e}")
        
        return configs
    
    def _card_needs_update(self, local_card: Dict[str, Any], db_card: Dict[str, Any]) -> bool:
        """Prüft, ob eine Karte aktualisiert werden muss"""
        # Felder, die für den Vergleich relevant sind
        fields = ["name", "type", "element", "evolution_level", "power", "health", "effect", "flavor_text", "base_cost"]
        
        for field in fields:
            if field in local_card and field in db_card:
                if local_card[field] != db_card[field]:
                    return True
            elif field in local_card and field not in db_card:
                return True
            elif field not in local_card and field in db_card:
                return True
        
        return False

def main():
    """Hauptfunktion"""
    parser = argparse.ArgumentParser(description="Zeitklingen Supabase-Datenbank Synchronisierungsskript")
    parser.add_argument("--env", choices=["dev", "staging", "prod"], default="dev", help="Umgebung (dev, staging, prod)")
    parser.add_argument("--dry-run", action="store_true", help="Zeigt Änderungen an, ohne sie anzuwenden")
    parser.add_argument("--verbose", action="store_true", help="Ausführliche Ausgabe")
    args = parser.parse_args()
    
    sync = SupabaseSync(environment=args.env, dry_run=args.dry_run, verbose=args.verbose)
    
    # Karten synchronisieren
    sync.sync_cards()
    
    # Spielkonfigurationen synchronisieren
    sync.sync_game_config()
    
    logger.info("Synchronisierung abgeschlossen.")

if __name__ == "__main__":
    main()
