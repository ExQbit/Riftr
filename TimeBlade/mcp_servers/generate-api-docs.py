#!/usr/bin/env python3
"""
generate-api-docs.py

Dieses Skript generiert API-Dokumentation aus Code-Kommentaren im Zeitklingen-Projekt.
Es scannt C#-Dateien nach XML-Dokumentationskommentaren und erstellt Markdown-Dateien
mit der API-Dokumentation.

Verwendung:
    python3 generate-api-docs.py

Abhängigkeiten:
    - Python 3.6+
    - re (reguläre Ausdrücke)
    - os (Dateisystemoperationen)
    - glob (Dateimuster-Matching)
"""

import os
import re
import glob
import json
from datetime import datetime
from collections import defaultdict

# Pfade
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_PATH = os.path.join(PROJECT_ROOT, "Assets")
SCRIPTS_PATH = os.path.join(ASSETS_PATH, "Scripts") if os.path.exists(os.path.join(ASSETS_PATH, "Scripts")) else None
DOCS_PATH = os.path.join(PROJECT_ROOT, "docs")
API_DOCS_PATH = os.path.join(DOCS_PATH, "api")

# Stelle sicher, dass die Dokumentationsverzeichnisse existieren
os.makedirs(API_DOCS_PATH, exist_ok=True)

