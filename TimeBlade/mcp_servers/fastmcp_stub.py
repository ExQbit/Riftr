#!/usr/bin/env python3
"""
Erweiterte FastMCP Implementation für Zeitklingen
"""

from typing import Callable, Any, Dict, List, Optional
from pydantic import BaseModel
import inspect

class Tool(BaseModel):
    name: str
    description: str
    parameters: dict
    
class FastMCP:
    def __init__(self, name: str = "Zeitklingen MCP Server"):
        self.name = name
        self.tools: Dict[str, Tool] = {}
    
    def register_tool(self, func: Callable) -> Callable:
        """Registriert eine Funktion als Tool mit automatischer Parametererkennung"""
        sig = inspect.signature(func)
        parameters = {}
        
        for name, param in sig.parameters.items():
            if name == "self":
                continue
            parameters[name] = {
                "type": str(param.annotation) if param.annotation != inspect.Parameter.empty else "Any",
                "required": param.default == inspect.Parameter.empty
            }
        
        self.tools[func.__name__] = Tool(
            name=func.__name__,
            description=func.__doc__ or "",
            parameters=parameters
        )
        return func
    
    def start(self, port: int = 8000):
        """Startet den MCP Server"""
        self.port = port
        print(f"Zeitklingen MCP Server läuft auf Port {self.port}")
        print("Verfügbare Tools (" + str(len(self.tools)) + "):")
        for tool_name, tool_data in self.tools.items():
            print(f"- {tool_name}: {tool_data.description}")
        print("Zeitklingen MCP Server is ready to process requests")
