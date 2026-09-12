"""Wrap action coverage and shared audio lifecycle contracts; no Arma runtime."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
INIT = (ROOT / 'functions/fn_wrapSfxInit.sqf').read_text()
START = (ROOT / 'functions/fn_wrapSfxStart.sqf').read_text()
STOP = (ROOT / 'functions/fn_wrapSfxStop.sqf').read_text()
SERVER = (ROOT / 'functions/fn_wrapSfxServer.sqf').read_text()
CONFIG = (ROOT / 'config.cpp').read_text()


class WrapSfxContracts(unittest.TestCase):
    def test_native_wrap_family_covers_all_four_operations(self):
        fixture = json.loads((ROOT / 'tools/na8_action_fixture.json').read_text())
        actions = fixture['entries'].values()
        bases = {row['name'].lower(): row['base'].lower() for row in actions}
        root = re.search(r'_wrap = _name == "([^"]+)";', INIT)[1]

        def covered(name):
            seen = set()
            while name and name not in seen:
                if name == root:
                    return True
                seen.add(name)
                name = bases.get(name, '')
            return False

        for name in ('ElasticWrap', 'ElasticWrapBandages', 'ElasticWrapClots', 'ElasticWrapSplint'):
            self.assertTrue(covered(name.lower()), name)
        for name in ('StitchWrappedWounds', 'StitchWrappedWounds_Suture', 'ACME_UnwrapHPMK', 'EmergencyTraumaDressing'):
            self.assertFalse(covered(name.lower()), name)
        self.assertIn('toLower _classname == "acme_wraphpmk"', INIT)
        self.assertIn('inheritsFrom _cfg', INIT)

    def test_global_emitter_uses_existing_junctional_wrapping_asset(self):
        emitter = re.search(r'createSoundSource \["([^"]+)"', SERVER)[1]
        sound_class = re.search(r'class ' + re.escape(emitter) + r': Sound\s*\{[^}]*sound = "([^"]+)"', CONFIG)[1]
        sound_block = re.search(r'class ' + re.escape(sound_class) + r'\s*\{(.*?)\n    \};', CONFIG, re.S)[1]
        self.assertIn('junctionalwound_wrapping_sfx.ogg', sound_block)
        self.assertNotIn('createSoundSourceLocal', SERVER)
        self.assertIn('CBA_fnc_serverEvent', START)
        self.assertIn('if (!isServer) exitWith', SERVER)
        for helper in ('Start', 'Stop'):
            delegate = (ROOT / ('functions/fn_junctionalWrapSfx' + helper + '.sqf')).read_text()
            self.assertIn('call ACME_fnc_wrapSfx' + helper, delegate)
            self.assertNotIn('createSoundSource', delegate)
        self.assertIn('"acme_wrapjunctional") exitWith {}', INIT)

    def test_real_action_events_own_start_and_stop(self):
        for event in ('ace_treatmentStarted', 'ace_treatmentSucceded', 'ace_treatmentFailed'):
            self.assertIn('"' + event + '"', INIT)
        self.assertNotIn('treatmentTime', START + STOP + SERVER)
        self.assertNotIn('waitAndExecute', START + STOP + SERVER)
        self.assertIn('deleteVehicle (_x select 3)', SERVER)
        self.assertIn('(_x select 2) == _token', SERVER)
        for guard in ('_patient isEqualTo _activePatient', 'toLower _bodyPart != _activePart', 'toLower _classname != _activeClass'):
            self.assertIn(guard, STOP)

    def test_watchdog_cleans_orphans_without_muting_other_providers(self):
        for guard in ('!isNull _provider', 'alive _provider', 'owner _provider == _origin', 'isPlayer _provider', 'ACE_isUnconscious'):
            self.assertIn(guard, SERVER)
        self.assertIn('(_x select 0) isEqualTo _medic', SERVER)
        self.assertIn('CBA_fnc_removePerFrameHandler', SERVER)
        self.assertIn('if (_active isEqualTo [])', SERVER)
        self.assertNotIn('!alive _target', SERVER)
        self.assertNotRegex(INIT, r'setVariable.*(wound|blood|Junc_)')


if __name__ == '__main__':
    unittest.main()
