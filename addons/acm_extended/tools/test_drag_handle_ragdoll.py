from pathlib import Path

ADDON = Path(__file__).resolve().parents[1]
FUN = ADDON / "functions"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="strict")


def test_drag_handle_functions_are_registered_and_started():
    config = read(ADDON / "config.cpp")
    post = read(FUN / "fn_postInit.sqf")
    for name in [
        "initDragHandleRuntime",
        "dragHandleWeight",
        "dragHandleCanStart",
        "dragHandleStart",
        "dragHandleStartOwner",
        "dragHandleOwnerTick",
        "dragHandleStartMedic",
        "dragHandleStop",
        "dragHandleStopOwner",
        "dragHandleStopMedic",
    ]:
        assert f"class {name} {{}};" in config
    assert "call ACME_fnc_initDragHandleRuntime;" in post


def test_drag_handle_uses_owner_authoritative_addforce_not_attachto():
    tick = read(FUN / "fn_dragHandleOwnerTick.sqf")
    start = read(FUN / "fn_dragHandleStartOwner.sqf")
    assert "_patient addForce [_impulse,_handleModel,false];" in tick
    assert "diag_deltaTime" in tick
    assert "ACME_dragHandle_springAccelPerM" in tick
    assert "ACME_dragHandle_damping" in tick
    assert "ACME_dragHandle_maxAccel" in tick
    assert "ACME_fnc_forceRagdoll" in start
    assert "isAwake _patient" in tick
    assert "private _bodySpeed" not in tick
    assert "_patient attachTo" not in tick
    assert "_patient attachTo" not in start


def test_weight_changes_both_patient_pull_and_dragger_speed():
    weight = read(FUN / "fn_dragHandleWeight.sqf")
    tick = read(FUN / "fn_dragHandleOwnerTick.sqf")
    medic = read(FUN / "fn_dragHandleStartMedic.sqf")
    assert "loadAbs _patient" in weight
    assert "getMass _patient" in weight
    assert "linearConversion [350,950,_weight,1,0.58,true]" in tick
    assert "ACME_dragHandle_lightAnimCoef" in medic
    assert "ACME_dragHandle_heavyAnimCoef" in medic
    assert "linearConversion [350,950,_weight,_lightCoef,_heavyCoef,true]" in medic


def test_dragger_is_sprint_blocked_and_capped_near_slow_jog():
    runtime = read(FUN / "fn_initDragHandleRuntime.sqf")
    medic = read(FUN / "fn_dragHandleStartMedic.sqf")
    stop = read(FUN / "fn_dragHandleStopMedic.sqf")
    assert "ACME_dragHandle_lightAnimCoef = 0.62;" in runtime
    assert "ACME_dragHandle_heavyAnimCoef = 0.48;" in runtime
    assert '[_medic,"blockSprint","ACME_dragHandle",true]' in medic
    assert "_medic setAnimSpeedCoef _desired;" in medic
    assert "linearConversion [0,1,_tension,1,0.72,true]" in medic
    assert '[_medic,"blockSprint","ACME_dragHandle",false]' in stop
    assert "_medic setAnimSpeedCoef _saved;" in stop


def test_advanced_fatigue_receives_weight_and_tension_load():
    runtime = read(FUN / "fn_initDragHandleRuntime.sqf")
    medic = read(FUN / "fn_dragHandleStartMedic.sqf")
    stop = read(FUN / "fn_dragHandleStopMedic.sqf")
    assert "ace_advanced_fatigue_fnc_addDutyFactor" in runtime
    assert "linearConversion [350,950,_w,1.15,1.70,true]" in runtime
    assert "linearConversion [0,1,_t,1,1.35,true]" in runtime
    assert 'ace_advanced_fatigue_setAnimExclusions pushBackUnique "ACME_dragHandle"' in medic
    assert 'ace_advanced_fatigue_setAnimExclusions - ["ACME_dragHandle"]' in stop


def test_transaction_yields_to_conflicting_transport_and_locality():
    can = read(FUN / "fn_dragHandleCanStart.sqf")
    tick = read(FUN / "fn_dragHandleOwnerTick.sqf")
    dispatch = read(FUN / "fn_ownerDispatch.sqf")
    assert "ace_common_fnc_isBeingDragged" in can
    assert "ace_common_fnc_isBeingCarried" in can
    assert '"ace_dragging_isDragging"' in can
    assert '"ace_dragging_isCarrying"' in can
    assert '"dragHandleStart"' in dispatch
    assert '"dragHandleStop"' in dispatch
    assert '"locality"' in tick
    assert '"vehicle"' in tick
    assert '"overstretch"' in tick


def test_drag_handle_and_seizure_visuals_do_not_fight():
    seizure = read(FUN / "fn_seizureMotion.sqf")
    start = read(FUN / "fn_dragHandleStartOwner.sqf")
    assert 'ACME_dragHandle_active' in seizure
    assert '[_patient,false] call ACME_fnc_seizureMotion;' in start


def test_hard_reset_and_stop_restore_owned_state():
    clear = read(FUN / "fn_clearAllAilments.sqf")
    start = read(FUN / "fn_dragHandleStartOwner.sqf")
    stop = read(FUN / "fn_dragHandleStopOwner.sqf")
    assert 'ACME_fnc_dragHandleStopOwner' in clear
    assert 'ACME_dragHandle_oldAceFlags' in start
    assert 'setVariable ["ace_dragging_canDrag",false,true]' in start
    assert 'setVariable ["ace_dragging_canCarry",false,true]' in start
    assert 'setVariable ["ace_dragging_canDrag",_oldFlags param [0,true],true]' in stop
    assert 'setVariable ["ace_dragging_canCarry",_oldFlags param [1,true],true]' in stop


def test_visual_harness_is_non_authoritative_and_jip_reconstructed():
    runtime = read(FUN / "fn_initDragHandleRuntime.sqf")
    assert 'addMissionEventHandler ["Draw3D"' in runtime
    assert "Eight-segment waist loop" in runtime
    assert "drawLine3D [_rear,_drop,_col];" in runtime
    assert "drawLine3D [_drop,_handle,_col];" in runtime
    assert "forEach allUnits" in runtime
    assert "ropeCreate" not in runtime
