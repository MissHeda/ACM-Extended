from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def txt(rel):
    return (ROOT / rel).read_text(encoding='utf-8', errors='replace')


def test_examine_is_one_click_for_common_assessments():
    src = txt('functions/fn_menuExamineGroups.sqf')
    groups = json.loads(src[src.index('\n[') + 1:])
    assert [g[1] for g in groups] == ['Monitoring Equipment', 'Injuries & IV Sites', 'Debug']
    grouped = {name for _, _, names, _ in groups for name in names}
    for cls in [
        'checkresponse', 'slapawake', 'acme_assesspupils',
        'checkpulse', 'checkbloodpressure', 'checkcapillaryrefill',
        'acme_inspectchest', 'usestethoscope',
        'acme_feelskin', 'acme_checktemperature', 'acme_readcoretemp',
        'acme_elevatehead', 'acme_lowerhead',
    ]:
        assert cls not in grouped, cls


def test_elevated_death_uses_normal_patient_release_animation():
    death = txt('functions/fn_headElevDeathRelease.sqf')
    stop = txt('functions/fn_headElevateStop.sqf')
    release = '[_patient, "ACME_HeadElevPatientRelease", 2] call ACME_fnc_doAnim;'
    assert release in stop
    assert release in death
    assert '[_patient, false] call ACME_fnc_headElevCollision;' in death
    assert '[_p, true] call ACME_fnc_headElevCollision;' in death
    # Death cleanup must never start a provider animation.
    assert 'headElevMedicSeq' not in death


def test_head_position_provider_releases_stance_lock_after_crouched_finish():
    seq = txt('functions/fn_headElevMedicSeq.sqf')
    cancel = txt('functions/fn_headElevateCancelSeq.sqf')
    assert '[_u, _rest, 2] call ACME_fnc_doAnim;' in seq
    assert '_unit setUnitPos "AUTO";' in seq
    assert '_m setUnitPos "AUTO";' in cancel
    assert 'ACME_headElev_seqActive' in seq


def test_cpr_and_bvm_are_native_acm_owned():
    cfg = txt('config.cpp')
    treatment = txt('overrides/fn_treatment.sqf')

    # No compile-time replacement of the ACM continuous-action functions.
    assert 'class beginCPR { file = "\\acm_extended\\overrides\\fn_beginCPR.sqf"; };' not in cfg
    assert 'class canUseBVM { file = "\\acm_extended\\overrides\\fn_canUseBVM.sqf"; };' not in cfg
    assert 'class useBVM { file = "\\acm_extended\\overrides\\fn_useBVM.sqf"; };' not in cfg
    assert not (ROOT / 'overrides/fn_beginCPR.sqf').exists()
    assert not (ROOT / 'overrides/fn_canUseBVM.sqf').exists()
    assert not (ROOT / 'overrides/fn_useBVM.sqf').exists()

    # Do not restate/loosen ACM's CPR treatment condition.
    assert 'class CPR {' not in cfg
    assert 'One CPR provider and one BVM provider may work simultaneously' not in cfg

    # Generic ACME provider preflight must bypass native continuous actions before any setUnitPos/holster logic.
    guard = treatment.index('private _nativeContinuousClass')
    preflight = treatment.index('private _bypass')
    assert guard < preflight
    for cls in ['"cpr"', '"usebvm"', '"usebvm_oxygen"', '"usebvm_vehicleoxygen"', '"usebvm_portableoxygen"']:
        assert cls in treatment[guard:preflight]
    assert '_this call ACME_native_fnc_treatment' in treatment[guard:preflight]


def test_bvm_visual_cue_is_read_only_native_observer():
    tick = txt('functions/fn_bvmVentTick.sqf')
    assert 'ACM_breathing_BVM_NextBreath' in tick
    assert 'ACME_bvmVent_lastNativeNextBreath' in tick
    for forbidden in ['ACM_breathing_BVM_Medic", _', 'ACM_breathing_BVM_provider", _', 'setUnitPos', 'ACME_fnc_medicAnimationPrep']:
        assert forbidden not in tick


def test_release_stamp():
    assert 'version = "1.2.0-r0";' in txt('config.cpp')
    assert 'ACME_buildBatch = "B92";' in txt('functions/fn_postInit.sqf')


if __name__ == '__main__':
    tests = [v for k, v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
    for test in tests:
        test()
        print(f'{test.__name__}: PASS')
    print('B92 critical provider/CPR/BVM checks: PASS')
