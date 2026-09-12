"""Offline balance/state contracts; these do not execute Arma animation or physiology."""
from pathlib import Path
import math
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PARTS = ('leftarm', 'rightarm', 'leftleg', 'rightleg')


def source(name):
    return (ROOT / 'functions' / f'fn_{name}.sqf').read_text(encoding='utf-8-sig')


def configured_norm(name):
    return float(re.search(r'ACME_junctionalBleedNorm\s*=\s*([.\d]+);', source(name))[1])


def isolated_two_litre_time(norm, parts, compensation=False):
    """6->4 L, isolated junctions: ref80, resistance100, coeff1, fixed vaso0.

    Fine integration independently checks the expected treatment window. There is no
    native wound, changing resistance/HR, transfusion, arrest or treatment in this model.
    """
    blood, elapsed, step = 6.0, 0.0, 0.01
    while blood > 4.0:
        shape = (elapsed / 12 if elapsed < 12 else 1 if elapsed < 57
                 else 1 - (elapsed - 57) / 105 if elapsed < 162 else 0)
        control = 1 - 0.55 * shape * 0.4 if compensation else 1
        stroke = 0.095 * 80 / 60 * max(0, min((blood - 3) / 3, 1))
        blood -= norm * parts * control * max(stroke, 0.02) * step
        elapsed += step
    return elapsed


def retained_evidence():
    """Read the literal evidence policy to exercise reset fixtures against its fields."""
    text = source('clinicalReset')
    block = text[text.index('private _junctionalEvidence'):text.index('_x params ["_name"')]
    literals = re.findall(r'"(ACME_[^"]+)"', block)
    return {name.replace('%1', part) for name in literals for part in PARTS}


class JunctionalB31(unittest.TestCase):
    def test_active_and_fallback_balance_match(self):
        self.assertEqual(configured_norm('postInit'), 0.10)
        self.assertEqual(configured_norm('applyHardcore'), 0.15)
        self.assertIn('["ACME_junctionalBleedNorm", 0.10]', source('junctionalStartBleed'))
        self.assertIn('["ACME_junctionalPackControl", 0.0]', source('junctionalStartBleed'))

    def test_isolated_loss_matches_analytic_stroke_curve(self):
        for parts in (1, 2):
            for norm in (0.35, 0.10, 0.45, 0.15):
                analytic = 3 * math.log(3) / (norm * parts * 0.095 * 80 / 60)
                self.assertAlmostEqual(isolated_two_litre_time(norm, parts), analytic, delta=0.03)

    def test_compensated_two_junction_window_is_materially_longer(self):
        old = isolated_two_litre_time(0.35, 2, True)
        new = isolated_two_litre_time(configured_norm('postInit'), 2, True)
        hardcore = isolated_two_litre_time(configured_norm('applyHardcore'), 2, True)
        self.assertAlmostEqual(old, 45.96, delta=0.03)
        self.assertAlmostEqual(new, 152.78, delta=0.03)
        self.assertGreater(new, old * 3)
        self.assertLess(hardcore, new)
        self.assertGreater(hardcore, old * 2)

    def test_death_and_respawn_choose_the_correct_reset_mode(self):
        post = source('postInit')
        self.assertRegex(post, r'EntityKilled[\s\S]*?\[_unit, true\] call ACME_fnc_clearAllAilments')
        self.assertIn('[_x, (_x isEqualTo _oldUnit && {!alive _x})] call ACME_fnc_clearAllAilments', post)
        self.assertIn('["ace_medical_FullHeal", {_this call ACME_fnc_clearAllAilments}]', post)
        clear = source('clearAllAilments')
        self.assertIn('(_this param [1, false]) isEqualTo true} && {!alive _patient}', clear)
        self.assertIn('if (!_preserveJunctional && {!isNil "ACME_fnc_junctionalFullHeal"})', clear)
        self.assertIn('[_patient, "finish", _preserveJunctional] call ACME_fnc_clinicalReset', clear)

    def test_corpse_keeps_wounds_devices_but_not_in_progress_treatment(self):
        keep = retained_evidence()
        self.assertTrue(all(f'ACME_Junc_{part}' in keep for part in PARTS))
        self.assertTrue(all(f'ACME_Junc_XStatAt_{part}' in keep for part in PARTS))
        fixture = {'ACME_Junc_leftarm': 'open', 'ACME_Junc_rightarm': 'packed',
                   'ACME_Junc_leftleg': 'wrapped', 'ACME_Junc_rightleg': 'xstat',
                   'ACME_AAJT_inguinal': True, 'ACME_Junc_XStatAt_rightleg': 12,
                   'ACME_Junc_Packing_leftarm': True, 'ACME_Junc_PackStamp_leftarm': 30,
                   'ACME_Junc_AAJTApplying': 25, 'ACME_AAJT_downedActive': True}
        corpse = {k: v for k, v in fixture.items() if k in keep}
        self.assertEqual(len(corpse), 6)
        self.assertEqual(corpse['ACME_Junc_rightleg'], 'xstat')
        # The ordinary heal/new-body mode has an empty keep list, so no evidence survives.
        self.assertEqual({k: v for k, v in fixture.items() if k in set()}, {})
        self.assertIn('if (_preserveJunctional && {!alive _patient})', source('clinicalReset'))
        self.assertIn('!(_name in _junctionalEvidence)', source('clinicalReset'))

    def test_death_invalidates_workers_and_silences_leak(self):
        reset = source('clinicalReset')
        self.assertIn('ACME_fnc_clinicalEpoch) + 1, true', reset)
        self.assertIn('"ACME_juncPFH"', reset)
        self.assertIn('["ACME_juncWorker", [], false]', reset)
        self.assertIn('["ACME_JuncBleedActive", false, false]', reset)
        clear = source('clearAllAilments')
        self.assertIn('deleteVehicle _juncLeakSrc', clear)
        self.assertIn('["ACME_JuncLeakSfxSrc", objNull, true]', clear)
        for name in ('junctionalStartBleed', 'junctionalResume'):
            self.assertIn('!alive _unit', source(name))

    def test_corpse_render_keeps_evidence_without_rebleed_progression(self):
        image = source('updateJunctionalImage')
        self.assertIn('_woundC ctrlShow (_state in ["open", "packed", "xstat"]);', image)
        self.assertIn('_wrapC  ctrlShow (_state == "wrapped");', image)
        self.assertNotIn('alive _target', image)
        self.assertIn('alive _target,', source('junctionalGuiSyncTick'))
        self.assertIn('if (alive _target && {(time - _at) > _xDwell})', source('junctionalInjuryEntry'))


if __name__ == '__main__':
    unittest.main()
