import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def src(name: str) -> str:
    return (ROOT / "functions" / f"fn_{name}.sqf").read_text(encoding="utf-8", errors="ignore")


def post() -> str:
    return src("postInit")


class B65AcreBabbleSafety(unittest.TestCase):
    def test_build_stamp(self):
        self.assertIn('version = "1.0.100-r29";', (ROOT / "config.cpp").read_text(encoding="utf-8", errors="ignore"))
        self.assertIn('ACME_buildBatch = "B65";', post())

    def test_pulse_scheduler_registered_and_called_from_obtunded_tick(self):
        config = (ROOT / "config.cpp").read_text(encoding="utf-8", errors="ignore")
        self.assertIn("class acreBabbleTick {};", config)
        self.assertIn("[_p] call ACME_fnc_acreBabbleTick;", src("obtundedTick"))

    def test_enable_has_no_master_off_or_manual_bypass(self):
        t = src("acreBabbleSet")
        enable = t.split("if (_on) then {", 1)[1].split("} else {", 1)[0]
        self.assertIn('ACME_sys_obtunded", false', enable)
        self.assertIn('ACME_obtunded", false', enable)
        self.assertIn('ACE_isUnconscious', enable)
        self.assertIn("_pulseAuthorized", enable)
        self.assertNotIn('ACME_obtunded_manual', enable)
        self.assertIn('ACME_acre_babbleEnable", false', enable)

    def test_enable_itself_requires_current_speech(self):
        t = src("acreBabbleSet")
        enable = t.split("if (_on) then {", 1)[1].split("} else {", 1)[0]
        self.assertIn('acre_api_fnc_isSpeaking', enable)
        self.assertIn('[_player] call acre_api_fnc_isSpeaking', enable)
        self.assertIn('ACME_obtunded_lucidActive', enable)

    def test_voice_function_cannot_enable_acre_babble(self):
        t = src("obtundedVoice")
        self.assertNotIn("[_effectiveMute] call ACME_fnc_acreBabbleSet", t)
        self.assertNotIn("[true", t.split("// ACRE2.", 1)[1])
        self.assertIn("[false] call ACME_fnc_acreBabbleSet", t)

    def test_scheduler_requires_master_obtundation_and_speech(self):
        t = src("acreBabbleTick")
        gate = t.split("private _validState", 1)[1].split("if (!_validState)", 1)[0]
        for needle in (
            'ACME_sys_obtunded", false',
            'ACME_obtunded", false',
            'ACE_isUnconscious',
            'acre_api_fnc_isSpeaking',
        ):
            self.assertIn(needle, gate)
        self.assertIn("private _speaking = [_unit] call acre_api_fnc_isSpeaking;", t)

    def test_silence_and_lucid_windows_force_restore(self):
        t = src("acreBabbleTick")
        self.assertRegex(t, r'if \(uiNamespace getVariable \["ACME_obtunded_lucidActive".*?\) exitWith \{[\s\S]*?\[false\] call ACME_fnc_acreBabbleSet;',)
        self.assertRegex(t, r'if \(!_speaking\) exitWith \{[\s\S]*?\[false\] call ACME_fnc_acreBabbleSet;',)

    def test_master_callback_force_restores_before_releasing_units(self):
        t = src("obtundedMasterChanged")
        off = t.split("// B65 safety gate:", 1)[1]
        self.assertIn("[false, false, true] call ACME_fnc_acreBabbleSet;", off)
        self.assertLess(off.index("[false, false, true] call ACME_fnc_acreBabbleSet;"), off.index("forEach allUnits"))

    def test_startup_force_sanitizes_language(self):
        t = src("acreBabbleInit")
        self.assertIn("[false, false, true] call ACME_fnc_acreBabbleSet;", t)
        self.assertIn('ACME_acre_babbleEnable", false', t)
        self.assertIn('ACME_sys_obtunded", false', t)

    def test_master_on_allows_registration_but_does_not_force_obtundation(self):
        t = src("obtundedMasterChanged")
        on_branch = t.split('if (missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith {', 1)[1].split('};', 1)[0]
        self.assertIn("call ACME_fnc_acreBabbleInit;", on_branch)
        self.assertNotIn("ACME_fnc_obtundedSet", on_branch)
        init = src("acreBabbleInit")
        self.assertLess(init.index('ACME_sys_obtunded", false'), init.index('acre_api_fnc_babelAddLanguageType'))

    def test_physiology_controls_severity_from_spo2_and_map(self):
        t = src("acreBabbleTick")
        self.assertIn('ace_medical_spo2', t)
        self.assertIn('ace_medical_status_fnc_getBloodPressure', t)
        self.assertIn('ACME_obtunded_spo2Recover', t)
        self.assertIn('ACME_obtunded_spo2EnterLo', t)
        self.assertIn('ACME_obtunded_mapRecover', t)
        self.assertIn('ACME_obtunded_mapEnterLo', t)
        self.assertIn('_severity = (_spo2Severity max _mapSeverity)', t)

    def test_worsening_means_more_frequent_but_still_brief_pulses(self):
        t = post()
        vals = {}
        for key in (
            "ACME_acre_babblePulseMildMin", "ACME_acre_babblePulseMildRand",
            "ACME_acre_babblePulseSevereMin", "ACME_acre_babblePulseSevereRand",
            "ACME_acre_babbleGapMildMin", "ACME_acre_babbleGapMildRand",
            "ACME_acre_babbleGapSevereMin", "ACME_acre_babbleGapSevereRand",
        ):
            m = re.search(rf"{key}\s*=\s*([0-9.]+);", t)
            self.assertIsNotNone(m, key)
            vals[key] = float(m.group(1))

        mild_dur_max = vals["ACME_acre_babblePulseMildMin"] + vals["ACME_acre_babblePulseMildRand"]
        severe_dur_max = vals["ACME_acre_babblePulseSevereMin"] + vals["ACME_acre_babblePulseSevereRand"]
        mild_gap_min = vals["ACME_acre_babbleGapMildMin"]
        severe_gap_min = vals["ACME_acre_babbleGapSevereMin"]

        self.assertLessEqual(mild_dur_max, 0.35)
        self.assertLessEqual(severe_dur_max, 0.75)
        self.assertGreater(mild_gap_min, severe_gap_min)
        self.assertGreater(severe_gap_min, severe_dur_max)

    def test_only_scheduler_has_authorized_enable_call(self):
        offenders = []
        for p in (ROOT / "functions").glob("fn_*.sqf"):
            text = p.read_text(encoding="utf-8", errors="ignore")
            if "[true, true] call ACME_fnc_acreBabbleSet" in text and p.name != "fn_acreBabbleTick.sqf":
                offenders.append(p.name)
        self.assertEqual([], offenders)
        self.assertIn("[true, true] call ACME_fnc_acreBabbleSet", src("acreBabbleTick"))


if __name__ == "__main__":
    unittest.main()
