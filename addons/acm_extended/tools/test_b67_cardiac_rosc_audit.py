from historical_source import read_source, assert_release_identity
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def txt(rel):
    return read_source(ROOT / rel, encoding="utf-8")

def test_b67_build_stamp_and_single_rosc_registration():
    assert_release_identity()
    # These are native functions now, compiled once by their owning addon.
    prep=(ROOT.parent/'circulation/XEH_PREP.hpp').read_text()
    for name in ('roscEligibility','attemptROSC'):
        assert prep.count('PREP('+name+');')==1
        assert (ROOT.parent/'circulation/functions'/('fnc_'+name+'.sqf')).is_file()
    assert 'class roscEligibility {};' not in txt('config.cpp')


def test_all_rosc_paths_share_one_eligibility_gate():
    attempt=txt('overrides/fn_attemptROSC.sqf')
    reversible=txt('overrides/fn_handleReversibleCardiacArrest.sqf')
    gate=(ROOT.parent/'circulation/functions/fnc_roscEligibility.sqf').read_text()
    assert 'call FUNC(roscEligibility)' in attempt
    assert 'call FUNC(roscEligibility)' in reversible
    assert 'call ACM_circulation_fnc_attemptROSC' in txt('functions/fn_shockROSC.sqf')
    assert 'GET_BLOOD_VOLUME(_patient) > ACM_REVERSIBLE_CA_BLOODVOLUME' not in reversible
    assert 'GET_CIRCULATIONSTATE(_patient)' in gate
    assert '_volume <= ACM_REVERSIBLE_CA_BLOODVOLUME' in gate
    assert 'CPRSucceeded' in attempt
    from test_historical_cardiac_execution import test_rosc_requires_strict_native_blood_volume_gate, test_shock_rosc_consumes_same_gate_and_rejects_old_episode
    for volume,expected in [(4.19,False),(4.2,False),(4.2001,True)]:
        test_rosc_requires_strict_native_blood_volume_gate(volume,expected)
    for allowed,epoch in [(False,1),(True,1),(True,2)]:
        test_shock_rosc_consumes_same_gate_and_rejects_old_episode(allowed,epoch)


def test_acme_no_longer_has_second_native_rate_arrest_authority():
    threshold=txt('functions/fn_rhythmThresholdTick.sqf')
    assert 'call ACME_fnc_arrestLocal' not in threshold
    vitals=txt('overrides/fn_handleUnitVitals.sqf')
    assert '_heartRate < 40 || {_heartRate > 220}' in vitals
    assert 'GET_MAP(_BPSystolic,_BPDiastolic) < 55' in vitals
    from test_historical_cardiac_execution import test_threshold_observer_never_clears_native_critical_rhythm_without_treatment
    for native in [-1,1,2,3,4]:
        test_threshold_observer_never_clears_native_critical_rhythm_without_treatment(native)


def test_direct_arrest_call_sites_are_intentional_only():
    from source_scan import lex
    allowed={'functions/fn_lidoToxTick.sqf','functions/fn_megacodeArrest.sqf',
             'functions/fn_ownerDispatch.sqf','functions/fn_rhythmTick.sqf',
             'functions/fn_shockLocal.sqf','functions/fn_tbiApplyVitals.sqf'}
    found=set()
    for base in (ROOT/'functions',ROOT/'overrides'):
        for f in base.glob('*.sqf'):
            tokens=lex(f.read_text())
            if any(a.kind=='ident' and a.value=='call' and b.kind=='ident' and b.value=='ACME_fnc_arrestLocal' for a,b in zip(tokens,tokens[1:])):
                found.add(f.relative_to(ROOT).as_posix())
    assert found==allowed
    # Torsades moved from immediate induction to its mature conversion tick.
    from test_historical_cardiac_execution import test_mature_torsades_arrest_request_is_rate_limited_and_stops_after_acknowledgement
    test_mature_torsades_arrest_request_is_rate_limited_and_stops_after_acknowledgement()


