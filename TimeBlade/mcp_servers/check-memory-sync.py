import os
import json

DOCS_DIR = "./docs"
MEMORY_FILE = "./.windsurf.memory.json"

def main():
    if not os.path.exists(MEMORY_FILE):
        print(f"❌ Keine Memory-Datei gefunden unter {MEMORY_FILE}")
        return

    with open(MEMORY_FILE, "r") as f:
        memory_data = json.load(f)

    registered_paths = set(entry["path"] for entry in memory_data.get("entries", []))
    all_md_files = set(
        os.path.join(DOCS_DIR, f)
        for f in os.listdir(DOCS_DIR)
        if f.endswith(".md")
    )

    missing_entries = all_md_files - registered_paths

    if not missing_entries:
        print("✅ Alle Markdown-Dateien im docs/-Ordner sind im Memory eingetragen.")
    else:
        print("🚨 Nicht im Memory eingetragen:")
        for f in sorted(missing_entries):
            print("  -", f)

if __name__ == "__main__":
    main()