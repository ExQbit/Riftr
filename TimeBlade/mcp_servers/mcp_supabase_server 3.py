#!/usr/bin/env python3
"""
MCP Server für Zeitklingen Supabase Integration
Ermöglicht Claude den Zugriff auf die Supabase-Datenbank für das Zeitklingen-Kartenspiel.
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
from typing import Dict, List, Optional, Any, Union, Awaitable
from mcp.server.lowlevel.server import Server as MCPServer
from mcp.types import Tool
from mcp.types import CallToolRequest
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
    evolution_level: Optional[int] = 0
    
class PlayerCardUpdate(BaseModel):
    """Model for updating a player's card collection"""
    player_id: str
    card_id: str
    quantity_change: int = Field(..., description="Positive to add cards, negative to remove")
    
class MaterialUpdate(BaseModel):
    """Model for updating a player's material inventory"""
    player_id: str
    material_type: str
    quantity_change: int = Field(..., description="Positive to add materials, negative to remove")
    
class WorldFilter(BaseModel):
    """Filter parameters for world queries"""
    world_id: Optional[str] = None
    difficulty: Optional[str] = None
    
class GameSession(BaseModel):
    """Game session metrics for analytics"""
    player_id: str
    session_duration: int
    cards_played: int
    victory: bool
    opponent_type: str
    world_id: Optional[str] = None

def get_supabase_client() -> Client:
    """Create and return a Supabase client using environment variables"""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    if not supabase_url or not supabase_key:
        raise ValueError("Missing Supabase credentials. Check your .env file.")
    
    return create_client(supabase_url, supabase_key)

