from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FN = ROOT / "functions"
CONFIG = ROOT / "config.cpp"

def read(path):
    return path.read_text(encoding="utf-8", errors="replace")

def test_lmb_does_not_consume_stethoscope_drag():
    s = read(FN / "fn_stethoscopeInit.sqf")
    assert 'setVariable ["ACME_stethPressed",true]' in s
    tail = s.split('setVariable ["ACME_stethPressed",true]', 1)[1]
    assert "false" in tail[:40]
    assert 'displayAddEventHandler ["MouseMoving"' in s

def test_tick_uses_display_owned_mouse_position():
    s = read(FN / "fn_stethoscopeTick.sqf")
    assert 'getVariable ["ACME_stethMouse",getMousePosition]' in s

def test_scope_display_owns_exact_pose_and_action_generations():
    s = read(FN / "fn_beginStethoscopeAction.sqf")
    assert 'setVariable ["ACME_continuousEpoch", _epoch]' in s
    assert 'setVariable ["ACME_stethMedic", _medic]' in s
    assert 'setVariable ["ACME_stethPoseEpoch", _poseEpoch]' in s

def test_unload_clears_matching_continuous_action_and_pose():
    s = read(FN / "fn_stethoscopeClose.sqf")
    assert 'ACM_core_ContinuousAction_Active = false;' in s
    assert '[_medic,"stethoscope",_poseEpoch] call ACME_fnc_treatmentPoseStop;' in s
    assert 'getAnimSpeedCoef _medic == 0' in s
    assert 'ACME_stethPatientAnimLease' in s

def test_stethoscope_work_state_has_crouch_exit():
    s = read(CONFIG)
    block = s.split("class ACME_StethoscopeWork:", 1)[1].split("// shared restriction set", 1)[0]
    assert 'connectTo[] = {"AmovPknlMstpSnonWnonDnon", 0.2};' in block
    assert "connectTo[] = {};" not in block