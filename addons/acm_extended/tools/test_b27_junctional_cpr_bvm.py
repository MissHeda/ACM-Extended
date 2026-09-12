from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return (ROOT/rel).read_text(encoding='utf-8-sig')

class B27JunctionalCPRBVM(unittest.TestCase):
    def test_version_pair(self):
        for rel in ('config.cpp','functions/fn_postInit.sqf'):
            self.assertRegex(read(rel), r'(?:0\.9\.999r-\d+-NA8\.5-B(?:27|28|29|30|31|32|33|34|35)|1\.0\.100-r(?:2|3|4|5|6|7))')
    def test_junctional_state_writers_still_broadcast(self):
        for rel in ('functions/fn_junctionalInflict.sqf','functions/fn_junctionalPackDone.sqf','functions/fn_junctionalWrapDone.sqf'):
            s=read(rel)
            self.assertRegex(s, r'setVariable\s*\[format\s*\["ACME_Junc_%1".*?true\]')
    def test_junctional_gui_sync_is_local_only(self):
        s=read('functions/fn_junctionalGuiSyncTick.sqf')
        self.assertIn('ace_medical_gui_menuDisplay',s)
        self.assertIn('ace_medical_gui_fnc_updateBodyImage',s)
        self.assertIn('ace_medical_gui_fnc_updateInjuryList',s)
        for bad in ('targetEvent','globalEvent','serverEvent','remoteExec','publicVariable','_target setVariable','_patient setVariable'):
            self.assertNotIn(bad,s)
    def test_junctional_gui_sync_is_bounded(self):
        p=read('functions/fn_postInit.sqf')
        self.assertIn('[{call ACME_fnc_junctionalGuiSyncTick}, 0.2, []] call CBA_fnc_addPerFrameHandler;',p)
    def test_cpr_action_no_longer_blocked_by_bvm(self):
        c=read('config.cpp')
        block=c[c.index('class CPR {'):c.index('// move all AED options',c.index('class CPR {'))]
        self.assertIn('condition = "[_medic, _patient] call ace_medical_treatment_fnc_canCPR";',block)
        self.assertNotIn('ACM_core_fnc_bvmActive',block)
    def test_begin_cpr_override_registered(self):
        c=read('config.cpp')
        self.assertIn('class beginCPR { file = "\\acm_extended\\overrides\\fn_beginCPR.sqf"; };',c)
        s=read('overrides/fn_beginCPR.sqf')
        self.assertIn('CPR and BVM are independent provider roles',s)
        self.assertNotIn('if !([GVAR(CPRTarget)] call EFUNC(core,bvmActive))',s)
    def test_bvm_can_run_during_cpr(self):
        s=read('overrides/fn_useBVM.sqf')
        self.assertIn('Two-provider resuscitation',s)
        self.assertIn('_patient setVariable ["ACM_breathing_BVM_provider", _medic, true];',s)
        self.assertIn('ACM_breathing_BVMActive = true;',s)
        self.assertNotIn('if !([ACM_breathing_BVMTarget] call ACM_core_fnc_cprActive)',s)
    def test_one_provider_per_role_remains(self):
        b=read('overrides/fn_useBVM.sqf')
        c=read('overrides/fn_beginCPR.sqf')
        self.assertIn('alive _existingBVM',b)
        self.assertIn('alive _existingCPR',c)
    def test_cross_provider_role_vars_still_networked(self):
        b=read('overrides/fn_useBVM.sqf')
        c=read('overrides/fn_beginCPR.sqf')
        self.assertIn('"ACM_breathing_BVM_provider", _medic, true',b)
        self.assertIn('QACEGVAR(medical,CPR_provider), _medic, true',c)

if __name__=='__main__': unittest.main()