class ZeitklingenMCPServer:
    """MCP Server implementation for Zeitklingen Supabase integration"""
    
    def __init__(self):
        # Reload environment variables to ensure they're available
        load_dotenv(dotenv_path=ENV_PATH)
        print(f"Initializing Zeitklingen MCP Server with .env from {ENV_PATH}", file=sys.stderr)
        self.supabase = get_supabase_client()
        
        # Initialize the MCP server
        self.mcp = MCPServer(name="zeitklingen-supabase")
        
        # Register request handlers for tool calls
        self.mcp.request_handlers[CallToolRequest] = self.handle_tool_call
        
        # Define and register tools
        self.register_tools()
    
    def register_tools(self):
        """Register all tools with the MCP server"""
        # Define the tools
        read_cards_tool = Tool(
            name="read_cards",
            description="Retrieve card information from the database with optional filtering",
            inputSchema={
                "type": "object",
                "properties": {
                    "class_type": {"type": "string", "description": "Filter by card class (Chronomant, Zeitwächter, Schattenschreiter)"},
                    "element": {"type": "string", "description": "Filter by elemental type (Fire, Water, Air, Earth, Metal)"},
                    "evolution_level": {"type": "integer", "description": "Filter by evolution level (0-3)"}
                }
            }
        )
        
        read_player_progress_tool = Tool(
            name="read_player_progress",
            description="Retrieve a player's current progress",
            inputSchema={
                "type": "object",
                "properties": {
                    "player_id": {"type": "string"}
                },
                "required": ["player_id"]
            }
        )
        
        update_player_cards_tool = Tool(
            name="update_player_cards",
            description="Update a player's deck",
            inputSchema={
                "type": "object",
                "properties": {
                    "player_id": {"type": "string"},
                    "card_id": {"type": "string"},
                    "quantity_change": {"type": "integer", "description": "Positive to add cards, negative to remove"}
                },
                "required": ["player_id", "card_id", "quantity_change"]
            }
        )
        
        update_player_materials_tool = Tool(
            name="update_player_materials",
            description="Update a player's material inventory",
            inputSchema={
                "type": "object",
                "properties": {
                    "player_id": {"type": "string"},
                    "material_type": {"type": "string"},
                    "quantity_change": {"type": "integer", "description": "Positive to add materials, negative to remove"}
                },
                "required": ["player_id", "material_type", "quantity_change"]
            }
        )
        
        read_world_data_tool = Tool(
            name="read_world_data",
            description="Retrieve data about worlds",
            inputSchema={
                "type": "object",
                "properties": {
                    "world_id": {"type": "string"},
                    "difficulty": {"type": "string"}
                }
            }
        )
        
        log_game_session_tool = Tool(
            name="log_game_session",
            description="Record gameplay metrics",
            inputSchema={
                "type": "object",
                "properties": {
                    "player_id": {"type": "string"},
                    "session_duration": {"type": "integer"},
                    "cards_played": {"type": "integer"},
                    "victory": {"type": "boolean"},
                    "opponent_type": {"type": "string"},
                    "world_id": {"type": "string"}
                },
                "required": ["player_id", "session_duration", "cards_played", "victory", "opponent_type"]
            }
        )
        
        # Add tools to the server's capabilities
        self.mcp.capabilities.tools = [
            read_cards_tool,
            read_player_progress_tool,
            update_player_cards_tool,
            update_player_materials_tool,
            read_world_data_tool,
            log_game_session_tool
        ]
    
    async def handle_tool_call(self, request: CallToolRequest, context):
        """Handle tool call requests"""
        tool_name = request.params.name
        arguments = request.params.arguments
        
        print(f"Tool call: {tool_name} with arguments: {arguments}", file=sys.stderr)
        
        # Map tool names to handler methods
        handlers = {
            "read_cards": self.read_cards,
            "read_player_progress": self.read_player_progress,
            "update_player_cards": self.update_player_cards,
            "update_player_materials": self.update_player_materials,
            "read_world_data": self.read_world_data,
            "log_game_session": self.log_game_session
        }
        
        if tool_name not in handlers:
            return {
                "error": f"Unknown tool: {tool_name}"
            }
        
        try:
            # Call the appropriate handler
            result = handlers[tool_name](arguments)
            return {
                "result": result
            }
        except Exception as e:
            print(f"Error handling tool call: {str(e)}", file=sys.stderr)
            return {
                "error": str(e)
            }
    
    def read_cards(self, params):
        """Retrieve card information with optional filtering"""
        try:
            query = self.supabase.table("cards").select("*")
            
            # Apply filters if provided
            if params.get("class_type"):
                query = query.eq("type", params["class_type"])
            if params.get("element"):
                query = query.eq("element", params["element"])
            if params.get("evolution_level") is not None:
                query = query.eq("evolution_level", params["evolution_level"])
                
            response = query.execute()
            return {"cards": response.data}
        except Exception as e:
            print(f"Error reading cards: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def read_player_progress(self, params):
        """Retrieve a player's current progress"""
        try:
            player_id = params.get("player_id")
            if not player_id:
                return {"error": "player_id is required"}
                
            # Get player data
            player_data = self.supabase.table("players").select("*").eq("id", player_id).execute()
            
            # Get player's cards
            player_cards = self.supabase.table("player_cards").select("*").eq("player_id", player_id).execute()
            
            # Get player's materials
            player_materials = self.supabase.table("player_materials").select("*").eq("player_id", player_id).execute()
            
            return {
                "player": player_data.data[0] if player_data.data else None,
                "cards": player_cards.data,
                "materials": player_materials.data
            }
        except Exception as e:
            print(f"Error reading player progress: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def update_player_cards(self, params):
        """Update a player's card collection"""
        try:
            player_id = params.get("player_id")
            card_id = params.get("card_id")
            quantity_change = params.get("quantity_change", 0)
            
            if not all([player_id, card_id]):
                return {"error": "player_id and card_id are required"}
            
            # Check if player has the card
            existing_card = self.supabase.table("player_cards").select("*").eq("player_id", player_id).eq("card_id", card_id).execute()
            
            if existing_card.data:
                # Update existing card quantity
                current_quantity = existing_card.data[0].get("quantity", 0)
                new_quantity = max(0, current_quantity + quantity_change)
                
                if new_quantity == 0:
                    # Remove card if quantity becomes zero
                    self.supabase.table("player_cards").delete().eq("player_id", player_id).eq("card_id", card_id).execute()
                    return {"message": f"Card {card_id} removed from player {player_id}'s collection"}
                else:
                    # Update quantity
                    self.supabase.table("player_cards").update({"quantity": new_quantity}).eq("player_id", player_id).eq("card_id", card_id).execute()
                    return {"message": f"Card {card_id} quantity updated to {new_quantity}"}
            elif quantity_change > 0:
                # Add new card to player's collection
                self.supabase.table("player_cards").insert({"player_id": player_id, "card_id": card_id, "quantity": quantity_change}).execute()
                return {"message": f"Added {quantity_change} of card {card_id} to player {player_id}'s collection"}
            else:
                return {"error": "Cannot remove a card the player doesn't have"}
        except Exception as e:
            print(f"Error updating player cards: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def update_player_materials(self, params):
        """Update a player's material inventory"""
        try:
            player_id = params.get("player_id")
            material_type = params.get("material_type")
            quantity_change = params.get("quantity_change", 0)
            
            if not all([player_id, material_type]):
                return {"error": "player_id and material_type are required"}
            
            # Check if player has the material
            existing_material = self.supabase.table("player_materials").select("*").eq("player_id", player_id).eq("material_type", material_type).execute()
            
            if existing_material.data:
                # Update existing material quantity
                current_quantity = existing_material.data[0].get("quantity", 0)
                new_quantity = max(0, current_quantity + quantity_change)
                
                if new_quantity == 0:
                    # Remove material if quantity becomes zero
                    self.supabase.table("player_materials").delete().eq("player_id", player_id).eq("material_type", material_type).execute()
                    return {"message": f"Material {material_type} removed from player {player_id}'s inventory"}
                else:
                    # Update quantity
                    self.supabase.table("player_materials").update({"quantity": new_quantity}).eq("player_id", player_id).eq("material_type", material_type).execute()
                    return {"message": f"Material {material_type} quantity updated to {new_quantity}"}
            elif quantity_change > 0:
                # Add new material to player's inventory
                self.supabase.table("player_materials").insert({"player_id": player_id, "material_type": material_type, "quantity": quantity_change}).execute()
                return {"message": f"Added {quantity_change} of material {material_type} to player {player_id}'s inventory"}
            else:
                return {"error": "Cannot remove a material the player doesn't have"}
        except Exception as e:
            print(f"Error updating player materials: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def read_world_data(self, params):
        """Retrieve data about worlds"""
        try:
            query = self.supabase.table("worlds").select("*")
            
            # Apply filters if provided
            if params.get("world_id"):
                query = query.eq("id", params["world_id"])
            if params.get("difficulty"):
                query = query.eq("difficulty", params["difficulty"])
                
            response = query.execute()
            return {"worlds": response.data}
        except Exception as e:
            print(f"Error reading world data: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def log_game_session(self, params):
        """Record gameplay metrics"""
        try:
            # Add timestamp
            params["timestamp"] = datetime.now().isoformat()
            
            # Insert session data
            self.supabase.table("game_sessions").insert(params).execute()
            
            return {"message": "Game session logged successfully"}
        except Exception as e:
            print(f"Error logging game session: {str(e)}", file=sys.stderr)
            return {"error": str(e)}
    
    def start(self):
        """Start the MCP server"""
        try:
            print("Starting Zeitklingen MCP Server...", file=sys.stderr)
            self.mcp.start(host="0.0.0.0", port=8000)
        except Exception as e:
            print(f"Error starting server: {str(e)}", file=sys.stderr)
            raise

if __name__ == "__main__":
    print(f"Starting Zeitklingen MCP Server with Python {sys.version}", file=sys.stderr)
    print(f"Working directory: {os.getcwd()}", file=sys.stderr)
    print(f"iCloud path: {ICLOUD_PATH}", file=sys.stderr)
    print(f"Environment variables: {list(os.environ.keys())}", file=sys.stderr)
    
    try:
        server = ZeitklingenMCPServer()
        server.start()
    except Exception as e:
        print(f"Error starting server: {str(e)}", file=sys.stderr)
        sys.exit(1)
