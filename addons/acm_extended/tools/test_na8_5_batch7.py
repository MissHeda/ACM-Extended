#!/usr/bin/env python3
"""B7 source contracts and independent lifecycle examples. These do not execute SQF."""
from pathlib import Path
from dataclasses import dataclass, replace
from copy import deepcopy
import unittest
from source_scan import lex

ROOT = Path(__file__).resolve().parents[1]
def source(n): return (ROOT/'functions'/f'fn_{n}.sqf').read_text(encoding='utf-8-sig')
def code(n): return [t.value for t in lex(source(n))]

class IVFlipSourceContracts(unittest.TestCase):
    def test_save_before_reset_and_view_change(self):
        s=source('ivMinigameFlip')
        self.assertLess(s.index('[] call ACME_fnc_ivMinigameSaveState'),s.index('[] call ACME_fnc_ivMinigameResetView'))
        self.assertLess(s.index('[] call ACME_fnc_ivMinigameResetView'),s.index('setVariable ["ACME_IV_View", _next]'))
    def test_save_is_unconditional_for_unbanded_stick(self):
        self.assertNotIn('_wasBanded',source('ivMinigameFlip'))
        self.assertEqual(source('ivMinigameFlip').count('[] call ACME_fnc_ivMinigameSaveState'),1)
    def test_flip_does_not_change_physical_band(self):
        for n in ('ivMinigameFlip','ivMinigameResetView','ivMinigameRestoreState'):
            self.assertNotIn('ACME_fnc_ivMinigameBandFlag',code(n))
            self.assertNotIn('ACME_IV_BandOnPart_',source(n))
    def test_destination_geometry_then_restore_then_live_band(self):
        s=source('ivMinigameFlip')
        self.assertLess(s.index('setVariable ["ACME_IV_SnapSites"'),s.index('ACME_fnc_ivMinigameRestoreState'))
        self.assertLess(s.index('ACME_fnc_ivMinigameRestoreState'),s.index('[true] call ACME_fnc_ivMinigameSyncBand'))
    def test_unfinished_site_and_gauge_are_saved(self):
        for key in ('InsSite','InsGauge','InsU','InsV','InsHit','InsProg','InsFrame','InsSuffix','StickAcc','InsEJSide'):
            self.assertIn('"ACME_IV_'+key+'"',source('ivMinigameSaveState'))
    def test_saved_retract_is_resumable_thread(self):
        self.assertIn('if (_stage == "retract") then { _stage = "thread"; _frame = 11; }',source('ivMinigameSaveState'))
    def test_local_journal_precedes_owner_dispatch(self):
        s=source('ivMinigameSaveState')
        self.assertLess(s.index('_cache set [_key, +_entry]'),s.index('call ACME_fnc_ownerDispatch'))
        self.assertIn('_display setVariable ["ACME_IV_ViewCache", _cache]',s)
    def test_restore_prefers_this_display_journal(self):
        s=source('ivMinigameRestoreState')
        self.assertLess(s.index('_patient getVariable ["ACME_IV_SiteState"'),s.index('if (_key in _cache)'))
        self.assertIn('+(_cache get _key)',s)
    def test_cache_deep_copies_payload(self):
        self.assertIn('_cache set [_key, +_entry]',source('ivMinigameSaveState'))
    def test_clear_insertion_drag_pull_and_tool_state(self):
        s=source('ivMinigameResetView')
        for kv in ('["ACME_IV_InsStage", ""]','["ACME_IV_InsPin", []]','["ACME_IV_Dragging", false]',
                   '["ACME_IV_PullIdx", -1]','["ACME_IV_SnapActive", []]','["ACME_IV_Held", "none"]'):
            self.assertIn(kv,s)
    def test_clear_invalidates_callbacks_and_removes_retraction_worker(self):
        s=source('ivMinigameResetView')
        self.assertIn('"ACME_IV_ViewGeneration", 0]) + 1',s)
        self.assertIn('[_retract] call CBA_fnc_removePerFrameHandler',s)
    def test_reset_cancels_crossfade_and_nv_metadata(self):
        s=source('ivMinigameResetView')
        for term in ('ACME_IV_CathGhost','ACME_IV_CathCtrl','ctrlSetTextColor [1,1,1,1]','ACME_NV_Variant','ctrlCommit 0'):
            self.assertIn(term,s)
    def test_restore_makes_catheter_visible_and_opaque(self):
        s=source('ivMinigameRestoreState')
        for term in ('_cath ctrlShow true','_cath ctrlSetTextColor [1,1,1,1]','_cath ctrlSetFade 0','call ACME_fnc_ivCathPose'):
            self.assertIn(term,s)
        self.assertIn("_ctrl ctrlCommit 0",source("ivCathPose"))
    def test_legacy_insertion_fields_have_defaults(self):
        s=source('ivMinigameRestoreState')
        for term in ('["_insSite", ""]','["_accuracy", 0]','["_ejSide", ""]'):
            self.assertIn(term,s)
    def test_restored_gauge_and_accuracy_reach_commit(self):
        s=source('ivMinigameRestoreState')
        self.assertIn('setVariable ["ACME_IV_Gauge", _gauge]',s)
        self.assertIn('setVariable ["ACME_IV_StickAcc", _accuracy]',s)
        for n in ('ivMinigameRegister','ivMinigameStickSuccess'):
            self.assertNotIn('getVariable ["ACME_IV_Gauge"',source(n))
            self.assertIn('getVariable ["ACME_IV_InsGauge"',source(n))
    def test_ej_side_frozen_at_puncture(self):
        self.assertIn('setVariable ["ACME_IV_InsEJSide"',source('ivMinigameInsertStart'))
        self.assertIn('getVariable ["ACME_IV_InsEJSide"',source('ivMinigameStickSuccess'))
    def test_tray_cannot_change_an_inserted_catheter(self):
        for n in ('ivMinigameGrabBand','ivMinigameGrabNeedle','ivMinigameGrabPad'):
            s=source(n)
            self.assertLess(s.index('in ["advance", "thread", "retract"]'),s.index('setVariable ["ACME_IV_Held"'))
    def test_callback_validity_has_all_scopes(self):
        s=source('ivMinigameViewValid')
        for term in ('ACME_IV_DLG','ACME_fnc_ivUiValid','ACME_IV_ViewGeneration','ACME_IV_BodyPart','ACME_IV_View'):
            self.assertIn(term,s)
    def test_retraction_checks_context_before_touching_sprite(self):
        s=source('ivMinigameRetract')
        self.assertLess(s.index('call ACME_fnc_ivMinigameViewValid'),s.index('getVariable ["ACME_IV_CathCtrl"'))
        self.assertIn('[12, _context]',s)
        self.assertIn('_dlg0 setVariable ["ACME_IV_RetractPFH", _handler]',s)
    def test_final_commit_checks_same_context_and_stage(self):
        s=source('ivMinigameStickSuccess')
        self.assertLess(s.index('call ACME_fnc_ivMinigameViewValid'),s.index('call ACME_fnc_ivMinigameRegister'))
        self.assertIn('getVariable ["ACME_IV_InsStage", ""]) != "retract"',s)
        self.assertIn('[_frame, _context], 0.15',s)
    def test_close_saves_before_canceling_and_clearing_art(self):
        s=source('ivMinigameClose')
        self.assertLess(s.index('call ACME_fnc_ivMinigameSaveState'),s.index('call ACME_fnc_ivMinigameResetView'))
        self.assertIn('["clear"] call ACME_fnc_ivMinigamePrepView',s)
    def test_init_clears_input_before_restoring(self):
        s=source('ivMinigameInit');self.assertLess(s.index('call ACME_fnc_ivMinigameResetView'),s.index('call ACME_fnc_ivMinigameRestoreState'))
    def test_band_pending_retains_operation_geometry(self):
        self.assertIn('diag_tickTime + 5, _index, _on, _view, +_band',source('ivMinigameBandFlag'))
    def test_band_pending_survives_forced_view_redraw(self):
        s=source('ivMinigameSyncBand')
        self.assertIn('if (_waiting && {count _pending == 6}',s)
        self.assertIn('_state = [_revision, _on, _bandView, _band]',s)
    def test_band_reader_still_has_no_network_write(self):
        s=source('ivMinigameSyncBand')
        for token in ('ownerDispatch','setVarNet','remoteExec','_patient setVariable'):
            self.assertNotIn(token,s)
    def test_prep_stored_before_flip_and_restored_after_it(self):
        s=source('ivMinigameFlip')
        self.assertLess(s.index('["leave"] call'),s.index('setVariable ["ACME_IV_View", _next]'))
        self.assertGreater(s.index('["enter"] call'),s.index('setVariable ["ACME_IV_View", _next]'))
    def test_local_prep_retains_cells_count_sum_and_age(self):
        s=source('ivMinigamePrepView')
        for term in ('ACME_IV_PrepCells','ACME_IV_PrepCtrls','ACME_IV_PrepTotal','ACME_IV_PrepSum','ACME_IV_PrepBruise','diag_tickTime'):
            self.assertIn(term,s)
    def test_prep_does_not_publish_handles_or_local_clock(self):
        for term in ('ownerDispatch','setVarNet','remoteExec'):
            self.assertNotIn(term,source('ivMinigamePrepView'))
        for term in ('ACME_IV_PrepCtrls','ACME_IV_PrepCells','diag_tickTime'):
            self.assertNotIn(term,source('ivMinigameSaveState'))
    def test_nv_pass_follows_restoration(self):
        s=source('ivMinigameFlip');self.assertLess(s.index('call ACME_fnc_ivMinigameRestoreState'),s.index('call ACME_fnc_minigameVisionTick'))
    def test_no_new_debug_output(self):
        for n in ('ivMinigameFlip','ivMinigameSaveState','ivMinigameRestoreState','ivMinigameResetView','ivMinigameViewValid','ivMinigamePrepView','ivMinigameRetract','ivMinigameStickSuccess'):
            for command in ('diag_log','systemChat','hint','hintSilent'):
                self.assertNotIn(command,code(n))
    def test_observing_loaded_view_does_not_publish(self):
        for n in ('ivMinigameInit','ivMinigameFlip'):
            self.assertIn('[false] call ACME_fnc_ivMinigameSaveState',source(n))
    def test_unchanged_snapshot_does_not_publish(self):
        s=source('ivMinigameSaveState')
        self.assertIn('if (!_publish || {!_changed}) exitWith {}',s)
        self.assertLess(s.index('if (!_publish || {!_changed})'),s.index('call ACME_fnc_ownerDispatch'))
    def test_idle_tray_gauge_is_not_patient_state(self):
        self.assertIn('if (_stage == "") then {_ins = ["",0,"",16,0.5,0.5,false,0,"",0,"",0];}',source('ivMinigameSaveState'))
    def test_new_helpers_registered_once(self):
        c=(ROOT/'config.cpp').read_text()
        for name in ('ivMinigameResetView','ivMinigameViewValid','ivMinigamePrepView'):
            self.assertEqual(c.count('class '+name+' {};'),1)

