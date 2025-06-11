#!/usr/bin/env python3
"""
MCP Server für Zeitklingen Supabase Integration
Ermöglicht Claude den Zugriff auf die Supabase-Datenbank für das Zeitklingen-Kartenspiel.
"""

import os
import sys
import json
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from dotenv import load_dotenv

# Set up paths for iCloud access
ICLOUD_PATH = Path("/Users/exqbitmac/Library/Mobile Documents/com~apple~CloudDocs/Zeitklingen")
ENV_PATH = ICLOUD_PATH / ".env"

# Load environment variables from .env file in iCloud
load_dotenv(dotenv_path=ENV_PATH)

# Add virtual environment site-packages to path if needed
VENV_SITE_PACKAGES = ICLOUD_PATH / "venv/lib/python3.10/site-packages"
if str(VENV_SITE_PACKAGES) not in sys.path:
    sys.path.append(str(VENV_SITE_PACKAGES))

# Import MCP modules
from mcp.server.lowlevel.server import Server
from mcp.server.models import InitializationOptions
import mcp.types as types
from mcp.server.stdio import stdio_server

# Import Supabase client
from supabase import create_client, Client
from pydantic import BaseModel, Field

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
        
        # Initialize Supabase client
        self.supabase = get_supabase_client()
        
        # Initialize the MCP server
        self.server = Server("zeitklingen-supabase")
        
        # Register handlers
        @self.server.list_tools()
        async def handle_list_tools() -> list[types.Tool]:
            """Handler for listing available tools"""
            return [
                types.Tool(
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
                ),
                types.Tool(
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
            ]
        
        @self.server.call_tool()
        async def handle_call_tool(name: str, arguments: dict | None) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
            """Handler for tool calls"""
            print(f"Tool call: {name} with arguments: {arguments}", file=sys.stderr)
            
            # Map tool names to handler methods
            handlers = {
                "read_cards": self.read_cards,
                "read_player_progress": self.read_player_progress
            }
            
            if name not in handlers:
                return [types.TextContent(text=json.dumps({"error": f"Unknown tool: {name}"}))]
            
            try:
                # Call the appropriate handler
                result = handlers[name](arguments or {})
                return [types.TextContent(text=json.dumps(result))]
            except Exception as e:
                print(f"Error handling tool call: {str(e)}", file=sys.stderr)
                return [types.TextContent(text=json.dumps({"error": str(e)}))]
    
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

async def main():
    """Main entry point for the MCP server"""
    print(f"Starting Zeitklingen MCP Server with Python {sys.version}", file=sys.stderr)
    print(f"Working directory: {os.getcwd()}", file=sys.stderr)
    print(f"iCloud path: {ICLOUD_PATH}", file=sys.stderr)
    
    try:
        # Initialize server
        server = ZeitklingenMCPServer()
        
        # Create initialization options
        init_options = InitializationOptions(
            server_name="zeitklingen-supabase",
            server_version="1.0.0",
            capabilities={}  # Simplified for now
        )
        
        # Use stdio for communication as shown in the example
        print("Starting server with stdio communication...", file=sys.stderr)
        async with stdio_server() as (read_stream, write_stream):
            await server.server.run(
                read_stream,
                write_stream,
                init_options,
                raise_exceptions=True
            )
    except Exception as e:
        print(f"Error in main: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Server shutting down...", file=sys.stderr)
    except Exception as e:
        print(f"Error starting server: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
