"""Current native-rate precedence, replacing retired B29 SVT exceptions.

The old setup demanded an inline exception that the current native vitals path
explicitly removed. Evaluate the actual production gates in SQF-VM, not a
handwritten Python physiological model. No medication/rhythm rules are changed.
"""
from pathlib import Path
import re
import pytest
from historical_source import read_source
from source_scan import lex, matching
from test_menu_death_lifecycle import execute, adapt

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return read_source(ROOT / path, encoding="utf-8-sig")


def assignment(text, name):
    hits = re.findall(r"private " + re.escape(name) + r"\s*=\s*([^;]+);", text)
    assert len(hits) == 1, (name, len(hits))
    return hits[0]


def gates():
    tick = read("functions/fn_rhythmTick.sqf")
    vitals = read("overrides/fn_handleUnitVitals.sqf")
    rate = assignment(tick, "_hrReleases")
    takeover = assignment(tick, "_physiologyTookOver")
    torsades = assignment(tick, "_torsadesOwnsPVT")
    fatal = re.findall(r"case \((!_activeGracePeriod[^:]+)\):", vitals)
    assert len(fatal) == 1
    return rate, takeover, torsades, fatal[0]


@pytest.mark.parametrize("rate", [0, 39, 40, 120, 219, 220, 221, 246])
def test_native_rate_boundary_takes_priority_without_an_atrial_exception(rate):
    release, takeover, torsades, fatal = gates()
    execute('''
        private _u = _patient;
        private _torsadesOwnsPVT = false;
        private _curRhythm = 0;
        private _activeGracePeriod = false;
        _patient setVariable ["ace_medical_inCardiacArrest", false];
    ''' + f"private _hrNow = {rate}; private _heartRate = {rate};" +
        "private _hrReleases = " + release + ";" +
        "private _takeover = " + takeover + ";" +
        "private _fatal = " + fatal + ";" +
        f"[_hrReleases isEqualTo {str(rate < 40 or rate > 220).lower()},'wrong boundary'] call _check;" +
        "[_takeover isEqualTo _hrReleases && {_fatal isEqualTo _hrReleases},'native precedence mismatch'] call _check;")


@pytest.mark.parametrize("raw,arrest", [(0,False),(0,True),(-1,False),(1,False),(2,False),(3,False),(4,False),(5,False)])
def test_native_arrest_or_critical_rhythm_releases_custom_overlay(raw, arrest):
    release, takeover, _, _ = gates()
    execute("private _u = _patient; private _torsadesOwnsPVT = false; private _hrReleases = false;" +
        f"private _curRhythm = {raw}; _patient setVariable ['ace_medical_inCardiacArrest',{str(arrest).lower()}];" +
        "private _takeover = " + takeover + ";" +
        f"[_takeover isEqualTo {str(arrest or raw != 0).lower()},'native takeover ignored'] call _check;")


def test_mature_torsades_preserves_morphology_but_not_mechanical_perfusion():
    _, takeover, torsades, _ = gates()
    getter = read("functions/fn_rhythmGet.sqf")
    morphology = assignment(getter, "_torsadesPVT")
    execute("private _u = _patient; private _unit = _patient; private _code = 102; private _custom = 102;" +
        "private _curRhythm = 3; private _raw = 3; private _arrest = true; private _torsadesNonPerf = true; private _hrReleases = true;" +
        "_patient setVariable ['ace_medical_inCardiacArrest',true]; _patient setVariable ['ACME_rhythm_torsadesNonPerfusing',true];" +
        "private _torsadesOwnsPVT = " + torsades + ";" +
        "private _takeover = " + takeover + "; private _keepMorphology = " + morphology + ";" +
        "[_torsadesOwnsPVT && {!_takeover} && {_keepMorphology},'mature PVT morphology lost'] call _check;")


def test_native_fatal_watchdog_is_outside_high_low_branch_and_has_no_custom_veto():
    vitals = read("overrides/fn_handleUnitVitals.sqf")
    start = vitals.index('TRACE_2("heartRate Fatal",_unit,_heartRate);')
    block = vitals[start:vitals.index('case (GET_MAP(', start)]
    assert 'ACME_fnc_rhythmGet' not in block
    assert 'ACM_Rhythm_VT' in block and 'ACM_Rhythm_PVT' in block
    # There must be exactly one watchdog event after the high/low if scopes.
    tokens = lex(block)
    event = next(i for i,t in enumerate(tokens) if t.value == 'handleFatalVitals')
    depth = 0
    for t in tokens[:event]:
        if t.kind == 'symbol': depth += (t.value == '{') - (t.value == '}')
    assert depth == 0, 'watchdog incorrectly nested in a branch'
    assert block.count('[QGVAR(handleFatalVitals), _unit] call CBA_fnc_localEvent;') == 1
    assert 'call ACME_fnc_arrestLocal' not in read("functions/fn_rhythmThresholdTick.sqf")


def test_wound_pain_still_affects_rate_but_overlay_discomfort_is_not_fed_back():
    heart = read("overrides/fn_updateHeartRate.sqf")
    assert 'private _painLevel = GET_PAIN_PERCEIVED(_unit);' in heart
    assert '_desiredHR + 50 * _painLevel' in heart
    assert '_desiredHR + 40 * _painLevel' in heart
    assert 'getVariable ["ACME_rhythm_painContribution"' not in heart
    assert 'getVariable ["ACME_rhythm_painContribution"' in read("overrides/fn_handleEffects.sqf")
