import json
import re
from pathlib import Path

CPP = Path(__file__).resolve().parents[2] / "blazium" / "modules" / "justamcp" / "tools" / "justamcp_tool_executor.cpp"
OUT = Path(__file__).resolve().parents[1] / "tests" / "mcp_tool_manifest.json"

text = CPP.read_text(encoding="utf-8")
cat = ""
manifest = {}
for line in text.splitlines():
    m = re.search(r'current_category = "([^"]+)"', line)
    if m:
        cat = m.group(1)
    m = re.search(r'add_schema\("([^"]+)"', line)
    if m:
        name = m.group(1)
        key = cat or "meta"
        manifest.setdefault(key, []).append(name)

total = sum(len(v) for v in manifest.values())
print(f"categories={len(manifest)} tools={total}")
OUT.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
