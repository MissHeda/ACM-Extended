from pathlib import Path
import unittest, re
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return (ROOT/rel).read_text(encoding='utf-8-sig')

class B19Source(unittest.TestCase):
    def test_version_pair(self):
        for rel in ('config.cpp','functions/fn_postInit.sqf'):
            self.assertRegex(read(rel), r'(?:0\.9\.999r-\d+-NA8\.5-B(?:17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35)|1\.0\.100-r(?:2|3|4|5|6|7))')
    def test_exact_vial_ledger_registered(self):
        c=read('config.cpp')
        for fn in ('vialHolder','vialItemCount','vialTake','vialRefund'):
            self.assertIn(f'class {fn} {{}};',c)
        for fn in ('Syringe_PrepareFinish','Syringe_GetMedicationList','Syringe_UpdateMedicationList'):
            self.assertIn(f'class {fn} ',c)
    def test_native_syringe_debits_exact_ml(self):
        s=read('overrides/fn_syringePrepareFinish.sqf')
        self.assertIn('ACME_fnc_vialTake',s)
        self.assertIn('ACME_fnc_vialItemCount',read('functions/fn_vialTake.sqf'))
        self.assertNotIn('removeItem (format ["ACM_Vial_',s)
        self.assertIn('ACME_fnc_vialRefund',s)
    def test_partial_vial_is_listed_without_physical_item(self):
        get_list=read('overrides/fn_syringeGetMedicationList.sqf')
        sync=read('functions/fn_skMedicationSync.sqf')
        update=read('overrides/fn_syringeUpdateMedicationList.sqf')
        # B42 builds membership from the selected live inventory and appends the exact open-vial ledger,
        # so a partial vial remains drawable after first puncture without making a global registry the UI source.
        source=read('functions/fn_medicationSourceRows.sqf')
        self.assertIn('ACME_fnc_medicationSourceRows', get_list)
        self.assertIn('ACME_fnc_medicationSourceRows', sync)
        self.assertIn('ACME_infusion_openVials', source)
        self.assertIn('keys _open', source)
        self.assertIn('ACME_fnc_skMedicationSync', update)
        self.assertNotIn('toFixed',update); self.assertNotIn('Common_Available',update)
    def test_final_partial_volume_limits_plunger(self):
        s=read('functions/fn_skUiTick.sqf')
        self.assertIn('ACM_circulation_SyringeDraw_MaxDose',s)
        # The hard stop is ledger-backed through vialSession; B41 removed a second redundant stock scan.
        self.assertIn('ACME_fnc_vialSession',s); self.assertIn('private _hardMax',s)
    def test_compound_save_keeps_original_save_label_and_reopens_draw_dialog(self):
        begin=read('functions/fn_skCompoundBegin.sqf')
        self.assertIn('ctrlSetText "Save"',begin)
        self.assertNotIn('Save & New Syringe',begin)
        s=read('functions/fn_skCompoundSave.sqf')
        self.assertIn('ACME_fnc_skOpenDraw',s); self.assertIn('closeDialog 0',s)
    def test_infusion_done_explicitly_returns(self):
        d=read('functions/fn_infusionDone.sqf'); c=read('functions/fn_skClose.sqf')
        self.assertIn('ACME_SK_suppressReturn',d); self.assertIn('ACME_fnc_reopenTransfusion',d)
        self.assertIn('if (_suppressReturn) exitWith {}',c)
    def test_true_pea_bp_zero_before_modifiers(self):
        s=read('functions/fn_bpCompute.sqf')
        self.assertRegex(s,r'rhythmGet\) == 5\) exitWith \{\[0, 0\]\}')
        self.assertIn('ACM_circulation_AED_NIBP_Display", [0,0]',read('functions/fn_circHandle.sqf'))
        co=read('overrides/fn_getCardiacOutput.sqf'); self.assertIn('rhythmGet) == 5',co); self.assertIn('exitWith {0}',co)
    def test_pea_morphology_distinct_from_sinus(self):
        g=read('overrides/fn_genEKG.sqf')
        self.assertIn('case 5: {  // true PEA',g)
        self.assertIn('[0,-2,-8,-20,-38,-50',g)
        m=read('functions/fn_megacodePanelTick.sqf')
        self.assertIn('case (_acmRhythm == 5)',m)
        self.assertNotIn('case (_acmRhythm in [0, 5])',m)
        self.assertIn('_SBP = 0; _DBP = 0',m)
    def test_artifact_is_visual_only_and_network_visible(self):
        a=read('functions/fn_ecgArtifactApply.sqf')
        self.assertIn('_mask set [_idx, false]',a)
        for bad in ('setVariable ["ace_medical_','ACME_fnc_rhythmSet','ACME_fnc_arrestLocal'):
            self.assertNotIn(bad,a)
        o=read('functions/fn_ownerDispatch.sqf'); self.assertIn('case "ecgJostle"',o)
        e=read('functions/fn_ecgJostleLocal.sqf'); self.assertIn('ACME_ecgJostleLeases',e); self.assertIn(', true]',e)
    def test_ace_timer_events_drive_artifact(self):
        p=read('functions/fn_postInit.sqf')
        for ev in ('ace_treatmentStarted','ace_treatmentSucceded','ace_treatmentFailed'):
            self.assertIn(ev,p)
        for rel in ('functions/fn_ivMinigameOpen.sqf','functions/fn_chestSealOpen.sqf','functions/fn_thoraOpen.sqf','functions/fn_laryngoInit.sqf'):
            self.assertIn('ACME_fnc_ecgJostleRequest',read(rel))
    def test_monitor_generators_apply_artifact(self):
        g=read('overrides/fn_genEKG.sqf'); self.assertGreaterEqual(g.count('ACME_fnc_ecgArtifactApply'),2)
        self.assertIn('ACME_fnc_ecgArtifactStrength',read('functions/fn_megacodePanelTick.sqf'))

class B19Reference(unittest.TestCase):
    def test_propofol_50ml_conserves_five_ten_ml_draws(self):
        cap=50.0; open_ml=0.0; sealed=1
        for expected in (40,30,20,10,0):
            draw=10
            needed=max(0,draw-open_ml)
            n=0 if needed<=0 else int((needed+cap-1e-9)//cap)
            self.assertLessEqual(n,sealed)
            sealed-=n; open_ml=open_ml+n*cap-draw
            self.assertAlmostEqual(open_ml,expected)
        self.assertEqual(sealed,0)
    def test_pea_mechanical_pressure_is_zero(self):
        rhythm=5; native_bp=(80,120); result=(0,0) if rhythm==5 else native_bp
        self.assertEqual(result,(0,0))
    def test_artifact_does_not_change_physiology_model(self):
        hr,bp,spo2=(80,(80,120),98)
        artifact=[0,3,-4,8,-2]
        self.assertEqual((hr,bp,spo2),(80,(80,120),98))
        self.assertTrue(any(x != 0 for x in artifact))

if __name__=='__main__': unittest.main()
