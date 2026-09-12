from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "addons" / "acm_extended" / "config.cpp"

text = CONFIG.read_text(encoding="utf-8")
start = text.find("class ACME_Laryngoscopy_Dialog")
assert start >= 0, "ACME_Laryngoscopy_Dialog is missing"
end = text.find("class ACME_", start + 10)
if end < 0:
    end = min(len(text), start + 50000)
block = text[start:end]

needle = "class ControlsBackground {"
pos = block.find(needle)
assert pos >= 0, "Laryngoscopy ControlsBackground is missing"
controls_pos = block.find("class Controls {", pos + len(needle))
assert controls_pos >= 0, "Laryngoscopy Controls class is missing"
pre_controls = block[:controls_pos].rstrip()
assert pre_controls.endswith("};"), (
    "Laryngoscopy ControlsBackground must terminate with `};` before class Controls; "
    "a bare `}` causes HEMTT L-C08"
)

print("PASS phase138: laryngoscopy ControlsBackground closes with a config-class semicolon")
