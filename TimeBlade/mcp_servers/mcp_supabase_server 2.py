#!/usr/bin/env python3
"""
MCP Server for Zeitklingen Card Game - Supabase Database Integration
This server provides tools for interacting with the Zeitklingen game database in Supabase.
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Set up paths for iCloud access
ICLOUD_PATH = Path("/Users/exqbitmac/Library/Mobile Documents/com~apple~CloudDocs/Zeitklingen")
ENV_PATH = ICLOUD_PATH / ".env"

# Load environment variables from .env file in iCloud
load_dotenv(dotenv_path=ENV_PATH)

# Add virtual environment site-packages to path
VENV_SITE_PACKAGES = ICLOUD_PATH / "venv/lib/python3.10/site-packages"
sys.path.append(str(VENV_SITE_PACKAGES))

import json
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from mcp.server.lowlevel.server import Server  # Correct import from mcp.server.lowlevel.server
from mcp.types import Tool  # Correct import from mcp.types
from pydantic import BaseModel, Field
from supabase import create_client, Client

# Models for request/response data
class CardFilter(BaseModel):
    """Filter parameters for card queries"""
    class_type: Optional[str] = Field(None, description="Filter by card class (Chronomant, Zeitwächter, Schattenschreiter)")
    element: Optional[str] = Field(None, description="Filter by elemental type (Fire, Water, Air, Earth, Metal)")
    evolution_level: Optional[int] = Field(None, description="Filter by evolution level (0-3)")
    
class Card(BaseModel):
    """Card data model"""
    id: str
    name: str
    type: str
    element: str
    base_cost: int
    effect: str
    evolution_level: int
    parent_card_id: Optional[str] = None

class PlayerProgress(BaseModel):
    """Player progress data model"""
    player_id: str
    username: str
    owned_cards: List[Dict[str, Any]]
    materials: List[Dict[str, Any]]
    completed_worlds: List[Dict[str, Any]]
    
class PlayerCardUpdate(BaseModel):
    """Model for updating player cards"""
    player_id: str
    card_id: str
    level: int
    evolution_path: Optional[str] = None
    materials_used: Optional[List[str]] = None
    
class MaterialUpdate(BaseModel):
    """Model for updating player materials"""
    player_id: str
    material_changes: List[Dict[str, Any]]
    reason: str = Field(..., description="Reason for material update (evolution, world_completion, purchase)")
    
class WorldFilter(BaseModel):
    """Filter parameters for world queries"""
    element: Optional[str] = None
    completed_by_player: Optional[str] = None
    
class GameSession(BaseModel):
    """Game session data for logging"""
    player_id: str
    world_id: str
    outcome: str = Field(..., description="win, loss, or abandoned")
    duration_seconds: int
    cards_played: List[str]
    remaining_time: Optional[int] = None
    difficulty: str

# Supabase client setup
def get_supabase_client() -> Client:
    """Create and return a Supabase client using environment variables"""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    if not supabase_url or not supabase_key:
        print("Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set", file=sys.stderr)
        print(f"Current environment variables: {os.environ.keys()}", file=sys.stderr)
        print(f"Checking .env file at {ENV_PATH}", file=sys.stderr)
        try:
            with open(ENV_PATH, 'r') as f:
                env_content = f.read()
                print(f"Found .env file with {len(env_content.splitlines())} lines", file=sys.stderr)
        except Exception as e:
            print(f"Error reading .env file: {e}", file=sys.stderr)
        raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables must be set")
    
    return create_client(supabase_url, supabase_key)

# MCP Server class
class ZeitklingenMCPServer:
    def __init__(self):
        # Reload environment variables to ensure they're available
        load_dotenv(dotenv_path=ENV_PATH)
        print(f"Initializing Zeitklingen MCP Server with .env from {ENV_PATH}", file=sys.stderr)
        self.supabase = get_supabase_client()
        self.mcp = Server(name="zeitklingen-supabase")
        
        # Register tools
        self.mcp.tools["read_cards"] = Tool(
            name="read_cards",
            description="Retrieve card information from the database with optional filtering",
            parameters=CardFilter.model_json_schema()["properties"],
            handler=self.read_cards
        )
        self.mcp.tools["read_player_progress"] = Tool(
            name="read_player_progress",
            description="Retrieve a player's current progress",
            parameters={"player_id": {"type": "string"}},
            handler=self.read_player_progress
        )
        self.mcp.tools["update_player_cards"] = Tool(
            name="update_player_cards",
            description="Update a player's deck",
            parameters=PlayerCardUpdate.model_json_schema()["properties"],
            handler=self.update_player_cards
        )
        self.mcp.tools["update_player_materials"] = Tool(
            name="update_player_materials",
            description="Update a player's material inventory",
            parameters=MaterialUpdate.model_json_schema()["properties"],
            handler=self.update_player_materials
        )
        self.mcp.tools["read_world_data"] = Tool(
            name="read_world_data",
            description="Retrieve data about worlds",
            parameters=WorldFilter.model_json_schema()["properties"],
            handler=self.read_world_data
        )
        self.mcp.tools["log_game_session"] = Tool(
            name="log_game_session",
            description="Record gameplay metrics",
            parameters=GameSession.model_json_schema()["properties"],
            handler=self.log_game_session
        )
    
    def read_cards(self, filter_params: Optional[CardFilter] = None) -> List[Card]:
        """Read cards from database with optional filtering"""
        query = self.supabase.table("cards").select("*")
        
        if filter_params:
            if filter_params.class_type:
                query = query.eq("type", filter_params.class_type)
            if filter_params.element:
                query = query.eq("element", filter_params.element)
            if filter_params.evolution_level is not None:
                query = query.eq("evolution_level", filter_params.evolution_level)
                
        response = query.execute()
        return [Card(**card) for card in response.data]
    
    def read_player_progress(self, player_id: str) -> PlayerProgress:
        """Retrieve a player's progress, including cards, materials, and worlds"""
        player = self.supabase.table("players").select("*").eq("id", player_id).single().execute()
        cards = self.supabase.table("player_cards").select("*, cards(*)").eq("player_id", player_id).execute()
        materials = self.supabase.table("player_materials").select("*, materials(*)").eq("player_id", player_id).execute()
        worlds = self.supabase.table("player_progress").select("*, worlds(*)").eq("player_id", player_id).execute()
        
        return PlayerProgress(
            player_id=player_id,
            username=player.data.get("username", "Unknown"),
            owned_cards=cards.data,
            materials=materials.data,
            completed_worlds=worlds.data
        )
    
    def update_player_cards(self, update: PlayerCardUpdate) -> Dict[str, Any]:
        """Update a player's cards (evolution, level change)"""
        existing = self.supabase.table("player_cards").select("*").eq("player_id", update.player_id).eq("card_id", update.card_id).execute()
        
        if not existing.data:
            result = self.supabase.table("player_cards").insert({
                "player_id": update.player_id,
                "card_id": update.card_id,
                "level": update.level,
                "evolution_path": update.evolution_path,
                "materials_used": update.materials_used
            }).execute()
        else:
            result = self.supabase.table("player_cards").update({
                "level": update.level,
                "evolution_path": update.evolution_path,
                "materials_used": update.materials_used
            }).eq("player_id", update.player_id).eq("card_id", update.card_id).execute()
            
        return {"success": True, "data": result.data}
    
    def update_player_materials(self, update: MaterialUpdate) -> Dict[str, Any]:
        """Update a player's material inventory"""
        results = []
        
        for change in update.material_changes:
            material_id = change["material_id"]
            quantity_change = change["quantity_change"]
            
            current = self.supabase.table("player_materials").select("quantity").eq("player_id", update.player_id).eq("material_id", material_id).execute()
            
            if not current.data:
                if quantity_change > 0:
                    result = self.supabase.table("player_materials").insert({
                        "player_id": update.player_id,
                        "material_id": material_id,
                        "quantity": quantity_change
                    }).execute()
                    results.append(result.data)
            else:
                new_quantity = current.data[0]["quantity"] + quantity_change
                
                if new_quantity <= 0:
                    result = self.supabase.table("player_materials").delete().eq("player_id", update.player_id).eq("material_id", material_id).execute()
                else:
                    result = self.supabase.table("player_materials").update({"quantity": new_quantity})\
                        .eq("player_id", update.player_id).eq("material_id", material_id).execute()
                
                results.append(result.data)
        
        self.supabase.table("material_logs").insert({
            "player_id": update.player_id,
            "changes": update.material_changes,
            "reason": update.reason,
            "timestamp": datetime.utcnow().isoformat()
        }).execute()
        
        return {"success": True, "data": results}
    
    def read_world_data(self, filter_params: Optional[WorldFilter] = None) -> List[Dict[str, Any]]:
        """Retrieve data about worlds, with optional filtering"""
        query = self.supabase.table("worlds").select("*")
        
        if filter_params:
            if filter_params.element:
                query = query.eq("element", filter_params.element)
                
            if filter_params.completed_by_player:
                completed = self.supabase.table("player_progress").select("world_id").eq("player_id", filter_params.completed_by_player).eq("completed", True).execute()
                
                completed_ids = [world["world_id"] for world in completed.data]
                if completed_ids:
                    query = query.in_("id", completed_ids)
                else:
                    return []
                
        worlds = query.execute()
        
        result = []
        for world in worlds.data:
            enemies = self.supabase.table("world_enemies").select("*").eq("world_id", world["id"]).execute()
            drops = self.supabase.table("world_drops").select("*, materials(*)").eq("world_id", world["id"]).execute()
            effects = self.supabase.table("world_effects").select("*").eq("world_id", world["id"]).execute()
            
            world_data = {
                **world,
                "enemies": enemies.data,
                "drops": drops.data,
                "field_effects": effects.data
            }
            
            result.append(world_data)
            
        return result
    
    def log_game_session(self, session: GameSession) -> Dict[str, Any]:
        """Log a game session with metrics"""
        session_data = {
            "player_id": session.player_id,
            "world_id": session.world_id,
            "start_time": (datetime.utcnow().timestamp() - session.duration_seconds),
            "end_time": datetime.utcnow().timestamp(),
            "outcome": session.outcome,
            "cards_played": session.cards_played,
            "remaining_time": session.remaining_time,
            "difficulty": session.difficulty
        }
        
        result = self.supabase.table("game_sessions").insert(session_data).execute()
        
        self.supabase.table("player_stats").upsert({
            "player_id": session.player_id,
            "last_played": datetime.utcnow().isoformat(),
            f"total_{session.outcome}s": self.supabase.raw(f"total_{session.outcome}s + 1"),
            "total_games": self.supabase.raw("total_games + 1")
        }).execute()
        
        if session.outcome == "win":
            progress = self.supabase.table("player_progress").select("*").eq("player_id", session.player_id).eq("world_id", session.world_id).execute()
            
            if not progress.data:
                self.supabase.table("player_progress").insert({
                    "player_id": session.player_id,
                    "world_id": session.world_id,
                    "completed": True,
                    "highest_difficulty": session.difficulty
                }).execute()
            else:
                current_difficulty = progress.data[0].get("highest_difficulty", "")
                difficulties = ["easy", "normal", "hard", "zeitriss"]
                
                if difficulties.index(session.difficulty) > difficulties.index(current_difficulty):
                    self.supabase.table("player_progress").update({
                        "highest_difficulty": session.difficulty
                    }).eq("player_id", session.player_id).eq("world_id", session.world_id).execute()
        
        return {"success": True, "session_id": result.data[0]["id"]}
    
    def start(self):
        print("Zeitklingen MCP Server läuft auf Port 8000", file=sys.stderr)
        print(f"Server verwendet Supabase URL: {os.getenv('SUPABASE_URL')}", file=sys.stderr)
        print(f"iCloud-Pfad: {ICLOUD_PATH}", file=sys.stderr)
        # Bind to 0.0.0.0 instead of localhost to allow connections from other processes
        self.mcp.start(host="0.0.0.0", port=8000)

# Main entry point
if __name__ == "__main__":
    try:
        print(f"Starting Zeitklingen MCP Server with Python {sys.version}", file=sys.stderr)
        print(f"Working directory: {os.getcwd()}", file=sys.stderr)
        print(f"iCloud path: {ICLOUD_PATH}", file=sys.stderr)
        print(f"Environment variables: {list(os.environ.keys())}", file=sys.stderr)
        
        server = ZeitklingenMCPServer()
        server.start()
        import time
        while True:
            time.sleep(1)
    except Exception as e:
        print(f"Error starting server: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()