#!/usr/bin/env python3
"""RC22: CBA wait payload and native stethoscope callback-shape regressions."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

def test_chest_preflight_condition_unpacks_full_cba_payload():
    s = read("addons/core/overrides/fnc_treatment.sqf")
    start = s.index("// CBA passes the ENTIRE _args payload")
    block = s[start:start + 1100]
    assert 'params ["_m","_p","_args","_tok","_leaseId","_classKey","_launch"];' in block
    assert 'getVariable ["ACME_chestAccessPreflightToken",""]) != _tok' in block

def test_removal_provider_wait_unwraps_nested_call_args():
    s = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
    start = s.index("// _this is [_args,_beginPatient]")
    block = s[start:start + 700]
    assert 'params ["_callArgs","_begin"];' in block
    assert '_callArgs param [1,objNull,[objNull]]' in block
    assert '_callArgs param [8,"",[""]]' in block
    assert 'params ["_m","_token"];' not in block

def test_restore_provider_wait_unwraps_nested_call_args():
    s = read("addons/acm_extended/functions/fn_chestAccessVestRestore.sqf")
    start = s.index("// _this is [_args,_beginRestore]")
    block = s[start:start + 700]
    assert 'params ["_callArgs","_begin"];' in block
    assert '_callArgs param [1,objNull,[objNull]]' in block
    assert '_callArgs param [9,"",[""]]' in block
    assert 'params ["_m","_token"];' not in block

def test_native_stethoscope_callback_accepts_classname_slot():
    s = read("addons/breathing/functions/fnc_useStethoscope.sqf")
    assert 'params ["_medic", "_patient", ["_bodyPart", "Body"]];' in s
    assert '["_entryReady", false, [false]]' not in s
    assert 'private _slot3 = _this param [3, false];' in s
    assert 'if (_slot3 isEqualType true)' in s
    assert 'private _slot4 = _this param [4, false];' in s

def test_rc19_stethoscope_lifetime_still_present():
    s = read("addons/acm_extended/functions/fn_beginStethoscopeAction.sqf")
    assert 'ACM_core_ContinuousAction_Session", [_patient, _epoch]' in s
    assert "_args call _onStart;" in s
    assert 'findDisplay _dialogID' in s

if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            fn()
    print("PASS rc22: chest wait payload + steth callback-shape regressions")
