#!/usr/bin/env python3
"""Phase 143 runtime regression guards: syringe UI, direct pressure, roll, seals and monitor timing."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def txt(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8", errors="replace")

def need(cond: bool, msg: str) -> None:
    if not cond:
        raise AssertionError(msg)

carousel = txt("addons/acm_extended/functions/fn_skCarouselRender.sqf")
dynamic = txt("addons/acm_extended/functions/fn_skDynamicLayout.sqf")
for name, body in [("carousel", carousel), ("dynamic layout", dynamic)]:
    need('private _duration = 0;' in body, f"{name}: duration must be local and event-argument agnostic")
    need('params [["_duration"' not in body, f"{name}: must not type-parse UI Control _this as numeric duration")

dp_pose = txt("addons/acm_extended/functions/fn_directPressurePose.sqf")
dp_limb = txt("addons/acm_extended/functions/fn_directPressureLimb.sqf")
dp_torso = txt("addons/acm_extended/functions/fn_directPressureTorso.sqf")
dp_stop = txt("addons/acm_extended/functions/fn_directPressureStop.sqf")
need("dialog\n    ||" not in dp_pose and "dialog ||" not in dp_pose, "direct pressure: opening medical menu must not cancel hold pose")
need(dp_limb.count('"ACME_DirectPressureHold", 1.1, 1] call ACME_fnc_doAnimHeld') >= 1, "direct pressure limb: immediate held pose missing")
need(dp_torso.count('"ACME_DirectPressureHold", 1.1, 1] call ACME_fnc_doAnimHeld') >= 1, "direct pressure torso: immediate held pose missing")
need('toLower (animationState _medic)' in dp_pose and '"acme_directpressurehold"' in dp_pose, "direct pressure: live animation watchdog missing")
need('ACME_DP_LastPoseAssert' in dp_pose and 'ACME_DP_LastPoseAssert' in dp_stop, "direct pressure: pose watchdog must be rate-limited and cleaned")

menu = txt("addons/gui/overrides/fnc_updateActions.sqf")
need("'acme_stopdirectpressure'" in menu, "medical menu: Stop Direct Pressure class not promoted")
need('_menuActions = _stopPressure + _pressure + _menuActions + _dogTags;' in menu, "medical menu: Stop Direct Pressure must be absolute first")

roll = txt("addons/acm_extended/functions/fn_chestSealRoll.sqf")
need('[_patient, _trans, 1] call ACME_fnc_doAnim;' in roll, "patient roll: smooth priority-1 request missing")
need('[_p, _trans, 2] call ACME_fnc_doAnim;' in roll, "patient roll: priority-2 isolated-state repair missing")
need('ACME_CS_rollToken' in roll and '0.15] call CBA_fnc_waitAndExecute' in roll, "patient roll: guarded delayed fallback missing")

body = txt("addons/gui/functions/fnc_updateBodyImage.sqf")
need('ACME_CS_holeData' in body, "main body map: detailed chest seal state not read")
need('(_x select 4) isEqualTo true' in body, "main body map: sealed flag must be row index 4")
need('ChestSeal_State' in body and '_hasDetailedSeal' in body and '||' in body, "main body map: native and detailed chest-seal states must be combined")

ekg_gen = txt("addons/circulation/functions/fnc_displayAEDMonitor_generateEKG.sqf")
custom_gen = txt("addons/acm_extended/functions/fn_genRhythmEKG.sqf")
handle_aed = txt("addons/circulation/functions/fnc_handleAED.sqf")
monitor = txt("addons/circulation/functions/fnc_displayAEDMonitor.sqf")
get_hr = txt("addons/circulation/functions/fnc_getEKGHeartRate.sqf")
need('_rhythm = _lastShown;' not in ekg_gen, "monitor: rhythm changes must not be deferred by visual latch")
need('[_tgtForRate] call ACM_circulation_fnc_getEKGHeartRate' in ekg_gen, "native EKG generator: waveform period must use electrical HR source")
need('[_tgtForRate] call ACM_circulation_fnc_getEKGHeartRate' in custom_gen, "custom EKG generator: waveform period must use electrical HR source")
need('_roundedEKG != _shownEKG' in handle_aed and '_lastSync + 1 < CBA_missionTime' in handle_aed, "AED readout: changed electrical BPM must publish immediately")
need('_lastSync + 5.25 < CBA_missionTime' not in handle_aed, "AED readout: stale 5.25 second BPM gate remains")
need('private _ekgHR = [_patient] call FUNC(getEKGHeartRate)' in monitor, "monitor display: electrical HR source missing")
need('round _ekgHR) >= 1' in monitor, "monitor display: EKG rate changes must refresh at one-BPM resolution")
need('QGVAR(AED_Monitor_HR), _ekgHR' in monitor, "monitor cache: must store electrical, not mechanical, HR")

need('ACME_rhythm_targetHR' in get_hr and 'if (_effective >= 100)' in get_hr, "EKG HR: custom rhythms must return pinned target rate")
need('ACME_rhythm_vfElectricalHR' in get_hr and 'ACME_rhythm_pvtElectricalHR' in get_hr, "EKG HR: VF/PVT rate must be stable, not rerolled per query")
need('random [150, 170, 200]' not in get_hr and 'random [200, 220, 240]' not in get_hr, "EKG HR: per-call VF/PVT randomization still present")
need('ACME_peaElectricalHR' in get_hr and ', 100]' in get_hr, "PEA: owner-selected electrical rate with 100 BPM fallback missing")
need('private _noiseRange = 3.5;' in ekg_gen and 'private _amp = random [0.90, 1.0, 1.10];' in ekg_gen, "PEA waveform: requested slight artifact/chaos missing")
need('private _gap = [count _cleanRhythmStep] call _fnc_gapFor;' in ekg_gen, "PEA waveform: rate-locked spacing must be preserved")

rh_cfg = txt("addons/acm_extended/functions/fn_initRhythmHemodynamicsConfig.sqf")
reversible = txt("addons/circulation/functions/fnc_handleReversibleCardiacArrest.sqf")
arrest = txt("addons/circulation/functions/fnc_handleCardiacArrest.sqf")
rhythm_set = txt("addons/acm_extended/functions/fn_rhythmSet.sqf")
need('ACME_peaBradyChance        = 0.25;' in rh_cfg, "PEA config: brady phenotype chance missing")
need('ACME_peaNormalModeHR       = 100;' in rh_cfg, "PEA config: normal PEA must center around 100 BPM")
need('ACME_peaBradyModeHR        = 45;' in rh_cfg, "PEA config: brady PEA target missing")
for name, body in [("reversible PEA", reversible), ("cardiac arrest", arrest), ("explicit rhythm set", rhythm_set)]:
    need('ACME_peaElectricalHR' in body, f"{name}: owner-authoritative PEA electrical-rate seed missing")

print("phase 143 runtime pressure/roll/monitor regression: PASS")
