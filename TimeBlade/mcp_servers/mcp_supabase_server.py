#!/usr/bin/env python3
from datetime import datetime # Added for simple logging

# Simplest possible logging to check if Windsurf executes this script
LOG_ATTEMPT_FILE = "/Users/exqbitmac/TimeBlade/mcp_windsurf_launch_attempt.log"
try:
    with open(LOG_ATTEMPT_FILE, 'a') as f_attempt:
        f_attempt.write(f"Script executed by Windsurf (or manually) at: {datetime.now()}\n")
except Exception as e_log:
    pass # If this fails, we can't do much here, but script continues

"""
MCP Server für Zeitklingen Supabase Integration
Ermöglicht Claude den Zugriff auf die Supabase-Datenbank für das Zeitklingen-Kartenspiel.
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from dotenv import load_dotenv

# Get the directory of the current script
SCRIPT_DIR = Path(__file__).resolve().parent
# Project root is one level up from the script directory
PROJECT_ROOT = SCRIPT_DIR.parent
ENV_PATH = PROJECT_ROOT / ".env"

# Load environment variables from .env file in project root
load_dotenv(dotenv_path=ENV_PATH)
print(f"Attempting to load environment variables from {ENV_PATH}", file=sys.stderr)

# Manually set environment variables if they're not properly loaded
if not os.getenv("SUPABASE_URL") or not os.getenv("SUPABASE_SERVICE_ROLE_KEY"):
    # Read the .env file manually
    try:
        with open(ENV_PATH, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    # Ensure value is stripped of potential quotes
                    value = value.strip('"').strip('\'')
                    os.environ[key] = value
                    print(f"Manually set {key}", file=sys.stderr)
        # Re-check after manual loading
        if not os.getenv("SUPABASE_URL") or not os.getenv("SUPABASE_SERVICE_ROLE_KEY"):
            print("Warning: Supabase credentials still not found after manual load.", file=sys.stderr)
    except Exception as e:
        print(f"Error manually loading .env file from {ENV_PATH}: {e}", file=sys.stderr)

# No need to manually add venv path, assuming the script is run with the correct interpreter

# Import FastMCP
try:
    from mcp.server.fastmcp import FastMCP
    print("Successfully imported FastMCP", file=sys.stderr)
except ImportError as e:
    print(f"Error importing FastMCP: {e}", file=sys.stderr)
    sys.exit(1)

# Import Supabase client
try:
    from supabase import create_client, Client
    from pydantic import BaseModel
    print("Successfully imported Supabase client", file=sys.stderr)
except ImportError as e:
    print(f"Error importing Supabase client: {e}", file=sys.stderr)
    sys.exit(1)

def get_supabase_client() -> Client:
    """Create and return a Supabase client using environment variables"""
    # Get credentials from environment variables
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    # Check if the URL looks valid (basic check)
    if not supabase_url or not supabase_url.startswith("http"):
        print(f"Invalid URL format: {supabase_url}", file=sys.stderr)
        raise ValueError("Invalid Supabase URL format. Check your .env file.")
    
    print(f"Supabase URL: {supabase_url}", file=sys.stderr)
    print(f"Supabase key length: {len(supabase_key) if supabase_key else 0}", file=sys.stderr)
    
    if not supabase_url or not supabase_key:
        raise ValueError("Missing Supabase credentials. Check your .env file.")
    
    try:
        client = create_client(supabase_url, supabase_key)
        print("Successfully created Supabase client", file=sys.stderr)
        return client
    except Exception as e:
        print(f"Error creating Supabase client: {e}", file=sys.stderr)
        raise

# Initialize the MCP server
print("Initializing FastMCP server", file=sys.stderr)
mcp = FastMCP("Zeitklingen Supabase")

# Initialize Supabase client
print("Initializing Supabase client", file=sys.stderr)
try:
    supabase = get_supabase_client()
    print("Supabase client initialized successfully", file=sys.stderr)
    
    # Überprüfe, ob die Tabellen existieren und erstelle sie, wenn nicht
    def ensure_tables_exist():
        try:
            # Überprüfe, ob die cards-Tabelle existiert
            try:
                supabase.table("cards").select("count").limit(1).execute()
                print("Cards table exists", file=sys.stderr)
            except Exception as e:
                if "relation \"public.cards\" does not exist" in str(e):
                    print("Creating cards table...", file=sys.stderr)
                    # SQL zur Erstellung der Tabelle
                    sql = """
                    CREATE TABLE IF NOT EXISTS public.cards (
                        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                        name TEXT NOT NULL,
                        type TEXT NOT NULL,
                        element TEXT,
                        evolution_level INTEGER DEFAULT 0,
                        power INTEGER,
                        health INTEGER,
                        effect TEXT,
                        flavor_text TEXT,
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                    );
                    """
                    # Führe SQL aus
                    try:
                        supabase.rpc('exec_sql', {"sql": sql}).execute()
                        print("Cards table created successfully", file=sys.stderr)
                    except Exception as sql_error:
                        print(f"Error creating cards table: {str(sql_error)}", file=sys.stderr)
                        print("The server will continue, but card operations may fail", file=sys.stderr)
                else:
                    print(f"Error checking cards table: {str(e)}", file=sys.stderr)
        except Exception as e:
            print(f"Error ensuring tables exist: {str(e)}", file=sys.stderr)
    
    # Versuche, die Tabellen zu erstellen
    try:
        ensure_tables_exist()
    except Exception as e:
        print(f"Warning: Could not create tables automatically: {str(e)}", file=sys.stderr)
        print("The server will continue, but some operations may fail", file=sys.stderr)
        
except Exception as e:
    print(f"Failed to initialize Supabase client: {e}", file=sys.stderr)
    sys.exit(1)

# Tool implementations
@mcp.tool()
def read_cards(class_type: Optional[str] = None, 
               element: Optional[str] = None, 
               evolution_level: Optional[int] = None) -> Dict:
    """
    Retrieve card information from the database with optional filtering.
    
    Args:
        class_type: Filter by card class (Chronomant, Zeitwächter, Schattenschreiter)
        element: Filter by elemental type (Fire, Water, Air, Earth, Metal)
        evolution_level: Filter by evolution level (0-3)
        
    Returns:
        A dictionary containing the list of cards matching the filters
    """
    print(f"read_cards called with class_type={class_type}, element={element}, evolution_level={evolution_level}", file=sys.stderr)
    
    try:
        # Versuche zuerst, alle verfügbaren Tabellen zu listen
        print("Checking available tables in Supabase...", file=sys.stderr)
        try:
            # Diese Methode ist nicht standardmäßig in der Supabase-API, aber wir versuchen es
            tables = supabase.table('information_schema.tables')\
                .select('table_name')\
                .eq('table_schema', 'public')\
                .execute()
            print(f"Available tables: {[t['table_name'] for t in tables.data]}", file=sys.stderr)
        except Exception as table_error:
            print(f"Could not list tables: {str(table_error)}", file=sys.stderr)
            print("Trying alternative approach to check if cards table exists...", file=sys.stderr)
        
        # Versuche nun, die Karten abzurufen
        table_name = "cards"  # Standardname
        alternative_names = ["card", "zeitklingen_cards", "zk_cards"]
        
        # Versuche zuerst den Standardnamen
        try:
            print(f"Trying to access table: {table_name}", file=sys.stderr)
            query = supabase.table(table_name).select("*")
            
            # Apply filters if provided
            if class_type:
                query = query.eq("type", class_type)
            if element:
                query = query.eq("element", element)
            if evolution_level is not None:
                query = query.eq("evolution_level", evolution_level)
                
            response = query.execute()
            print(f"read_cards found {len(response.data)} cards in table '{table_name}'", file=sys.stderr)
            return {"cards": response.data}
        except Exception as e:
            print(f"Error accessing table '{table_name}': {str(e)}", file=sys.stderr)
            
            # Versuche alternative Tabellennamen
            for alt_name in alternative_names:
                try:
                    print(f"Trying alternative table name: {alt_name}", file=sys.stderr)
                    query = supabase.table(alt_name).select("*")
                    response = query.execute()
                    print(f"Successfully found table '{alt_name}' with {len(response.data)} records", file=sys.stderr)
                    
                    # Apply filters if provided
                    if class_type:
                        query = query.eq("type", class_type)
                    if element:
                        query = query.eq("element", element)
                    if evolution_level is not None:
                        query = query.eq("evolution_level", evolution_level)
                    
                    filtered_response = query.execute()
                    print(f"read_cards found {len(filtered_response.data)} cards in table '{alt_name}'", file=sys.stderr)
                    return {"cards": filtered_response.data, "table_used": alt_name}
                except Exception as alt_error:
                    print(f"Error accessing alternative table '{alt_name}': {str(alt_error)}", file=sys.stderr)
            
            # Wenn keine Tabelle gefunden wurde, geben wir einen detaillierten Fehlerbericht zurück
            return {
                "error": f"Could not find a valid cards table in the database. Tried: {[table_name] + alternative_names}",
                "details": str(e),
                "suggestion": "The cards table may not exist yet. Please create it in Supabase with the appropriate schema."
            }
    except Exception as e:
        print(f"Unexpected error reading cards: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def read_player_progress(player_id: str) -> Dict:
    """
    Retrieve a player's current progress.
    
    Args:
        player_id: The ID of the player
        
    Returns:
        A dictionary containing the player's data, cards, and materials
    """
    print(f"read_player_progress called with player_id={player_id}", file=sys.stderr)
    try:
        # Get player data
        player_data = supabase.table("players").select("*").eq("id", player_id).execute()
        
        # Get player's cards
        player_cards = supabase.table("player_cards").select("*").eq("player_id", player_id).execute()
        
        # Get player's materials
        player_materials = supabase.table("player_materials").select("*").eq("player_id", player_id).execute()
        
        print(f"read_player_progress found player data: {bool(player_data.data)}", file=sys.stderr)
        return {
            "player": player_data.data[0] if player_data.data else None,
            "cards": player_cards.data,
            "materials": player_materials.data
        }
    except Exception as e:
        print(f"Error reading player progress: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def update_player_cards(player_id: str, card_id: str, quantity_change: int) -> Dict:
    """
    Update a player's card collection.
    
    Args:
        player_id: The ID of the player
        card_id: The ID of the card to update
        quantity_change: Positive to add cards, negative to remove
        
    Returns:
        A dictionary containing the result of the operation
    """
    print(f"update_player_cards called with player_id={player_id}, card_id={card_id}, quantity_change={quantity_change}", file=sys.stderr)
    try:
        # Check if player has the card
        existing_card = supabase.table("player_cards").select("*").eq("player_id", player_id).eq("card_id", card_id).execute()
        
        if existing_card.data:
            # Update existing card quantity
            current_quantity = existing_card.data[0].get("quantity", 0)
            new_quantity = max(0, current_quantity + quantity_change)
            
            if new_quantity == 0:
                # Remove card if quantity becomes zero
                supabase.table("player_cards").delete().eq("player_id", player_id).eq("card_id", card_id).execute()
                return {"message": f"Card {card_id} removed from player {player_id}'s collection"}
            else:
                # Update quantity
                supabase.table("player_cards").update({"quantity": new_quantity}).eq("player_id", player_id).eq("card_id", card_id).execute()
                return {"message": f"Card {card_id} quantity updated to {new_quantity}"}
        elif quantity_change > 0:
            # Add new card to player's collection
            supabase.table("player_cards").insert({"player_id": player_id, "card_id": card_id, "quantity": quantity_change}).execute()
            return {"message": f"Added {quantity_change} of card {card_id} to player {player_id}'s collection"}
        else:
            return {"error": "Cannot remove a card the player doesn't have"}
    except Exception as e:
        print(f"Error updating player cards: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def update_player_materials(player_id: str, material_type: str, quantity_change: int) -> Dict:
    """
    Update a player's material inventory.
    
    Args:
        player_id: The ID of the player
        material_type: The type of material to update
        quantity_change: Positive to add materials, negative to remove
        
    Returns:
        A dictionary containing the result of the operation
    """
    print(f"update_player_materials called with player_id={player_id}, material_type={material_type}, quantity_change={quantity_change}", file=sys.stderr)
    try:
        # Check if player has the material
        existing_material = supabase.table("player_materials").select("*").eq("player_id", player_id).eq("material_type", material_type).execute()
        
        if existing_material.data:
            # Update existing material quantity
            current_quantity = existing_material.data[0].get("quantity", 0)
            new_quantity = max(0, current_quantity + quantity_change)
            
            if new_quantity == 0:
                # Remove material if quantity becomes zero
                supabase.table("player_materials").delete().eq("player_id", player_id).eq("material_type", material_type).execute()
                return {"message": f"Material {material_type} removed from player {player_id}'s inventory"}
            else:
                # Update quantity
                supabase.table("player_materials").update({"quantity": new_quantity}).eq("player_id", player_id).eq("material_type", material_type).execute()
                return {"message": f"Material {material_type} quantity updated to {new_quantity}"}
        elif quantity_change > 0:
            # Add new material to player's inventory
            supabase.table("player_materials").insert({"player_id": player_id, "material_type": material_type, "quantity": quantity_change}).execute()
            return {"message": f"Added {quantity_change} of material {material_type} to player {player_id}'s inventory"}
        else:
            return {"error": "Cannot remove a material the player doesn't have"}
    except Exception as e:
        print(f"Error updating player materials: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def read_world_data(world_id: Optional[str] = None, difficulty: Optional[str] = None) -> Dict:
    """
    Retrieve data about worlds.
    
    Args:
        world_id: Filter by world ID
        difficulty: Filter by difficulty level
        
    Returns:
        A dictionary containing the list of worlds matching the filters
    """
    print(f"read_world_data called with world_id={world_id}, difficulty={difficulty}", file=sys.stderr)
    try:
        query = supabase.table("worlds").select("*")
        
        # Apply filters if provided
        if world_id:
            query = query.eq("id", world_id)
        if difficulty:
            query = query.eq("difficulty", difficulty)
            
        response = query.execute()
        print(f"read_world_data found {len(response.data)} worlds", file=sys.stderr)
        return {"worlds": response.data}
    except Exception as e:
        print(f"Error reading world data: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def create_card(name: str, 
               type: str,
               element: Optional[str] = None,
               evolution_level: Optional[int] = 0,
               power: Optional[int] = None,
               health: Optional[int] = None,
               effect: Optional[str] = None,
               flavor_text: Optional[str] = None) -> Dict:
    """
    Create a new card in the database.
    
    Args:
        name: The name of the card
        type: The type of card (Chronomant, Zeitwächter, Schattenschreiter)
        element: The elemental type (Fire, Water, Air, Earth, Metal)
        evolution_level: The evolution level (0-3)
        power: The power value of the card
        health: The health value of the card
        effect: The card's game effect description
        flavor_text: Flavor text for the card
        
    Returns:
        A dictionary containing the created card information
    """
    print(f"create_card called with name={name}, type={type}", file=sys.stderr)
    try:
        # Stelle sicher, dass die Tabelle existiert
        try:
            supabase.table("cards").select("count").limit(1).execute()
        except Exception as e:
            if "relation \"public.cards\" does not exist" in str(e):
                print("Cards table doesn't exist, creating it...", file=sys.stderr)
                # SQL zur Erstellung der Tabelle
                sql = """
                CREATE TABLE IF NOT EXISTS public.cards (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    element TEXT,
                    evolution_level INTEGER DEFAULT 0,
                    power INTEGER,
                    health INTEGER,
                    effect TEXT,
                    flavor_text TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                );
                """
                # Führe SQL aus
                try:
                    supabase.rpc('exec_sql', {"sql": sql}).execute()
                    print("Cards table created successfully", file=sys.stderr)
                except Exception as sql_error:
                    print(f"Error creating cards table: {str(sql_error)}", file=sys.stderr)
                    return {"error": f"Could not create cards table: {str(sql_error)}"}
            else:
                print(f"Error checking cards table: {str(e)}", file=sys.stderr)
                return {"error": f"Could not check if cards table exists: {str(e)}"}
        
        # Erstelle die Karte
        card_data = {
            "name": name,
            "type": type,
            "element": element,
            "evolution_level": evolution_level,
            "power": power,
            "health": health,
            "effect": effect,
            "flavor_text": flavor_text
        }
        
        # Entferne None-Werte
        card_data = {k: v for k, v in card_data.items() if v is not None}
        
        # Füge die Karte zur Datenbank hinzu
        response = supabase.table("cards").insert(card_data).execute()
        print(f"Card created successfully: {response.data}", file=sys.stderr)
        return {"card": response.data[0] if response.data else None}
    except Exception as e:
        print(f"Error creating card: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def delete_card(card_id: str) -> Dict:
    """
    Delete a card from the database.
    
    Args:
        card_id: The ID of the card to delete
        
    Returns:
        A dictionary containing the result of the operation
    """
    print(f"delete_card called with card_id={card_id}", file=sys.stderr)
    try:
        # Delete the card
        response = supabase.table("cards").delete().eq("id", card_id).execute()
        print(f"Card deleted successfully: {response.data}", file=sys.stderr)
        return {"message": f"Card {card_id} deleted successfully"}
    except Exception as e:
        print(f"Error deleting card: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

@mcp.tool()
def delete_cards(card_ids: List[str]) -> Dict:
    """
    Delete multiple cards from the database.
    
    Args:
        card_ids: A list of card IDs to delete
        
    Returns:
        A dictionary containing the result of the operation
    """
    print(f"delete_cards called with card_ids={card_ids}", file=sys.stderr)
    results = []
    errors = []
    
    for card_id in card_ids:
        try:
            response = supabase.table("cards").delete().eq("id", card_id).execute()
            results.append(card_id)
        except Exception as e:
            errors.append({"id": card_id, "error": str(e)})
    
    return {"deleted": results, "errors": errors}

@mcp.tool()
def log_game_session(player_id: str, session_duration: int, cards_played: int, 
                     victory: bool, opponent_type: str, world_id: Optional[str] = None) -> Dict:
    """
    Record gameplay metrics.
    
    Args:
        player_id: The ID of the player
        session_duration: Duration of the game session in seconds
        cards_played: Number of cards played during the session
        victory: Whether the player won the game
        opponent_type: Type of opponent (AI, human, etc.)
        world_id: The ID of the world where the game was played
        
    Returns:
        A dictionary containing the result of the operation
    """
    print(f"log_game_session called with player_id={player_id}, session_duration={session_duration}, cards_played={cards_played}, victory={victory}, opponent_type={opponent_type}, world_id={world_id}", file=sys.stderr)
    try:
        # Prepare session data
        session_data = {
            "player_id": player_id,
            "session_duration": session_duration,
            "cards_played": cards_played,
            "victory": victory,
            "opponent_type": opponent_type,
            "timestamp": datetime.now().isoformat()
        }
        
        if world_id:
            session_data["world_id"] = world_id
        
        # Insert session data
        supabase.table("game_sessions").insert(session_data).execute()
        
        return {"message": "Game session logged successfully"}
    except Exception as e:
        print(f"Error logging game session: {str(e)}", file=sys.stderr)
        return {"error": str(e)}

# Main entry point
if __name__ == "__main__":
    import argparse
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Zeitklingen Supabase MCP Server")
    parser.add_argument("--tcp", action="store_true", help="Run server in TCP mode on port 8000")
    parser.add_argument("--port", type=int, default=8000, help="Port to use in TCP mode (default: 8000)")
    args = parser.parse_args()
    
    print(f"Starting Zeitklingen MCP Server with Python {sys.version}", file=sys.stderr)
    print(f"Working directory: {os.getcwd()}", file=sys.stderr)
    print(f"Project root: {PROJECT_ROOT}", file=sys.stderr)
    
    # Print registered tools
    print("\nRegistered tools:", file=sys.stderr)
    # Wir können die Tools direkt auflisten, da wir wissen, welche wir registriert haben
    print("- read_cards: Retrieve card information from the database with optional filtering.", file=sys.stderr)
    print("- create_card: Create a new card in the database.", file=sys.stderr)
    print("- read_player_progress: Retrieve a player's current progress.", file=sys.stderr)
    print("- update_player_cards: Update a player's card collection.", file=sys.stderr)
    print("- update_player_materials: Update a player's material inventory.", file=sys.stderr)
    print("- read_world_data: Retrieve data about worlds.", file=sys.stderr)
    print("- delete_card: Delete a card from the database.", file=sys.stderr)
    print("- delete_cards: Delete multiple cards from the database.", file=sys.stderr)
    print("- log_game_session: Record gameplay metrics.", file=sys.stderr)
    print("", file=sys.stderr)
    
    try:
        # Run the MCP server
        print("Starting FastMCP server...", file=sys.stderr)
        
        # FastMCP unterstützt keine direkten TCP-Parameter
        # Wir verwenden stattdessen den Standard-Socket-Modus
        print("Running in socket mode for Claude Desktop", file=sys.stderr)
        
        if args.tcp:
            print("Note: TCP mode requested but FastMCP doesn't support direct TCP parameters.", file=sys.stderr)
            print("The server will run in socket mode, but you can still connect to it via Claude Desktop.", file=sys.stderr)
            
        mcp.run()
            
    except KeyboardInterrupt:
        print("Server shutting down...", file=sys.stderr)
    except Exception as e:
        print(f"Error starting server: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