@dataclass
class Insertion:
    stage: str=''
    frame: int=0
    gauge: int=16
    site: str='middle'
    u: float=.49
    v: float=.44
    hit: bool=True
    accuracy: float=.16
    progress: float=.3
    angle: str='_15_left'
    ej: str=''

class Lifecycle:
    """Small independent state machine to exercise the proposed invariants; not an SQF VM."""
    def __init__(self):
        self.view='front';self.body='leftarm';self.session=1;self.epoch=1;self.generation=0
        self.active=Insertion();self.cache={};self.owner_rows={};self.pending=[]
        self.band=(True,'front');self.input_drag=False;self.sprite=False;self.pull=-1
        self.commits=[];self.prep={'front':{'count':0,'cells':{},'sum':(0.,0.)}}
    def token(self):return (self.session,self.epoch,self.generation,self.body,self.view)
    def valid(self,token):return self.token()==token
    def save(self):
        s=deepcopy(self.active)
        if s.stage=='retract':s=replace(s,stage='thread',frame=11)
        self.cache[self.view]=s;self.pending.append((self.view,deepcopy(s)))
    def flip(self):
        self.save();self.generation+=1;self.active=Insertion();self.input_drag=False;self.pull=-1;self.sprite=False
        self.view='rear' if self.view=='front' else 'front'
        self.active=deepcopy(self.cache.get(self.view,self.owner_rows.get(self.view,Insertion())))
        self.sprite=self.active.stage in ('advance','thread')
        self.prep.setdefault(self.view,{'count':0,'cells':{},'sum':(0.,0.)})
    def final_callback(self,token):
        if not self.valid(token) or self.active.stage!='retract':return False
        self.commits.append((self.body,self.view,self.active.site,self.active.gauge))
        self.active=Insertion();self.sprite=False;self.save();return True
    def band_visible(self):return self.band==(True,self.view)

