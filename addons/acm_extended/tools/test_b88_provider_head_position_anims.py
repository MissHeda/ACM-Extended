from historical_source import read_source
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def txt(path):
    return read_source(ROOT / path, encoding="utf-8", errors="ignore")

def main():
    seq = txt("functions/fn_headElevMedicSeq.sqf")
    start = txt("functions/fn_headElevMedicStart.sqf")
    stop = txt("functions/fn_headElevateStop.sqf")
    dispatch = txt("functions/fn_ownerDispatch.sqf")
    cancel = txt("functions/fn_headElevateCancelSeq.sqf")
    post = txt("functions/fn_postInit.sqf")
    cfg = txt("config.cpp")

    elevate_first = "DraggerBasenon"
    elevate_second = "AcinPknlMstpSnonWnonDnon_AmovPknlMstpSnonWnonDnon"
    lower_first = "AmovPknlMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon_Putdown"
    lower_second = "AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"
    rest = "AmovPknlMstpSnonWnonDnon"

    assert elevate_first in seq
    assert elevate_second in seq
    assert lower_first in seq
    assert lower_second in seq
    assert rest in seq

    # Each finite stage has one request site only. The state machine may adopt a native move-graph transition instead.
    assert seq.count('[_u, _first, 2] call ACME_fnc_doAnim;') == 1
    assert seq.count('[_u, _second, 2] call ACME_fnc_doAnim;') == 1

    # Elevation and lowering are explicitly split at their provider call sites.
    assert '[_medic, "elevate"] call ACME_fnc_headElevMedicSeq;' in start
    assert '[_medic, "lower"] call ACME_fnc_headElevMedicSeq;' in stop
    assert 'case "headElevMedicSeq": {_args call ACME_fnc_headElevMedicSeq;};' in dispatch

    # Provider starts are explicitly unarmed stand/crouch and always end in the unarmed crouch.
    assert '_u setUnitPos "UP";' in seq
    assert '_u setUnitPos "MIDDLE";' in seq
    assert '_u selectWeapon "";' in seq
    assert '[_u, _rest, 2] call ACME_fnc_doAnim;' in seq
    assert '[_medic, "AmovPknlMstpSnonWnonDnon", 2] call ACME_fnc_doAnim;' in cancel

    # B87 runtime provider modifiers are not used by the B88 sequence.
    assert 'ACME_HeadElevProviderLift' not in seq
    assert 'ACME_headElev_providerAnimSpeed' not in seq
    assert 'ACME_headElev_providerPinTime' not in seq
    assert 'call ACME_fnc_headElevPinPose' not in seq
    assert 'inputAction ' not in seq

    # Patient animations remain present and unchanged at their existing runtime call sites.
    assert '[_patient, "ACME_HeadElevPatientRelease", 2] call ACME_fnc_doAnim;' in stop
    assert 'class ACME_HeadElevPatientGrab: AinjPpneMrunSnonWnonDb_grab' in cfg
    assert 'class ACME_HeadElevPatientRelease: AinjPpneMrunSnonWnonDb_release' in cfg

    assert 'version = "1.2.0-r0";' in cfg
    assert 'ACME_buildBatch = "B88";' in post

    print("B88 provider head-position animation contracts: PASS")

if __name__ == "__main__":
    main()