def log(message):
    """Protokolliert eine Nachricht mit Zeitstempel."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def find_matching_brace(content):
    """Findet die schließende geschweifte Klammer für die erste öffnende Klammer."""
    brace_count = 0
    for i, char in enumerate(content):
        if char == '{':
            brace_count += 1
        elif char == '}':
            brace_count -= 1
            if brace_count == 0:
                return i
    return -1

def extract_xml_doc(comment):
    """Extrahiert Informationen aus einem XML-Dokumentationskommentar."""
    result = {
        "summary": "",
        "params": {},
        "returns": "",
        "remarks": "",
        "example": "",
        "exceptions": {}
    }
    
    if not comment:
        return result
    
    # Entferne Kommentarzeichen und führende Leerzeichen
    lines = comment.split("\n")
    cleaned_lines = []
    for line in lines:
        line = line.strip()
        line = re.sub(r"^///\s*", "", line)  # Entferne ///
        line = re.sub(r"^//\s*", "", line)   # Entferne //
        line = re.sub(r"^\*\s*", "", line)   # Entferne *
        cleaned_lines.append(line)
    
    # Verarbeite XML-Tags
    current_tag = None
    current_content = ""
    current_param_name = ""
    
    for line in cleaned_lines:
        # Öffnende Tags
        summary_match = re.match(r"<summary>(.*)", line)
        param_match = re.match(r"<param\s+name=\"([^\"]+)\">(.*)", line)
        returns_match = re.match(r"<returns>(.*)", line)
        remarks_match = re.match(r"<remarks>(.*)", line)
        example_match = re.match(r"<example>(.*)", line)
        exception_match = re.match(r"<exception\s+cref=\"([^\"]+)\">(.*)", line)
        
        # Schließende Tags
        end_summary = re.match(r"(.*)</summary>", line)
        end_param = re.match(r"(.*)</param>", line)
        end_returns = re.match(r"(.*)</returns>", line)
        end_remarks = re.match(r"(.*)</remarks>", line)
        end_example = re.match(r"(.*)</example>", line)
        end_exception = re.match(r"(.*)</exception>", line)
        
        # Verarbeite öffnende Tags
        if summary_match:
            current_tag = "summary"
            current_content = summary_match.group(1).strip()
        elif param_match:
            current_tag = "param"
            current_param_name = param_match.group(1).strip()
            current_content = param_match.group(2).strip()
        elif returns_match:
            current_tag = "returns"
            current_content = returns_match.group(1).strip()
        elif remarks_match:
            current_tag = "remarks"
            current_content = remarks_match.group(1).strip()
        elif example_match:
            current_tag = "example"
            current_content = example_match.group(1).strip()
        elif exception_match:
            current_tag = "exception"
            current_param_name = exception_match.group(1).strip()
            current_content = exception_match.group(2).strip()
        # Verarbeite schließende Tags
        elif end_summary:
            current_content += " " + end_summary.group(1).strip()
            result["summary"] = current_content.strip()
            current_tag = None
        elif end_param:
            current_content += " " + end_param.group(1).strip()
            result["params"][current_param_name] = current_content.strip()
            current_tag = None
        elif end_returns:
            current_content += " " + end_returns.group(1).strip()
            result["returns"] = current_content.strip()
            current_tag = None
        elif end_remarks:
            current_content += " " + end_remarks.group(1).strip()
            result["remarks"] = current_content.strip()
            current_tag = None
        elif end_example:
            current_content += " " + end_example.group(1).strip()
            result["example"] = current_content.strip()
            current_tag = None
        elif end_exception:
            current_content += " " + end_exception.group(1).strip()
            result["exceptions"][current_param_name] = current_content.strip()
            current_tag = None
        # Fortsetzen des aktuellen Tags
        elif current_tag:
            current_content += " " + line.strip()
    
    # Speichere verbleibende Inhalte
    if current_tag == "summary":
        result["summary"] = current_content.strip()
    elif current_tag == "param":
        result["params"][current_param_name] = current_content.strip()
    elif current_tag == "returns":
        result["returns"] = current_content.strip()
    elif current_tag == "remarks":
        result["remarks"] = current_content.strip()
    elif current_tag == "example":
        result["example"] = current_content.strip()
    elif current_tag == "exception":
        result["exceptions"][current_param_name] = current_content.strip()
    
    return result

def parse_cs_file(file_path):
    """Parst eine C#-Datei und extrahiert Klassen, Methoden und ihre Dokumentation."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        namespace = None
        namespace_match = re.search(r"namespace\s+([^\s{]+)", content)
        if namespace_match:
            namespace = namespace_match.group(1)
        
        result = {
            "file": os.path.relpath(file_path, PROJECT_ROOT),
            "namespace": namespace,
            "classes": []
        }
        
        # Suche nach Klassen
        class_pattern = r"(?:///.*?\n)*\s*(?:public|internal|private|protected)\s+(?:abstract|sealed|static)?\s*class\s+(\w+)(?:<[^>]+>)?(?:\s*:\s*[^{]+)?\s*\{"
        class_matches = re.finditer(class_pattern, content, re.DOTALL)
        
        for class_match in class_matches:
            class_name = class_match.group(1)
            class_start = class_match.start()
            
            # Suche nach Klassendokumentation
            class_doc = ""
            doc_pattern = r"((?:///.*?\n)+)\s*(?:public|internal|private|protected)"
            doc_match = re.search(doc_pattern, content[:class_start], re.DOTALL)
            if doc_match:
                class_doc = doc_match.group(1)
            
            class_content = content[class_start:]
            class_end = find_matching_brace(class_content)
            if class_end > 0:
                class_content = class_content[:class_end]
            
            class_info = {
                "name": class_name,
                "documentation": extract_xml_doc(class_doc),
                "methods": [],
                "properties": []
            }
            
            # Suche nach Methoden
            method_pattern = r"(?:///.*?\n)*\s*(?:public|internal|private|protected)\s+(?:abstract|virtual|override|sealed|static)?\s*(?:<[^>]+>\s*)?(?:\w+(?:<[^>]+>)?)\s+(\w+)\s*\(([^)]*)\)\s*(?:where\s+[^{]+)?\s*\{"
            method_matches = re.finditer(method_pattern, class_content, re.DOTALL)
            
            for method_match in method_matches:
                method_name = method_match.group(1)
                method_params = method_match.group(2)
                method_start = method_match.start()
                
                # Suche nach Methodendokumentation
                method_doc = ""
                doc_match = re.search(doc_pattern, class_content[:method_start], re.DOTALL)
                if doc_match:
                    method_doc = doc_match.group(1)
                
                method_info = {
                    "name": method_name,
                    "parameters": parse_parameters(method_params),
                    "documentation": extract_xml_doc(method_doc)
                }
                
                class_info["methods"].append(method_info)
            
            # Suche nach Properties
            property_pattern = r"(?:///.*?\n)*\s*(?:public|internal|private|protected)\s+(?:abstract|virtual|override|sealed|static)?\s*(?:\w+(?:<[^>]+>)?)\s+(\w+)\s*\{\s*(?:get|set)"
            property_matches = re.finditer(property_pattern, class_content, re.DOTALL)
            
            for property_match in property_matches:
                property_name = property_match.group(1)
                property_start = property_match.start()
                
                # Suche nach Property-Dokumentation
                property_doc = ""
                doc_match = re.search(doc_pattern, class_content[:property_start], re.DOTALL)
                if doc_match:
                    property_doc = doc_match.group(1)
                
                property_info = {
                    "name": property_name,
                    "documentation": extract_xml_doc(property_doc)
                }
                
                class_info["properties"].append(property_info)
            
            result["classes"].append(class_info)
        
        return result
    
    except Exception as e:
        log(f"Fehler beim Parsen von {file_path}: {e}")
        return None

def parse_parameters(params_str):
    """Parst die Parameterliste einer Methode."""
    if not params_str.strip():
        return []
    
    params = []
    param_parts = params_str.split(",")
    
    for part in param_parts:
        part = part.strip()
        if not part:
            continue
        
        # Behandle Standardwerte
        if "=" in part:
            part = part.split("=")[0].strip()
        
        # Extrahiere Typ und Name
        parts = part.split()
        if len(parts) >= 2:
            param_type = " ".join(parts[:-1])
            param_name = parts[-1]
            params.append({
                "type": param_type,
                "name": param_name
            })
    
    return params

