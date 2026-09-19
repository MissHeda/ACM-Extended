from pathlib import Path

ADDON = Path(__file__).resolve().parents[1]
ROOT = ADDON.parent


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="strict")


def test_seizure_gestures_are_isolated_and_135x():
    s = read(ADDON / "config.cpp")
    for n in range(3, 7):
        assert f'ACME_SeizureSpasm{n}[] = {{"ACME_SeizureSpasm{n}", "Gesture"}};' in s
        assert f'class ACME_SeizureSpasm{n}: GestureSpasm{n} {{ speed = 1.35; }};' in s


def test_motion_uses_gesture_done_not_old_jitter_driver():
    s = read(ADDON / "functions" / "fn_seizureMotion.sqf")
    assert 'addEventHandler ["GestureDone"' in s
    assert "ACME_fnc_seizureGestureAdvance" in s
    assert "ACME_seizure_jerkHz" not in s
    assert "ACME_seizure_yawAmp" not in s
    assert "ACME_seizure_yawChaos" not in s
    assert "addCamShake" not in s
    assert "ACME_fnc_forceRagdoll" not in s
    assert "private _tremor" not in s
    assert "private _jitter" not in s


def test_only_selected_spasm_variants_cycle_without_immediate_repeat():
    s = read(ADDON / "functions" / "fn_seizureGestureAdvance.sqf")
    for n in range(3, 7):
        assert f'"ACME_SeizureSpasm{n}"' in s
    assert '"ACME_SeizureSpasm0"' not in s
    assert '"ACME_SeizureSpasm1"' not in s
    assert '"ACME_SeizureSpasm2"' not in s
    assert "private _pool = _gestures - [_last];" in s
    assert "selectRandom _pool" in s


def test_sarin_joins_shared_seizure_state_machine():
    effect = read(ROOT / "cbrn" / "functions" / "fnc_effectSarin.sqf")
    tox = read(ADDON / "functions" / "fn_lidoToxTick.sqf")
    reset = read(ROOT / "cbrn" / "functions" / "fnc_resetVariables.sqf")
    assert 'ACME_sarinSeizureCause' in effect
    assert "addCamShake" not in effect
    assert 'private _sarinCause = _patient getVariable ["ACME_sarinSeizureCause", false];' in tox
    assert '|| _sarinCause' in tox
    assert '|| _sarinCause ||' in tox
    assert '_patient setVariable ["ACME_sarinSeizureCause", false, true];' in reset


def test_full_heal_clears_new_gesture_state():
    s = read(ADDON / "functions" / "fn_clearAllAilments.sqf")
    for name in [
        "ACME_sarinSeizureCause",
        "ACME_seizure_motionActive",
        "ACME_seizure_motionGestureEH",
        "ACME_seizure_motionCurrentGesture",
        "ACME_seizure_motionRetryPending",
        "ACME_seizure_motionAdvancePending",
    ]:
        assert f'"{name}"' in s


def test_old_visual_tuning_is_explicitly_inert():
    cfg = read(ADDON / "functions" / "fn_initDrugPhysiologyConfig.sqf")
    motion = read(ADDON / "functions" / "fn_seizureMotion.sqf")
    assert "Legacy visual tuning names are retained as inert compatibility values" in cfg
    assert "ACME_sarin_seizureThreshold = 10;" in cfg
    for name in [
        "ACME_seizure_jerkHz",
        "ACME_seizure_yawAmp",
        "ACME_seizure_yawChaos",
        "ACME_seizure_burstMin",
        "ACME_seizure_burstMax",
        "ACME_seizure_pauseMin",
        "ACME_seizure_pauseMax",
        "ACME_seizure_ragdollChance",
        "ACME_seizure_ragdollDur",
        "ACME_seizure_camShake",
    ]:
        assert name not in motion
