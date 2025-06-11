#!/usr/bin/env python3
"""
Supabase-Client für Zeitklingen

Bietet Funktionen für die Interaktion mit der Supabase-Datenbank.
Verwendet den ConfigManager für sichere Handhabung der Anmeldeinformationen.
"""

import os
import sys
import logging
from typing import Dict, Any, List, Optional
from supabase import create_client, Client

# Importiere den ConfigManager
from config_manager import get_config_manager, get_supabase_credentials

# Konfiguriere Logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("supabase_client")

def get_supabase_client() -> Client:
    """
    Erstelle und gib einen Supabase-Client zurück
    
    Verwendet den ConfigManager, um die Anmeldeinformationen sicher zu laden.
    Unterstützt mehrere Quellen für die Anmeldeinformationen und bietet Fallback-Mechanismen.
    
    Returns:
        Supabase-Client
    
    Raises:
        ValueError: Wenn die Anmeldeinformationen nicht gefunden werden
    """
    try:
        # Hole Anmeldeinformationen vom ConfigManager
        url, key = get_supabase_credentials()
        
        logger.info(f"Erstelle Supabase-Client mit URL: {url}")
        logger.debug(f"Schlüssellänge: {len(key) if key else 0}")
        
        # Erstelle Client
        client = create_client(url, key)
        logger.info("Supabase-Client erfolgreich erstellt")
        
        return client
    
    except Exception as e:
        logger.error(f"Fehler beim Erstellen des Supabase-Clients: {e}")
        raise

def test_connection() -> bool:
    """
    Teste die Verbindung zur Supabase-Datenbank
    
    Returns:
        True, wenn die Verbindung erfolgreich ist, sonst False
    """
    try:
        # Erstelle Client
        client = get_supabase_client()
        
        # Führe eine einfache Abfrage durch
        response = client.table('cards').select("count").execute()
        logger.info(f"Verbindungstest erfolgreich: {response}")
        
        return True
    
    except Exception as e:
        logger.error(f"Verbindungstest fehlgeschlagen: {e}")
        return False

def get_cards(limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
    """
    Hole Karten aus der Datenbank
    
    Args:
        limit: Maximale Anzahl der zurückgegebenen Karten
        offset: Offset für die Abfrage
    
    Returns:
        Liste von Karten
    """
    try:
        client = get_supabase_client()
        response = client.table('cards').select("*").limit(limit).offset(offset).execute()
        return response.data
    except Exception as e:
        logger.error(f"Fehler beim Abrufen der Karten: {e}")
        return []

def create_card(card_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Erstelle eine neue Karte in der Datenbank
    
    Args:
        card_data: Daten der Karte
    
    Returns:
        Die erstellte Karte oder None bei einem Fehler
    """
    try:
        client = get_supabase_client()
        response = client.table('cards').insert(card_data).execute()
        return response.data[0] if response.data else None
    except Exception as e:
        logger.error(f"Fehler beim Erstellen der Karte: {e}")
        return None

# Beispiel für die Verwendung
if __name__ == "__main__":
    # Teste die Verbindung
    if test_connection():
        print("Verbindung zur Supabase-Datenbank erfolgreich getestet!")
        
        # Hole Karten
        cards = get_cards(limit=5)
        print(f"Anzahl der abgerufenen Karten: {len(cards)}")
        for card in cards:
            print(f"Karte: {card.get('name', 'Unbekannt')}")
    else:
        print("Verbindungstest fehlgeschlagen!")
        sys.exit(1)
