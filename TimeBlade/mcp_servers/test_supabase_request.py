import json
import socket
import sys
import os
from pathlib import Path

# Set up paths for iCloud access
ICLOUD_PATH = Path("/Users/exqbitmac/Library/Mobile Documents/com~apple~CloudDocs/Zeitklingen")

def send_request(tool_name, parameters=None, host="localhost", port=8000):
    message = {
        "tool": tool_name,
        "parameters": parameters or {}
    }

    print(f"Verbindung zu {host}:{port} wird hergestellt...")
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5)  # Set timeout to 5 seconds
            s.connect((host, port))
            print(f"Verbindung hergestellt. Sende Anfrage: {tool_name}")
            s.sendall((json.dumps(message) + "\n").encode())
            
            response = s.recv(100000)
            print("Antwort vom Server:")
            print(response.decode())
            return response.decode()
    except ConnectionRefusedError:
        print(f"Fehler: Verbindung zu {host}:{port} wurde verweigert. Läuft der MCP-Server?")
        return None
    except socket.timeout:
        print(f"Fehler: Zeitüberschreitung bei der Verbindung zu {host}:{port}")
        return None
    except Exception as e:
        print(f"Fehler bei der Verbindung: {e}")
        return None

def test_all_connections():
    # Test different connection options
    hosts = ["localhost", "127.0.0.1", "0.0.0.0"]
    
    for host in hosts:
        print(f"\nTeste Verbindung zu {host}:8000...")
        result = send_request("read_cards", host=host)
        if result:
            print(f"✅ Verbindung zu {host}:8000 erfolgreich!")
            return True
    
    print("❌ Keine Verbindung konnte hergestellt werden.")
    return False

if __name__ == "__main__":
    print(f"Teste MCP-Server Verbindung für Zeitklingen Supabase...")
    print(f"iCloud-Pfad: {ICLOUD_PATH}")
    
    # Test connection to the server
    success = test_all_connections()
    
    if not success:
        print("\nVersuche, den Server zu starten...")
        import subprocess
        import time
        
        try:
            # Start the server in the background
            server_path = ICLOUD_PATH / "zk-commands" / "mcp_supabase_server.py"
            print(f"Starte Server: {server_path}")
            
            # Use the virtual environment Python
            venv_python = ICLOUD_PATH / "venv" / "bin" / "python"
            if venv_python.exists():
                python_cmd = str(venv_python)
            else:
                python_cmd = "python3"
                
            subprocess.Popen([python_cmd, str(server_path)])
            
            # Wait for the server to start
            print("Warte 5 Sekunden, bis der Server gestartet ist...")
            time.sleep(5)
            
            # Try to connect again
            test_all_connections()
        except Exception as e:
            print(f"Fehler beim Starten des Servers: {e}")