def generate_markdown_docs(parsed_files):
    """Generiert Markdown-Dokumentation aus den geparsten Dateien."""
    # Erstelle Index-Datei
    index_path = os.path.join(API_DOCS_PATH, "index.md")
    with open(index_path, "w", encoding="utf-8") as f:
        f.write("# Zeitklingen API-Dokumentation\n\n")
        f.write("## Namespaces\n\n")
        
        # Sammle Namespaces
        namespaces = defaultdict(list)
        for file_info in parsed_files:
            if file_info and file_info["namespace"]:
                for class_info in file_info["classes"]:
                    namespaces[file_info["namespace"]].append({
                        "name": class_info["name"],
                        "file": file_info["file"]
                    })
        
        # Schreibe Namespaces in Index
        for namespace, classes in sorted(namespaces.items()):
            f.write(f"### {namespace}\n\n")
            for class_info in sorted(classes, key=lambda x: x["name"]):
                class_filename = f"{namespace}.{class_info['name']}.md"
                class_path = class_filename.replace(".", "/")
                f.write(f"- [{class_info['name']}]({class_path})\n")
            f.write("\n")
    
    log(f"Index-Datei erstellt: {index_path}")
    
    # Erstelle Klassendateien
    for file_info in parsed_files:
        if not file_info:
            continue
        
        namespace = file_info["namespace"] or "Global"
        
        for class_info in file_info["classes"]:
            class_name = class_info["name"]
            class_dir = os.path.join(API_DOCS_PATH, namespace.replace(".", os.path.sep))
            os.makedirs(class_dir, exist_ok=True)
            
            class_doc_path = os.path.join(class_dir, f"{class_name}.md")
            
            with open(class_doc_path, "w", encoding="utf-8") as f:
                f.write(f"# {class_name}\n\n")
                
                # Klassenbeschreibung
                if class_info["documentation"]["summary"]:
                    f.write(f"{class_info['documentation']['summary']}\n\n")
                
                # Datei-Info
                f.write(f"**Namespace:** {namespace}  \n")
                f.write(f"**Datei:** {file_info['file']}  \n\n")
                
                # Bemerkungen
                if class_info["documentation"]["remarks"]:
                    f.write("## Bemerkungen\n\n")
                    f.write(f"{class_info['documentation']['remarks']}\n\n")
                
                # Beispiel
                if class_info["documentation"]["example"]:
                    f.write("## Beispiel\n\n")
                    f.write("```csharp\n")
                    f.write(f"{class_info['documentation']['example']}\n")
                    f.write("```\n\n")
                
                # Properties
                if class_info["properties"]:
                    f.write("## Properties\n\n")
                    for prop in sorted(class_info["properties"], key=lambda x: x["name"]):
                        f.write(f"### {prop['name']}\n\n")
                        if prop["documentation"]["summary"]:
                            f.write(f"{prop['documentation']['summary']}\n\n")
                    f.write("\n")
                
                # Methoden
                if class_info["methods"]:
                    f.write("## Methoden\n\n")
                    for method in sorted(class_info["methods"], key=lambda x: x["name"]):
                        f.write(f"### {method['name']}\n\n")
                        
                        # Methodenbeschreibung
                        if method["documentation"]["summary"]:
                            f.write(f"{method['documentation']['summary']}\n\n")
                        
                        # Parameter
                        if method["parameters"]:
                            f.write("#### Parameter\n\n")
                            for param in method["parameters"]:
                                param_name = param["name"]
                                param_type = param["type"]
                                param_desc = method["documentation"]["params"].get(param_name, "")
                                f.write(f"- **{param_name}** ({param_type}): {param_desc}\n")
                            f.write("\n")
                        
                        # Rückgabewert
                        if method["documentation"]["returns"]:
                            f.write("#### Rückgabewert\n\n")
                            f.write(f"{method['documentation']['returns']}\n\n")
                        
                        # Ausnahmen
                        if method["documentation"]["exceptions"]:
                            f.write("#### Ausnahmen\n\n")
                            for exc_type, exc_desc in method["documentation"]["exceptions"].items():
                                f.write(f"- **{exc_type}**: {exc_desc}\n")
                            f.write("\n")
                        
                        # Beispiel
                        if method["documentation"]["example"]:
                            f.write("#### Beispiel\n\n")
                            f.write("```csharp\n")
                            f.write(f"{method['documentation']['example']}\n")
                            f.write("```\n\n")
            
            log(f"Klassendokumentation erstellt: {class_doc_path}")

def main():
    """Hauptfunktion."""
    log("Starte API-Dokumentationsgenerierung...")
    
    if not SCRIPTS_PATH:
        log("Skriptverzeichnis nicht gefunden.")
        return
    
    # Scanne C#-Dateien
    cs_files = glob.glob(os.path.join(SCRIPTS_PATH, "**/*.cs"), recursive=True)
    log(f"{len(cs_files)} C#-Dateien gefunden.")
    
    # Parse Dateien
    parsed_files = []
    for cs_file in cs_files:
        parsed_file = parse_cs_file(cs_file)
        if parsed_file and parsed_file["classes"]:
            parsed_files.append(parsed_file)
    
    log(f"{len(parsed_files)} Dateien mit Klassen geparst.")
    
    # Generiere Markdown-Dokumentation
    generate_markdown_docs(parsed_files)
    
    log("API-Dokumentation erfolgreich generiert.")
    log(f"Dokumentation verfügbar unter: {API_DOCS_PATH}")

if __name__ == "__main__":
    main()
