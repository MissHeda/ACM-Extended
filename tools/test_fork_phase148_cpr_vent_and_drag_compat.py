#!/usr/bin/env python3
"""Phase 148: vent provider churn must not impersonate CPR transitions, and carry-drop repair must be verifiable."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

cpr = (ROOT / "addons/circulation/functions/fnc_beginCPR.sqf").read_text(encoding="utf-8", errors="ignore")
vent = (ROOT / "addons/acm_extended/functions/fn_ventDriveTick.sqf").read_text(encoding="utf-8", errors="ignore")
compat = (ROOT / "addons/acm_extended/functions/fn_compatCheck.sqf").read_text(encoding="utf-8", errors="ignore")
carry = (ROOT / "addons/core/overrides/fnc_dropObject_carry.sqf").read_text(encoding="utf-8", errors="ignore")

# The ventilator may legitimately move ACM_breathing_BVM_provider in and out while CPR continues.
assert '[["bvmProvider", _patient]' in vent
assert '[["bvmProvider", objNull]' in vent

# CPR notifications/animation restarts are keyed to a CPR transition, not to BVM-provider churn.
assert "private _cprChanged = _cprNow isNotEqualTo _cprWasActive;" in cpr
assert "private _bvmChanged = _bvmNow isNotEqualTo _bvmWasActive;" in cpr
assert 'if (_cprChanged) then {\n                    [LLSTRING(CPR_Continued)' in cpr
assert 'if (_cprChanged && {_notInVehicle}) then {[_medic, _epoch] call _fnc_doCPRAnimation;};' in cpr

# Reconciliation validates an executed behavior string that survives compilation.
assert '"ACM_LyingState"' in carry
assert '["ace_dragging_fnc_dropObject_carry", "ACM_LyingState"]' in compat
assert 'find "acm_lyingstate"' in compat
assert '["ace_dragging_fnc_dropObject_carry", "B106:ace321CarryDrop"]' not in compat

print("PASS phase148: CPR/vent transition isolation and carry-drop compatibility repair")
