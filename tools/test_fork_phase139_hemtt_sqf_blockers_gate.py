#!/usr/bin/env python3
"""Phase 139: close first HEMTT SQF compiler blockers without external ACE source includes."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(rel):
    return (ROOT / rel).read_text(encoding="utf-8")

holes = text("addons/acm_extended/functions/fn_chestSealGenHoles.sqf")
mouse = text("addons/acm_extended/functions/fn_chestSealMouseDown.sqf")
assert "_distance > 0.96 && {_distance > 0}" not in holes
assert "_distance > 0.96 && {_distance > 0}" not in mouse
assert "if (_distance > 0.96) then" in holes
assert "if (_distance > 0.96) then" in mouse

addlog = text("addons/core/overrides/fnc_addToLog.sqf")
display = text("addons/core/overrides/fnc_displayTextStructured.sqf")
progress = text("addons/core/overrides/fnc_progressBar.sqf")

for body in (addlog, display, progress):
    assert '#include "..\\script_component.hpp"' in body
    assert '#include "\\z\\ace\\addons\\common\\script_component.hpp"' not in body
    assert '#include "\\z\\ace\\addons\\medical_treatment\\script_component.hpp"' not in body

assert "QACEGVAR(medical_treatment,addToLog)" in addlog
assert 'format ["ace_medical_log_%1", _logType]' in addlog
assert '"ace_medical_allLogs"' in addlog
assert "ACEGVAR(common,displayTextColor)" in display
assert "ACEGVAR(common,displayTextFontColor)" in display
assert "QACEGVAR(common,ProgressBar_Dialog)" in progress
assert "ACEFUNC(common,canInteractWith)" in progress
assert 'localize "STR_ACE_Common_TimeLeft"' in progress

print("PASS phase139: HEMTT SQF blockers closed and ACE override includes are self-contained")
