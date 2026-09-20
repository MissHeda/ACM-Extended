from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "functions"
CIRC = ROOT.parent / "circulation" / "functions"


def acme(name: str) -> str:
    return (FUN / name).read_text(encoding="utf-8")


def circ(name: str) -> str:
    return (CIRC / name).read_text(encoding="utf-8")


def test_native_drag_uses_vial_session_limit_in_same_frame():
    src = circ("fnc_Syringe_Draw.sqf")
    moving = src.split("if (GVAR(SyringeDraw_Moving)) then {", 1)[1]
    assert 'if !(isNil "ACME_fnc_vialSession")' in moving
    assert '["limit", _acmeMed, GVAR(SyringeDraw_DrawnAmount), _acmeDisplay] call ACME_fnc_vialSession' in moving
    assert '_effectiveMax = (_effectiveMax max 0) min _size;' in moving
    assert moving.index('ACME_fnc_vialSession') < moving.index('private _bottomLimit = linearConversion')
    assert '_amountDrawn = (_amountDrawn max 0) min _effectiveMax;' in moving
    assert 'GVAR(SyringeDraw_MaxDose) = _effectiveMax;' in moving


def test_acme_ui_no_longer_fights_live_drag_loop():
    src = acme("fn_skUiTick.sqf")
    clamp = src.split('// The native ACM drag loop now consumes this hard limit', 1)[1].split('// Inventory can change', 1)[0]
    assert 'ACME_fnc_syringeDrawSetAmount' in clamp
    assert 'setMousePosition' not in clamp
    assert 'SyringeDraw_Moving' not in clamp
    assert '_drawnNow > _hardMax' in clamp


def test_forced_amount_correction_keeps_numeric_hitbox_and_art_together():
    src = acme("fn_syringeDrawSetAmount.sqf")
    assert 'ACM_circulation_SyringeDraw_DrawnAmount' in src
    assert '_display displayCtrl 84009' in src
    assert 'ACM_circulation_SyringeDraw_Ctrl_PlungerVisual' in src
    assert '_y - _adjust' in src
    assert 'ACM_circulation_SyringeDraw_Moving' in src
    assert 'class syringeDrawSetAmount {};' in (ROOT / "config.cpp").read_text(encoding="utf-8")


def test_infusion_commit_requires_settled_plunger_and_rechecks_real_stock():
    stock = acme("fn_infusionDrawStock.sqf")
    inject = acme("fn_injectIntoBag.sqf")
    assert 'private _moving = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false];' in stock
    assert '!_moving' in stock
    assert 'if (missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false]) exitWith {};' in inject
    assert 'ACME_fnc_infusionVialVolume' in inject
    assert '_sessionMax min _stockMax min _size' in inject
    assert 'Confirm the dose and inject again.' in inject


def test_successful_bag_injection_resets_plunger_and_native_selection_atomically():
    src = acme("fn_injectIntoBag.sqf")
    assert '[0, _display, true] call ACME_fnc_syringeDrawSetAmount;' in src
    assert 'ACM_circulation_SyringeDraw_MaxDose = 0;' in src
    assert 'ACM_circulation_SyringeDraw_MedicationSelected_Index = -1;' in src
    assert 'ACM_circulation_SyringeDraw_Medication = "";' in src
    assert 'ACM_circulation_SyringeDraw_MedicationSelected = false;' in src


def test_stock_refresh_never_changes_amount_without_moving_artwork_too():
    src = acme("fn_infusionDrawStock.sqf")
    assert '[_hardMax, _display, false] call ACME_fnc_syringeDrawSetAmount;' in src
    # Regression: a variable-only clamp causes the visible plunger to remain at the old volume.
    block = src.split('if (_drawn > _hardMax + 0.0001) then {', 1)[1].split('};', 1)[0]
    assert 'SyringeDraw_DrawnAmount =' not in block