class LifecycleExamples(unittest.TestCase):
    def setUp(self):self.ui=Lifecycle()
    def round_trip(self,ins):
        self.ui.active=ins;self.ui.sprite=True;self.ui.flip();self.assertFalse(self.ui.sprite);self.assertEqual(self.ui.active.stage,'')
        self.ui.flip();return self.ui.active
    def test_advance_round_trip(self):self.assertEqual(self.round_trip(Insertion(stage='advance',frame=3)),Insertion(stage='advance',frame=3))
    def test_thread_partial_round_trip(self):self.assertEqual(self.round_trip(Insertion(stage='thread',frame=8)),Insertion(stage='thread',frame=8))
    def test_hubbed_round_trip(self):self.assertEqual(self.round_trip(Insertion(stage='thread',frame=11)).frame,11)
    def test_separation_restores_threaded_without_commit(self):
        r=self.round_trip(Insertion(stage='retract',frame=12));self.assertEqual((r.stage,r.frame),('thread',11));self.assertEqual(self.ui.commits,[])
    def test_unbanded_partial_round_trip(self):
        self.ui.band=(False,'front');r=self.round_trip(Insertion(stage='advance',frame=2));self.assertEqual(r.frame,2);self.assertFalse(self.ui.band_visible())
    def test_miss_is_not_rerolled(self):self.assertFalse(self.round_trip(Insertion(stage='advance',hit=False,accuracy=1)).hit)
    def test_accuracy_survives(self):self.assertEqual(self.round_trip(Insertion(stage='thread',accuracy=.73)).accuracy,.73)
    def test_all_gauges_survive(self):
        for gauge in (14,16,18,20):
            with self.subTest(gauge=gauge):self.assertEqual(self.round_trip(Insertion(stage='advance',gauge=gauge)).gauge,gauge)
    def test_original_puncture_site_survives(self):self.assertEqual(self.round_trip(Insertion(stage='thread',site='lower')).site,'lower')
    def test_pointer_and_pull_do_not_survive_flip(self):
        self.ui.input_drag=True;self.ui.pull=4;self.ui.flip();self.assertFalse(self.ui.input_drag);self.assertEqual(self.ui.pull,-1)
    def test_band_stays_physically_on_limb(self):
        self.ui.flip();self.assertEqual(self.ui.band,(True,'front'));self.assertFalse(self.ui.band_visible());self.ui.flip();self.assertTrue(self.ui.band_visible())
    def test_remote_band_removal_wins_on_return(self):
        self.ui.flip();self.ui.band=(False,'front');self.ui.flip();self.assertFalse(self.ui.band_visible())
    def test_remote_reposition_uses_new_face(self):
        self.ui.flip();self.ui.band=(True,'rear');self.ui.flip();self.assertFalse(self.ui.band_visible());self.ui.flip();self.assertTrue(self.ui.band_visible())
    def test_owner_reply_not_required_for_immediate_return(self):
        self.ui.active=Insertion(stage='thread',frame=9);self.ui.owner_rows={};self.ui.flip();self.ui.flip();self.assertEqual(self.ui.active.frame,9)
    def test_owner_snapshot_does_not_alias_journal(self):
        self.ui.active=Insertion(stage='advance',frame=2);self.ui.save();self.ui.pending[-1][1].frame=5
        self.assertEqual(self.ui.cache['front'].frame,2)
    def test_opposite_faces_keep_independent_progress(self):
        self.ui.active=Insertion(stage='advance',frame=2,gauge=20);self.ui.flip();self.ui.active=Insertion(stage='thread',frame=9,gauge=14)
        self.ui.flip();self.assertEqual((self.ui.active.frame,self.ui.active.gauge),(2,20));self.ui.flip();self.assertEqual((self.ui.active.frame,self.ui.active.gauge),(9,14))
    def test_stale_callback_rejected_on_other_face(self):
        self.ui.active=Insertion(stage='retract');t=self.ui.token();self.ui.flip();self.assertFalse(self.ui.final_callback(t))
    def test_stale_callback_rejected_after_round_trip(self):
        self.ui.active=Insertion(stage='retract');t=self.ui.token();self.ui.flip();self.ui.flip();self.ui.active.stage='retract';self.assertFalse(self.ui.final_callback(t))
    def test_other_patient_session_rejected(self):
        self.ui.active=Insertion(stage='retract');t=self.ui.token();self.ui.session+=1;self.assertFalse(self.ui.final_callback(t))
    def test_full_heal_epoch_rejected(self):
        self.ui.active=Insertion(stage='retract');t=self.ui.token();self.ui.epoch+=1;self.assertFalse(self.ui.final_callback(t))
    def test_other_limb_rejected(self):
        self.ui.active=Insertion(stage='retract');t=self.ui.token();self.ui.body='rightleg';self.assertFalse(self.ui.final_callback(t))
    def test_finish_consumes_one_and_keeps_original_gauge(self):
        self.ui.active=Insertion(stage='retract',gauge=20,site='lower');t=self.ui.token();self.assertTrue(self.ui.final_callback(t));self.assertFalse(self.ui.final_callback(t))
        self.assertEqual(self.ui.commits,[('leftarm','front','lower',20)])
    def test_completed_catheter_does_not_restore_partial(self):
        self.ui.active=Insertion(stage='retract');self.ui.final_callback(self.ui.token());self.ui.flip();self.ui.flip();self.assertEqual(self.ui.active.stage,'')
    def test_many_flips_keep_bounded_view_journal(self):
        self.ui.active=Insertion(stage='thread',frame=10)
        for _ in range(100):self.ui.flip()
        self.assertEqual(len(self.ui.cache),2);self.assertEqual(self.ui.active.frame,10)
    def test_prep_count_cells_and_sums_stay_on_face(self):
        self.ui.prep['front']={'count':100,'cells':{'one':(9,0.4)},'sum':(40.,40.)}
        self.ui.flip();self.assertEqual(self.ui.prep['rear']['count'],0);self.ui.flip()
        self.assertEqual(self.ui.prep['front']['count'],100);self.assertEqual(len(self.ui.prep['front']['cells']),1)
    def test_original_bug_counterexample(self):
        self.ui.active=Insertion(stage='thread',frame=8);self.ui.sprite=False # B6 hid art without clearing stage
        self.assertTrue(self.ui.active.stage in ('advance','thread','retract') and not self.ui.sprite)
        self.ui.flip();self.ui.flip();self.assertTrue(self.ui.sprite)

