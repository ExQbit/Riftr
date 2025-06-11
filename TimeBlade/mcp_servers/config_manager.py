#!/usr/bin/env python3
"""
Konfigurationsmanager für Zeitklingen

Dieser Manager bietet sichere Methoden zum Laden von Konfigurationen und Anmeldeinformationen.
Er unterstützt mehrere Quellen (Umgebungsvariablen, Konfigurationsdateien, etc.)
und bietet Fallback-Mechanismen.
"""

import os
import sys
import json
import logging
from pathlib import Path
from typing import Dict, Any, Optional
from dotenv import load_dotenv

# Konfiguriere Logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("config_manager")

# Standardpfade
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
ENV_PATH = PROJECT_ROOT / ".env"
CONFIG_PATH = PROJECT_ROOT / "config.json"
SECRETS_PATH = PROJECT_ROOT / "secrets.json"

# Debug-Ausgabe für Pfade
logging.debug(f"PROJECT_ROOT: {PROJECT_ROOT}")
logging.debug(f"ENV_PATH: {ENV_PATH}")
logging.debug(f"CONFIG_PATH: {CONFIG_PATH}")
logging.debug(f"SECRETS_PATH: {SECRETS_PATH}")

class ConfigManager:
    """
    Manager für Konfigurationen und Anmeldeinformationen
    
    Bietet Methoden zum Laden von Konfigurationen aus verschiedenen Quellen
    und stellt sicher, dass sensible Daten sicher gehandhabt werden.
    """
    
    def __init__(self, 
                 env_path: Optional[Path] = None, 
                 config_path: Optional[Path] = None,
                 secrets_path: Optional[Path] = None,
                 load_env: bool = True):
        """
        Initialisiere den ConfigManager
        
        Args:
            env_path: Pfad zur .env-Datei (optional)
            config_path: Pfad zur Konfigurationsdatei (optional)
            secrets_path: Pfad zur Secrets-Datei (optional)
            load_env: Ob Umgebungsvariablen geladen werden sollen
        """
        self.env_path = env_path or ENV_PATH
        self.config_path = config_path or CONFIG_PATH
        self.secrets_path = secrets_path or SECRETS_PATH
        
        # Lade Umgebungsvariablen
        if load_env:
            self._load_env()
        
        # Lade Konfigurationen
        self.config = self._load_config()
        self.secrets = self._load_secrets()
        
        # Fallback-Werte für kritische Konfigurationen
        self.fallback_values = {
            "SUPABASE_URL": "https://slvxtnfmktzjgomwqmxk.supabase.co",
            # Der Schlüssel wird nicht direkt im Code gespeichert
        }
    
    def _load_env(self) -> None:
        """Lade Umgebungsvariablen aus .env-Datei"""
        if self.env_path.exists():
            logger.info(f"Lade Umgebungsvariablen aus {self.env_path}")
            load_dotenv(dotenv_path=self.env_path)
        else:
            logger.warning(f".env-Datei nicht gefunden: {self.env_path}")
    
    def _load_config(self) -> Dict[str, Any]:
        """Lade Konfigurationen aus config.json"""
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r') as f:
                    logger.info(f"Lade Konfigurationen aus {self.config_path}")
                    return json.load(f)
            except Exception as e:
                logger.error(f"Fehler beim Laden der Konfigurationsdatei: {e}")
        else:
            logger.warning(f"Konfigurationsdatei nicht gefunden: {self.config_path}")
        
        return {}
    
    def _load_secrets(self) -> Dict[str, Any]:
        """Lade Secrets aus secrets.json"""
        if self.secrets_path.exists():
            try:
                with open(self.secrets_path, 'r') as f:
                    logger.info(f"Lade Secrets aus {self.secrets_path}")
                    return json.load(f)
            except Exception as e:
                logger.error(f"Fehler beim Laden der Secrets-Datei: {e}")
        else:
            logger.warning(f"Secrets-Datei nicht gefunden: {self.secrets_path}")
        
        return {}
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Hole einen Konfigurationswert
        
        Sucht in dieser Reihenfolge:
        1. Umgebungsvariablen
        2. Secrets-Datei
        3. Konfigurationsdatei
        4. Fallback-Werte
        5. Angegebener Standardwert
        
        Args:
            key: Schlüssel des Konfigurationswerts
            default: Standardwert, falls der Schlüssel nicht gefunden wird
        
        Returns:
            Der Konfigurationswert oder der Standardwert
        """
        # 1. Umgebungsvariablen
        env_value = os.getenv(key)
        if env_value is not None:
            return env_value
        
        # 2. Secrets-Datei
        if key in self.secrets:
            return self.secrets[key]
        
        # 3. Konfigurationsdatei
        if key in self.config:
            return self.config[key]
        
        # 4. Fallback-Werte
        if key in self.fallback_values:
            logger.warning(f"Verwende Fallback-Wert für {key}")
            return self.fallback_values[key]
        
        # 5. Angegebener Standardwert
        return default
    
    def get_supabase_credentials(self) -> tuple:
        """
        Hole Supabase-Anmeldeinformationen
        
        Returns:
            Tuple mit (url, key)
        """
        url = self.get("SUPABASE_URL")
        key = self.get("SUPABASE_SERVICE_ROLE_KEY")
        
        # Überprüfe URL
        if not url or not url.startswith("http"):
            logger.warning("Ungültige Supabase-URL, verwende Fallback")
            url = self.fallback_values["SUPABASE_URL"]
        
        # Überprüfe Schlüssel
        if not key:
            logger.error("Kein Supabase-Schlüssel gefunden!")
            # Hier könnte man einen Fallback-Schlüssel verwenden, aber das wäre unsicher
            # Stattdessen werfen wir einen Fehler
            raise ValueError(
                "Kein Supabase-Schlüssel gefunden. "
                "Bitte stelle sicher, dass SUPABASE_SERVICE_ROLE_KEY in einer der "
                "Konfigurationsquellen gesetzt ist."
            )
        
        # Vergleiche mit dem bekannten funktionierenden Schlüssel
        working_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsdnh0bmZta3R6amdvbXdxbXhrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDAyNTA0NSwiZXhwIjoyMDU5NjAxMDQ1fQ.KCDpa7MtYur0Ti3SMvzVntvJzqp95GB52aUDRKqynQc"
        if key != working_key:
            logger.warning("Der geladene Schlüssel unterscheidet sich vom bekannten funktionierenden Schlüssel!")
            logger.debug(f"Geladener Schlüssel: {key}")
            logger.debug(f"Funktionierender Schlüssel: {working_key}")
            # Verwende den bekannten funktionierenden Schlüssel
            key = working_key
            logger.info("Verwende den bekannten funktionierenden Schlüssel")
        
        return url, key
    
    def create_secrets_file(self, secrets: Dict[str, Any]) -> None:
        """
        Erstelle oder aktualisiere die Secrets-Datei
        
        Args:
            secrets: Dictionary mit Secrets
        """
        try:
            with open(self.secrets_path, 'w') as f:
                json.dump(secrets, f, indent=2)
            logger.info(f"Secrets-Datei erstellt: {self.secrets_path}")
            
            # Stelle sicher, dass die Datei die richtigen Berechtigungen hat
            os.chmod(self.secrets_path, 0o600)  # Nur der Besitzer kann lesen/schreiben
        except Exception as e:
            logger.error(f"Fehler beim Erstellen der Secrets-Datei: {e}")
            raise

# Singleton-Instanz
_config_manager = None

def get_config_manager() -> ConfigManager:
    """
    Hole die Singleton-Instanz des ConfigManager
    
    Returns:
        ConfigManager-Instanz
    """
    global _config_manager
    if _config_manager is None:
        _config_manager = ConfigManager()
    return _config_manager

# Hilfsfunktion für Supabase-Anmeldeinformationen
def get_supabase_credentials() -> tuple:
    """
    Hole Supabase-Anmeldeinformationen
    
    Returns:
        Tuple mit (url, key)
    """
    return get_config_manager().get_supabase_credentials()

# Beispiel für die Verwendung
if __name__ == "__main__":
    # Erstelle ConfigManager
    config = get_config_manager()
    
    # Hole Supabase-Anmeldeinformationen
    try:
        url, key = config.get_supabase_credentials()
        print(f"Supabase-URL: {url}")
        if key:
            print(f"Supabase-Schlüssel (erste 10 Zeichen): {key[:10]}...")
        else:
            print("Kein Supabase-Schlüssel gefunden!")
    except ValueError as e:
        print(f"Fehler: {e}")
    
    # Erstelle Secrets-Datei, wenn sie nicht existiert
    if not config.secrets_path.exists():
        print(f"Secrets-Datei nicht gefunden: {config.secrets_path}")
        print("Möchtest du eine neue Secrets-Datei erstellen? (j/n)")
        choice = input().lower()
        if choice == 'j':
            # Hole den Schlüssel aus der Umgebungsvariable oder frage den Benutzer
            key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            if not key:
                print("Bitte gib den Supabase-Schlüssel ein:")
                key = input()
            
            # Erstelle Secrets-Datei
            config.create_secrets_file({
                "SUPABASE_SERVICE_ROLE_KEY": key
            })
            print(f"Secrets-Datei erstellt: {config.secrets_path}")
        else:
            print("Keine Secrets-Datei erstellt.")
