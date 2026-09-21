#!/usr/bin/env python3
"""RC20: chest-access animation choreography must wrap, never own, clinical action lifetime."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")

def test_patient_release_finishes_supine_and_workspace_state_exists():
    s = read("addons/acm_extended/config.cpp")
    release = s.split("class ACME_HeadElevPatientRelease:", 1)[1].split("};", 1)[0]
    assert 'ConnectTo[] = {"ACM_LyingState", 0.1};' in release
    assert "class ACME_ChestSealWorkspace:" in s

def test_carrier_provider_is_literal_medic4_and_freezes_at_22():
    pose = read("addons/acm_extended/functions/fn_treatmentPoseStart.sqf")
    init = read("addons/acm_extended/functions/fn_initChestSealProcedureRuntime.sqf")
    assert 'case "chestAccess": {"AinvPknlMstpSnonWnonDnon_medic4"};' in pose
    assert '["chestAccess", 2.2]' in init
    assert "ACME_CS_workspaceHoldAt = 0.85" in init
    assert '["chestSealWorkspace", ACME_CS_workspaceHoldAt]' in init

def test_patient_lift_waits_for_real_provider_medic4():
    provider = read("addons/acm_extended/functions/fn_chestAccessVestProvider.sqf")
    acquire = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
    assert 'animationState _m) == "ainvpknlmstpsnonwnondnon_medic4"' in provider
    assert "ACME_chestAccessProviderReady" in provider
    ready = acquire.index("ACME_chestAccessProviderReady")
    grab = acquire.index('"ACME_HeadElevPatientGrab"')
    assert ready < grab
    assert '"stop", true, _token' in acquire

def test_removal_order_is_lift_remove_park_release():
    s = read("addons/acm_extended/functions/fn_chestAccessVestAcquire.sqf")
    grab = s.index('"ACME_HeadElevPatientGrab"')
    remove = s.index("removeVest _p")
    park = s.index("ACME_fnc_chestAccessVestPark")
    release = s.index('"ACME_HeadElevPatientRelease"')
    assert grab < release
    assert remove < release
    assert park < release

def test_restoration_is_lift_revest_release_then_provider_exit():
    s = read("addons/acm_extended/functions/fn_chestAccessVestRestore.sqf")
    grab = s.index('"ACME_HeadElevPatientGrab"')
    revest = s.index("_loadout set [4,+_saved]")
    release = s.index('"ACME_HeadElevPatientRelease"')
    stop = s.index('"stop", false, _token')
    assert grab < revest < release < stop

def test_removed_carrier_has_one_fixed_world_target():
    a = read("addons/acm_extended/functions/fn_chestAccessVestPark.sqf")
    b = read("addons/acm_extended/functions/fn_chestSealParkCarrier.sqf")
    assert "ACME_chestFixedPark" in a
    assert "ACME_chestFixedPark" in b

def test_clinical_launch_is_native_and_generation_scoped():
    s = read("addons/core/overrides/fnc_treatment.sqf")
    start = s.index("// Chest-access preparation is a physical gear transaction")
    end = s.index("// Auscultation owns its own modal display", start)
    block = s[start:end]
    assert "ACME_chestAccess_readyLease" in block
    assert "ACME_chestAccess_readyServer" in block
    assert "ACM_core_fnc_treatmentNative" in block
    assert "ace_medical_treatment_fnc_treatment;" not in block
    assert "ContinuousAction_" not in block

def test_chest_seal_workspace_hands_directly_to_flip_and_back():
    flip = read("addons/acm_extended/functions/fn_chestSealFlip.sqf")
    tick = read("addons/acm_extended/functions/fn_chestSealFlipTick.sqf")
    close = read("addons/acm_extended/functions/fn_chestSealClose.sqf")
    assert '["ACME_CS_providerHoldEpoch",-1]' in flip
    assert 'call ACME_fnc_treatmentPoseStop;' in flip
    assert '[_provider,"roll",_epoch,_current] call ACME_fnc_treatmentPoseStop;' in tick
    assert "ACME_fnc_chestSealProviderHoldStart" in tick
    assert "_providerAtHold" in tick
    assert '(_poseNow param [3,-2]) >= 3' in tick
    assert '["chestSealWorkspace",_holdEpoch,true] call ACME_fnc_treatmentPoseStop;' in close

def test_stethoscope_rolls_wait_for_medic4_hold_without_touching_dialog_lifetime():
    entry = read("addons/acm_extended/functions/fn_stethoscopeEntryFlipTick.sqf")
    flip = read("addons/acm_extended/functions/fn_stethoscopeFlipTick.sqf")
    use = read("addons/breathing/functions/fnc_useStethoscope.sqf")
    assert "_providerAtHold" in entry
    assert "_providerAtHold" in flip
    assert use.index('createDialog "ACM_breathing_Stethoscope_Dialog";') < use.index("call ACME_fnc_patientAnimRequest;")

def test_thoracostomy_waits_for_same_chest_access_transaction():
    s = read("addons/acm_extended/functions/fn_thoraOpen.sqf")
    assert "ACME_chestAccess_readyLease" in s
    assert "ACME_chestAccess_readyServer" in s
    assert s.index("ACME_chestAccess_readyServer") < s.index('["ACME_Thoracostomy_Dialog"]')

def test_semi_fowler_resume_cannot_overlap_carrier_restore():
    s = read("addons/acm_extended/functions/fn_headElevTryResume.sqf")
    assert "ACME_chestAccess_leases" in s
    assert "ACME_chestAccess_vestBusy" in s

def test_cric_acm_lifetime_regression_remains_removed():
    s = read("addons/airway/functions/fnc_establishSurgicalAirway.sqf")
    assert "SurgicalAirway_InProgress_Session" not in s
    assert "ContinuousAction_Session" not in s

if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            fn()
    print("PASS rc20: chest access choreography contracts")
