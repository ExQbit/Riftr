# Placeholder for check-docs.py script
import os
import re

docs_dir = os.path.join(os.getcwd(), "docs")
pattern = re.compile(r"(ZK-[A-Z0-9\-]+)")

def extract_id_from_content(path):
    try:
        with open(path, "r", encoding="utf-8") as file:
            for line in file:
                match = pattern.search(line)
                if match:
                    return match.group(1)
    except Exception as e:
        return None
    return None

def check_files():
    print("📂 Überprüfe Markdown-Dateien in 'docs/'...\n")
    for filename in sorted(os.listdir(docs_dir)):
        if not filename.endswith(".md"):
            continue

        path = os.path.join(docs_dir, filename)
        expected_id = extract_id_from_content(path)
        if not expected_id:
            print(f"❌ Kein ZK-Code in Inhalt: {filename}")
            continue

        expected_name = f"{expected_id}.md"
        if filename != expected_name:
            print(f"⚠️  Abweichung: {filename} → erwartet: {expected_name}")
        else:
            print(f"✅ OK: {filename}")

if __name__ == "__main__":
    check_files()
