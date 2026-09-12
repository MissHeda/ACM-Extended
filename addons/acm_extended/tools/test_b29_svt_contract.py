"""Evaluate the actual SQF boolean gates against rhythm/rate scenarios.

This checks the cross-function source contract; it does not execute the Arma engine.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    return (ROOT / name).read_text(encoding="utf-8-sig")


def predicate(expression, **values):
    """Translate only the SQF boolean subset used by the selected source gates."""
    expression = expression.replace("&&", " and ").replace("||", " or ")
    expression = re.sub(r"!(?!=)", " not ", expression)
    expression = expression.replace("{", "(").replace("}", ")")
    return bool(eval(expression.strip(), {"__builtins__": {}}, values))


class SVTSourceContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        getter = read("functions/fn_rhythmGet.sqf")
        cls.atrial_gate = re.search(r"if \((_custom in .*?)\) exitWith", getter).group(1)
        tick = read("functions/fn_rhythmTick.sqf")
        cls.release_gate = re.search(r"private _hrReleases = (.*?);", tick).group(1)
        cls.release_gate = cls.release_gate.replace(
            '(missionNamespace getVariable ["ACME_rhythmACMFatalHighHR", 220])', "220"
        )
        threshold = read("functions/fn_rhythmThresholdTick.sqf")
        # B67 retired ACME's independent fatal-rate fallback. ACM handleUnitVitals is now the only
        # native HR-threshold arrest authority; keep compatibility with older source only when that gate exists.
        _fallback = re.search(r"if \((_hr > _acmHighHR.*?)\) then", threshold)
        cls.fallback_gate = _fallback.group(1) if _fallback else None
        cls.threshold_has_arrest = "call ACME_fnc_arrestLocal" in threshold
        cls.vitals = read("overrides/fn_handleUnitVitals.sqf")
        cls.vt_gate = re.search(r"if (!\(\(\[_unit\] call ACME_fnc_rhythmGet\).*?) then", cls.vitals).group(1)
        cls.vt_gate = cls.vt_gate.replace("([_unit] call ACME_fnc_rhythmGet)", "_rhythm")
        cls.fatal_gate = re.search(r"case \((!_activeGracePeriod.*?)\):", cls.vitals).group(1)

    def test_all_supported_atrial_rhythms_keep_identity_above_220(self):
        for code in (100, 101, 103, 104):
            for rate in (221, 235, 240, 246):
                with self.subTest(code=code, rate=rate):
                    valid = predicate(self.atrial_gate, _custom=code, _raw=0, _arrest=False)
                    self.assertTrue(valid)
                    self.assertFalse(predicate(self.release_gate, _isTorsades=False,
                                               _hrNow=rate, _isPerfusingAtrial=valid))
                    if self.fallback_gate is not None:
                        self.assertFalse(predicate(self.fallback_gate, _hr=rate, _acmHighHR=220,
                                                   _rhythm=code))
                    else:
                        self.assertFalse(self.threshold_has_arrest)
                    self.assertFalse(predicate(self.vt_gate, _rhythm=code))
                    # Native instability monitoring must still run even at extreme SVT rates.
                    self.assertTrue(predicate(self.fatal_gate, _activeGracePeriod=False,
                                              _heartRate=rate))

    def test_native_rhythm_and_arrest_override_stale_custom_state(self):
        for raw in (-1, 1, 2, 3, 4, 5):
            for arrest in (False, True):
                with self.subTest(raw=raw, arrest=arrest):
                    self.assertFalse(predicate(self.atrial_gate, _custom=104, _raw=raw,
                                               _arrest=arrest))
        self.assertFalse(predicate(self.atrial_gate, _custom=104, _raw=0, _arrest=True))
        self.assertFalse(predicate(self.atrial_gate, _custom=102, _raw=0, _arrest=False))
        if self.fallback_gate is not None:
            self.assertTrue(predicate(self.fallback_gate, _hr=230, _acmHighHR=220, _rhythm=0))
        else:
            # B67: ACM's fatal-vitals watchdog owns this transition; ACME does not race it.
            self.assertFalse(self.threshold_has_arrest)
        self.assertTrue(predicate(self.vt_gate, _rhythm=0))

    def test_bradycardia_still_releases_atrial_rhythm(self):
        for rate in (0, 10, 30, 39):
            self.assertTrue(predicate(self.release_gate, _isTorsades=False, _hrNow=rate,
                                      _isPerfusingAtrial=True))
            self.assertTrue(predicate(self.fatal_gate, _activeGracePeriod=False,
                                      _heartRate=rate))
        # Torsades is already pulseless; its zero mechanical rate must not erase its overlay.
        self.assertFalse(predicate(self.release_gate, _isTorsades=True, _hrNow=0,
                                   _isPerfusingAtrial=False))

    def test_watchdog_event_remains_outside_conditional_vt_write(self):
        high_branch = self.vitals.split('TRACE_2("heartRate Fatal",_unit,_heartRate);', 1)[1]
        high_branch = high_branch.split('case (GET_MAP(', 1)[0]
        # The event belongs after the high/low branches, so narrow SVT does not escape the watchdog.
        self.assertRegex(high_branch,
                         r'\};\s*\[QGVAR\(handleFatalVitals\), _unit\] call CBA_fnc_localEvent;')

    def test_only_rhythm_generated_discomfort_loses_hr_feedback(self):
        hr = read("overrides/fn_updateHeartRate.sqf")
        self.assertIn("private _painLevel = GET_PAIN_PERCEIVED(_unit);", hr)
        self.assertIn("_desiredHR + 50 * _painLevel", hr)
        self.assertIn("_desiredHR + 40 * _painLevel", hr)
        self.assertNotIn('getVariable ["ACME_rhythm_painContribution"', hr)
        # The patient's rhythm-related pain effect itself remains present.
        self.assertIn('getVariable ["ACME_rhythm_painContribution"',
                      read("overrides/fn_handleEffects.sqf"))


if __name__ == "__main__":
    unittest.main()
