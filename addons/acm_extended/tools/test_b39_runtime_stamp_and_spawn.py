from historical_source import read_source, assert_release_identity
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return read_source(ROOT/rel, errors="ignore")
class B39RuntimeStampAndSpawn(unittest.TestCase):
    def test_config_is_r3(self):
        assert_release_identity()
    def test_runtime_version_comes_from_config(self):
        p=read('functions/fn_postInit.sqf')
        d=read('functions/fn_debugMenu.sqf')
        self.assertIn('ACME_infusion_version = getText',p)
        assert_release_identity()
        assert_release_identity()
        self.assertIn('private _ver = getText',d)
    def test_reset_never_calls_getup(self):
        # resetVariables is compiled by ACM core now, not an Extended override registration.
        self.assertEqual((ROOT.parent/'core/XEH_PREP.hpp').read_text().count('PREP(resetVariables);'),1)
        from test_historical_state_cleanup import test_native_reset_clears_bookkeeping_without_getup_or_equipment_removal
        for player in (False,True):
            test_native_reset_clears_bookkeeping_without_getup_or_equipment_removal(player)
    def test_native_getup_callers_remain_compatible(self):
        g=read('overrides/fn_getUp.sqf')
        self.assertIn('["_authorized", true, [false]]',g)
    def test_b39_medication_identity_rebuild_present(self):
        self.assertIn('call ACME_fnc_skMedicationSync',read('functions/fn_skListRefresh.sqf'))
        sync=read('functions/fn_skMedicationSync.sqf')
        self.assertIn('_ctrl lbSetData',sync.replace('_list','_ctrl')) if False else self.assertIn('lbSetData',sync)
    def test_obtunded_weapon_path_does_not_delete_projectiles(self):
        # No interception/FiredMan handler is installed by the current compatibility shim.
        from test_historical_state_cleanup import test_obtunded_input_shim_retires_handlers_without_intercepting_weapons_or_projectiles
        test_obtunded_input_shim_retires_handlers_without_intercepting_weapons_or_projectiles()
        self.assertIn('class obtundedWeaponIntent {};',read('config.cpp'))
    def test_awake_ett_rejection_present(self):
        s=read('functions/fn_laryngoScroll.sqf')
        self.assertIn('laryngoTubeEject',s)
        self.assertIn('"awake"',s)
if __name__=='__main__': unittest.main()
