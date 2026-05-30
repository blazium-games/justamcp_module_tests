import re
from pathlib import Path

cpp = Path(__file__).resolve().parents[2] / "blazium" / "modules" / "justamcp" / "tools" / "justamcp_tool_executor.cpp"
text = cpp.read_text(encoding="utf-8")
schemas = re.findall(r'add_schema\("([^"]+)"', text)
dispatched = set(re.findall(r'internal_name == "([^"]+)"', text))
missing = [s for s in schemas if s not in dispatched]
print(f"schemas={len(schemas)} dispatched={len(dispatched)} missing={len(missing)}")
for name in missing:
    print(name)