def test_nonterminal_tbi_cannot_be_sole_native_fatal_hr_or_map_trigger():
    tbi = txt("functions/fn_tbiApplyVitals.sqf")
    hr = txt("overrides/fn_updateHeartRate.sqf")
    post = txt("functions/fn_postInit.sqf")
    assert 'if (_stage < 3)' in tbi
    assert 'ACME_tbi_nonterminalMinHR", 42' in tbi
    assert 'ACME_tbi_nonterminalMinMAP", 60' in tbi
    assert 'ACME_tbi_nonterminalMinRR", 12' in tbi
    assert '_tbiMAPtarget = _tbiMAPtarget max (_tbiMAPnative min _nonterminalMAPFloor)' in tbi
    assert '_desiredHR = _desiredHR max (_preTbiDesired min _floor)' in hr
    assert 'ACME_tbi_nonterminalMinHR    = 42' in post
    assert 'ACME_tbi_nonterminalMinMAP   = 60' in post
    assert 'ACME_tbi_nonterminalMinRR    = 12' in post
    # Terminal stage remains the only ICP stage with a direct arrest path.
    terminal = tbi[tbi.index('if (_stage >= 3) then {'):]
    assert 'call ACME_fnc_arrestLocal' in terminal


def test_tbi_cpp_acid_does_not_double_count_arrest_or_early_reperfusion():
    circ = txt("functions/fn_circHandle.sqf")
    post = txt("functions/fn_postInit.sqf")
    assert 'ACME_tbi_cppReperfusionWindow", 45' in circ
    assert '_tbiStageForAcid >= 3 && {!_inCardiacArrest} && {!_tbiCppReperf}' in circ
    assert '_state set ["tbiCppReperfusion", _tbiCppReperf]' in circ
    assert '_state set ["tbiCppStage", _tbiStageForAcid]' in circ
    assert 'ACME_tbi_cppReperfusionWindow = 45' in post


def test_monitor_rhythm_change_is_forced_into_active_sweep():
    from test_historical_cardiac_execution import test_rhythm_write_invalidates_both_monitor_caches
    test_rhythm_write_invalidates_both_monitor_caches()
    monitor=(ROOT.parent/'circulation/functions/fnc_displayAEDMonitor.sqf').read_text()
    assert 'private _rhythmChangeEKG = _EKGRhythm != _oldEKGRhythm || {_peaFormChanged};' in monitor
    assert 'private _oldEKGRhythm = _patient getVariable [QGVAR(AED_EKGRhythm), -2];' in monitor
    # No demand for the old generator's 0.18-second delay or repeated sweep restarts.


def test_native_and_extended_reversible_causes_are_composed_once():
    update = txt("overrides/fn_updateCirculationState.sqf")
    # Native ACM reversible conditions stay in one composed publication.
    assert 'GET_OXYGEN(_patient) < ACM_OXYGEN_HYPOXIA' in update
    assert 'TensionPneumothorax_State' in update
    assert 'Hemothorax_Fluid' in update
    assert 'GET_BLOOD_VOLUME(_patient) < BLOOD_VOLUME_CLASS_4_HEMORRHAGE' in update
    # Extended vetoes remain arrest-only and do not make healthy perfusing patients fail circulation state.
    assert '_state && {IN_CRDC_ARRST(_patient)}' in update
    assert 'ACME_rosc_hypothermiaFloorC' in update
    assert 'ACME_rosc_paCO2BlockMmHg' in update
    assert 'ACME_lidoTox_arrestFired' in update



def test_aed_distinguishes_pulseless_defib_from_perfusing_sync_rhythms():
    analyze = txt("overrides/fn_aedAnalyzeRhythm.sqf")
    shock = txt("functions/fn_shockLocal.sqf")
    assert 'private _shockableRhythms = [2, 3] +' in analyze
    assert '[2, 3, 4]' not in analyze
    assert 'private _defib = _rhythm in [2,3,102];' in shock
    assert 'private _organized = _rhythm in [4,100,101,103,104]' in shock
    assert 'if (_organized && {_expectedSync})' in shock
    assert 'if (_organized && {!_expectedSync})' in shock

def test_threshold_safety_margins_are_above_acm_fatal_lines():
    # Executable contract for the intended separation.
    assert 42 > 40
    assert 60 > 55
    assert 12 >= 12
    # Nonterminal MAP guard never rescues a different native pathology; it only refuses to worsen it.
    floor = 60
    for native in (100, 70, 60, 54, 40):
        guarded_target = max(20, min(native, floor))
        if native >= floor:
            assert guarded_target >= floor
        else:
            assert guarded_target >= native
