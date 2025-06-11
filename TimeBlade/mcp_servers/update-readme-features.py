#!/usr/bin/env python3
"""
update-readme-features.py

Dieses Skript aktualisiert die README.md-Datei automatisch basierend auf Codeänderungen.
Es scannt das Projekt nach neuen Features und Funktionen und aktualisiert die entsprechenden
Abschnitte in der README.md-Datei.

Verwendung:
    python3 update-readme-features.py

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

# Pfade
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
README_PATH = os.path.join(PROJECT_ROOT, "README.md")
ASSETS_PATH = os.path.join(PROJECT_ROOT, "Assets")
SCRIPTS_PATH = os.path.join(ASSETS_PATH, "Scripts") if os.path.exists(os.path.join(ASSETS_PATH, "Scripts")) else None
FEATURES_CACHE_PATH = os.path.join(PROJECT_ROOT, ".readme-features-cache.json")

# Abschnitte in README.md
FEATURES_SECTION_START = "## ✨ Hauptmerkmale"
CLASSES_SECTION_START = "## 🃏 Spielklassen & Mechaniken"
COMBAT_SECTION_START = "## ⏰ Timeline-basiertes Kampfsystem"

def log(message):
    """Protokolliert eine Nachricht mit Zeitstempel."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def read_readme():
    """Liest die README.md-Datei und gibt den Inhalt zurück."""
    try:
        with open(README_PATH, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        log(f"Fehler beim Lesen der README.md: {e}")
        return None

def write_readme(content):
    """Schreibt den übergebenen Inhalt in die README.md-Datei."""
    try:
        with open(README_PATH, "w", encoding="utf-8") as f:
            f.write(content)
        log("README.md erfolgreich aktualisiert.")
        return True
    except Exception as e:
        log(f"Fehler beim Schreiben der README.md: {e}")
        return False

def load_features_cache():
    """Lädt den Cache der erkannten Features."""
    if os.path.exists(FEATURES_CACHE_PATH):
        try:
            with open(FEATURES_CACHE_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            log(f"Fehler beim Laden des Feature-Caches: {e}")
    return {"features": [], "classes": [], "last_update": None}

def save_features_cache(cache):
    """Speichert den Cache der erkannten Features."""
    cache["last_update"] = datetime.now().isoformat()
    try:
        with open(FEATURES_CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2, ensure_ascii=False)
        log("Feature-Cache erfolgreich gespeichert.")
        return True
    except Exception as e:
        log(f"Fehler beim Speichern des Feature-Caches: {e}")
        return False

def scan_for_features():
    """Scannt das Projekt nach Features und Klassen."""
    features = []
    classes = []
    
    if not SCRIPTS_PATH:
        log("Skriptverzeichnis nicht gefunden.")
        return features, classes
    
    # Scanne C#-Skripte
    for cs_file in glob.glob(os.path.join(SCRIPTS_PATH, "**/*.cs"), recursive=True):
        try:
            with open(cs_file, "r", encoding="utf-8") as f:
                content = f.read()
                
                # Suche nach Klassen
                class_matches = re.finditer(r"public\s+class\s+(\w+).*?{", content, re.DOTALL)
                for match in class_matches:
                    class_name = match.group(1)
                    class_content = content[match.start():]
                    end_brace_index = find_matching_brace(class_content)
                    if end_brace_index > 0:
                        class_content = class_content[:end_brace_index]
                    
                    # Suche nach Klassenkommentaren
                    class_comment = ""
                    comment_match = re.search(r"/\*\*(.*?)\*/", content[:match.start()], re.DOTALL)
                    if comment_match:
                        class_comment = comment_match.group(1).strip()
                    
                    # Kategorisiere Klassen
                    if "Chronomant" in class_name or "TimeManipulation" in class_name:
                        classes.append({
                            "name": class_name,
                            "type": "Chronomant",
                            "description": extract_description(class_comment),
                            "file": os.path.relpath(cs_file, PROJECT_ROOT)
                        })
                    elif "Wächter" in class_name or "Guardian" in class_name or "Protector" in class_name:
                        classes.append({
                            "name": class_name,
                            "type": "Zeitwächter",
                            "description": extract_description(class_comment),
                            "file": os.path.relpath(cs_file, PROJECT_ROOT)
                        })
                    elif "Schatten" in class_name or "Shadow" in class_name:
                        classes.append({
                            "name": class_name,
                            "type": "Schattenschreiter",
                            "description": extract_description(class_comment),
                            "file": os.path.relpath(cs_file, PROJECT_ROOT)
                        })
                    
                    # Suche nach Features in Methoden
                    method_matches = re.finditer(r"public\s+\w+\s+(\w+)\s*\(.*?\)\s*{", class_content, re.DOTALL)
                    for method_match in method_matches:
                        method_name = method_match.group(1)
                        method_content = class_content[method_match.start():]
                        end_method_index = find_matching_brace(method_content)
                        if end_method_index > 0:
                            method_content = method_content[:end_method_index]
                        
                        # Suche nach Methodenkommentaren
                        method_comment = ""
                        method_comment_match = re.search(r"/\*\*(.*?)\*/", class_content[:method_match.start()], re.DOTALL)
                        if method_comment_match:
                            method_comment = method_comment_match.group(1).strip()
                        
                        # Identifiziere Features basierend auf Methodennamen und Kommentaren
                        if "Zeitmanipulation" in method_comment or "TimeManipulation" in method_name:
                            features.append({
                                "name": "Zeitmanipulation",
                                "description": extract_description(method_comment),
                                "class": class_name,
                                "method": method_name,
                                "file": os.path.relpath(cs_file, PROJECT_ROOT)
                            })
                        elif "Kampfsystem" in method_comment or "CombatSystem" in method_name or "Timeline" in method_name:
                            features.append({
                                "name": "Timeline-basiertes Kampfsystem",
                                "description": extract_description(method_comment),
                                "class": class_name,
                                "method": method_name,
                                "file": os.path.relpath(cs_file, PROJECT_ROOT)
                            })
                        elif "Deckbuilding" in method_comment or "DeckBuilding" in method_name:
                            features.append({
                                "name": "Deckbuilding",
                                "description": extract_description(method_comment),
                                "class": class_name,
                                "method": method_name,
                                "file": os.path.relpath(cs_file, PROJECT_ROOT)
                            })
        except Exception as e:
            log(f"Fehler beim Scannen von {cs_file}: {e}")
    
    return features, classes

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

def extract_description(comment):
    """Extrahiert eine Beschreibung aus einem Kommentar."""
    if not comment:
        return ""
    
    # Entferne Sternchen und führende Leerzeichen
    lines = comment.split("\n")
    cleaned_lines = [line.strip().lstrip("* ") for line in lines]
    
    # Suche nach @description oder nehme den ersten Absatz
    description = ""
    for i, line in enumerate(cleaned_lines):
        if line.startswith("@description"):
            description = line[12:].strip()
            break
        elif not line and i > 0 and description:
            break
        elif line and not line.startswith("@"):
            description += " " + line if description else line
    
    return description.strip()

def update_readme_features(features, classes):
    """Aktualisiert die Features und Klassen in der README.md."""
    readme_content = read_readme()
    if not readme_content:
        return False
    
    # Gruppiere Features nach Namen
    grouped_features = {}
    for feature in features:
        if feature["name"] not in grouped_features:
            grouped_features[feature["name"]] = feature
    
    # Aktualisiere Features-Abschnitt
    features_section_match = re.search(f"{FEATURES_SECTION_START}(.*?)(##|$)", readme_content, re.DOTALL)
    if features_section_match:
        current_features_section = features_section_match.group(1)
        new_features_section = "\n\n"
        
        # Behalte bestehende Features bei
        feature_pattern = r"- \*\*(.*?)\*\*:(.*?)(?=\n- \*\*|\n\n|$)"
        existing_features = re.finditer(feature_pattern, current_features_section, re.DOTALL)
        existing_feature_names = set()
        
        for match in existing_features:
            feature_name = match.group(1).strip()
            feature_description = match.group(2).strip()
            existing_feature_names.add(feature_name)
            
            # Aktualisiere Beschreibung, wenn ein neues Feature gefunden wurde
            if feature_name in grouped_features and grouped_features[feature_name]["description"]:
                feature_description = grouped_features[feature_name]["description"]
            
            new_features_section += f"- **{feature_name}**: {feature_description}\n"
        
        # Füge neue Features hinzu
        for name, feature in grouped_features.items():
            if name not in existing_feature_names and feature["description"]:
                new_features_section += f"- **{name}**: {feature['description']}\n"
        
        # Ersetze den alten Abschnitt
        updated_readme = readme_content.replace(
            features_section_match.group(0),
            f"{FEATURES_SECTION_START}{new_features_section}\n\n##"
        )
        
        # Aktualisiere Klassen-Abschnitt
        classes_section_match = re.search(f"{CLASSES_SECTION_START}(.*?)(##|$)", updated_readme, re.DOTALL)
        if classes_section_match:
            current_classes_section = classes_section_match.group(1)
            new_classes_section = "\n\n"
            
            # Gruppiere Klassen nach Typ
            grouped_classes = {"Chronomant": [], "Zeitwächter": [], "Schattenschreiter": []}
            for cls in classes:
                if cls["type"] in grouped_classes:
                    grouped_classes[cls["type"]].append(cls)
            
            # Behalte bestehende Klassenbeschreibungen bei
            class_pattern = r"- \*\*(.*?)\*\*:(.*?)(?=\n- \*\*|\n\n|$)"
            existing_classes = re.finditer(class_pattern, current_classes_section, re.DOTALL)
            existing_class_types = {}
            
            for match in existing_classes:
                class_type = match.group(1).strip()
                class_description = match.group(2).strip()
                existing_class_types[class_type] = class_description
            
            # Aktualisiere Klassenbeschreibungen
            for class_type in ["Chronomant", "Zeitwächter", "Schattenschreiter"]:
                description = existing_class_types.get(class_type, "")
                
                # Aktualisiere Beschreibung, wenn neue Klassen gefunden wurden
                if class_type in grouped_classes and grouped_classes[class_type]:
                    descriptions = [cls["description"] for cls in grouped_classes[class_type] if cls["description"]]
                    if descriptions:
                        description = descriptions[0]
                
                new_classes_section += f"- **{class_type}**: {description}\n"
            
            # Ersetze den alten Abschnitt
            updated_readme = updated_readme.replace(
                classes_section_match.group(0),
                f"{CLASSES_SECTION_START}{new_classes_section}\n\n##"
            )
        
        return write_readme(updated_readme)
    
    return False

def main():
    """Hauptfunktion."""
    log("Starte README-Feature-Aktualisierung...")
    
    # Lade Cache
    cache = load_features_cache()
    
    # Scanne nach Features und Klassen
    features, classes = scan_for_features()
    log(f"{len(features)} Features und {len(classes)} Klassen gefunden.")
    
    # Aktualisiere README
    if update_readme_features(features, classes):
        # Aktualisiere Cache
        cache["features"] = features
        cache["classes"] = classes
        save_features_cache(cache)
        log("README.md erfolgreich aktualisiert.")
    else:
        log("Keine Änderungen an README.md vorgenommen.")

if __name__ == "__main__":
    main()