class BandAcknowledgementExamples(unittest.TestCase):
    @staticmethod
    def state(owner,pending,now,index=2):
        if len(pending)==6 and owner[0]<=pending[0] and now<pending[1] and pending[2]==index:
            return owner[0],pending[3],pending[4],pending[5]
        return owner
    def test_apply_is_visible_before_ack(self):
        self.assertEqual(self.state((0,False,'',[]),(0,5,2,True,'front',['band']),1)[1:3],(True,'front'))
    def test_forced_redraw_does_not_erase_pending_geometry(self):
        p=(0,5,2,True,'front',['band']);s=self.state((0,False,'',[]),p,1)
        self.assertEqual(s[2:4],('front',['band']))
    def test_newer_owner_removal_wins(self):
        s=self.state((2,False,'front',[]),(0,5,2,True,'front',['band']),1);self.assertFalse(s[1])
    def test_expired_request_uses_owner(self):
        s=self.state((0,False,'',[]),(0,5,2,True,'front',['band']),6);self.assertFalse(s[1])
    def test_other_limb_does_not_use_pending(self):
        s=self.state((0,False,'',[]),(0,5,2,True,'front',['band']),1,index=3);self.assertFalse(s[1])
    def test_pending_removal_hides_band(self):
        s=self.state((2,True,'front',['band']),(2,5,2,False,'front',['band']),1);self.assertFalse(s[1])

if __name__=='__main__':unittest.main()
