"""Source integration checks. Arma physics and gestures still require an in-game test."""
from pathlib import Path
import re

ADDON = Path(__file__).resolve().parents[1]
ADDONS = ADDON.parent

def source(rel):
    return (ADDONS / rel).read_text(encoding="utf-8-sig")

def fn(name):
    return source(f"acm_extended/functions/fn_{name}.sqf")

def test_debug_seizure_bypasses_physical_treatment_and_keeps_gates():
    treatment = source("core/overrides/fnc_treatment.sqf")
    direct = treatment.split('if (_classname == "ACME_DebugInduceSeizure") exitWith {', 1)[1].split("// Direct Pressure", 1)[0]
    assert '(toLowerANSI _bodyPart) == "head"' in direct
    assert "ACME_fnc_debugEnabled" in direct
    assert "ace_medical_treatment_fnc_canTreat" in direct
    assert '[_patient, "debugSeizure", [_medic, _patient]] call ACME_fnc_ownerDispatch;' in direct
    assert "treatmentNative" not in direct
    assert "medicAnimationPrep" not in direct
    assert "progressBar" not in direct
    assert treatment.index('if (_classname == "ACME_DebugInduceSeizure")') < treatment.index("ACME_fnc_procedureActionAllowed")

def test_seizure_state_precedes_collapse_and_prevents_spontaneous_wake():
    debug = fn("debugInduceSeizure")
    assert debug.index('"ACME_lido_seizureState","active"') < debug.index("call ACME_fnc_seizureCollapse")
    assert 'ACME_lido_seizureState' in source("core/functions/fnc_isForcedUnconscious.sqf")
    assert '"active"' in source("core/functions/fnc_isForcedUnconscious.sqf")

def test_generic_settle_yields_to_real_seizure_and_drag_state():
    settle = fn("treatmentPatientSettle")
    assert '"ACME_lido_seizureState", ""' in settle
    assert '"ACME_dragHandle_active", false' in settle
    assert settle.index('"ACME_dragHandle_active"') < settle.index("ACME_fnc_patientAnimRequest")
    assert '"ACME_seizure_active"' not in settle

def test_seizure_waits_for_physics_and_transport_to_release_body():
    advance = fn("seizureGestureAdvance")
    retry = advance[:advance.index("private _gestures")]
    assert "!isAwake _patient" in retry
    assert "ACME_dragHandle_active" in retry
    assert "ace_common_fnc_isBeingDragged" in retry
    assert "ace_common_fnc_isBeingCarried" in retry
    assert "CBA_fnc_waitAndExecute" in retry
    assert "ACME_seizure_motionActive" in retry

def test_ragdoll_uses_native_impulse_without_pose_or_consciousness_toggle():
    ragdoll = fn("forceRagdoll")
    assert "_patient addForce [[0,0,-1],_point,true];" in ragdoll
    for forbidden in ("_patient setUnconscious false", '"AmovPpneMstpSnonWnonDnon"',
                      "CBA_fnc_execNextFrame", "_patient setPos"):
        assert forbidden not in ragdoll
    assert "!local _patient" in ragdoll and "objectParent _patient" in ragdoll
    collapse = fn("seizureCollapse")
    assert "ACME_fnc_forceRagdoll" not in collapse
    assert "if (!_wasUncon" in collapse


def test_unconscious_pose_cannot_pin_active_drag_ragdoll():
    settle = source("core/overrides/fnc_applyAnimAfterRagdoll.sqf")
    assert 'if (_unit getVariable ["ACME_dragHandle_active", false]) exitWith {};' in settle
    assert settle.index('"ACME_dragHandle_active"') < settle.index('_unit switchMove')
    keeper = fn("megacodeStanceLock")
    assert "ACME_dragHandle_active" in keeper
    assert "ACME_lido_seizureState" in keeper
    spawn = fn("megacodeSpawn")
    assert spawn.index('disableAI "ALL"') < spawn.index('enableAI "ANIM"')

def test_drag_impulse_is_not_blocked_waiting_for_ragdoll():
    tick = fn("dragHandleOwnerTick")
    assert "if (isAwake _patient) exitWith" not in tick
    assert "ACME_fnc_forceRagdoll" in tick
    assert "_patient addForce [_impulse,_handleModel,true];" in tick
    assert "_patient attachTo" not in tick
    assert "_patient setPos" not in tick


def test_stretch_release_has_bounded_grace_and_cleanup():
    tick = fn("dragHandleOwnerTick")
    assert '(_distance > _releaseDist) exitWith' not in tick
    assert "_releaseDist + 3" in tick
    assert "(CBA_missionTime - _overSince) > 0.75" in tick
    for name in ("startedAt", "overstretchSince"):
        assert f'ACME_dragHandle_{name}' in fn("dragHandleStartOwner")
        assert f'setVariable ["ACME_dragHandle_{name}",nil]' in fn("dragHandleStopOwner")

def test_semifowler_rejects_upright_even_with_stale_lying_flag():
    can = fn("headElevateCanStart")
    assert 'if (_stance in ["STAND", "CROUCH"]) exitWith {false};' in can
    assert can.index('["STAND", "CROUCH"]') < can.index('private _down')
    assert 'ACM_core_Lying_State' in can
    assert '_stance == "PRONE"' in can
    assert 'ACME_dragHandle_active' in can

def test_semifowler_is_revalidated_before_side_effects_and_menu_grouping():
    start = fn("headElevateStart")
    guard = start.index('if !([_patient, _medic] call ACME_fnc_headElevateCanStart) exitWith {};')
    assert guard < start.index('call ACME_fnc_chestAccessVestRestore')
    assert guard < start.index('setVariable ["ACME_headElevated", true')
    renderer = source("gui/overrides/fnc_updateActions.sqf")
    assert "!= 'acme_elevatehead'" in renderer
    assert '[_target, ACE_player] call ACME_fnc_headElevateCanStart' in renderer

def test_ketamine_water_amplitude_reduced_at_every_tier():
    tick = fn("visualFxTick")
    previous = [
        [0, .0066, .0081, .0098],
        [0, .0049, .0061, .0072],
        [0, .0041, .0051, .0062],
        [0, .0030, .0038, .0046],
    ]
    for number, original in enumerate(previous, 1):
        match = re.search(rf"private _a{number} = \[_k,([^\]]+)\] call _tierLerp;", tick)
        assert match
        actual = [float(value) for value in match.group(1).split(",")]
        assert all(abs(a - b * .75) < 1e-10 for a, b in zip(actual, original))
    assert '[_k,1.24,1.42,1.50,1.58]' in tick
    assert '_ketWetDebugHandle ppEffectCommit 0;' in tick
