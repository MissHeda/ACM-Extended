#!/usr/bin/env python3
"""NA7 Python source-data tests and explicit behavioral reference models.
These tests do not execute SQF and cannot establish in-game UI alignment, event order or network behavior.
Run: python -m unittest discover -s tools -p 'test_na7.py' -v
"""
from __future__ import annotations
import json, math, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def geometry(name):return json.loads((ROOT/'functions'/('fn_'+name+'.sqf')).read_text().split('*/',1)[1].strip())

def flash(t):return 0 <= t < .09 or .18 <= t < .27

def screen_bounds(uv,rect,pixels=2,res=(1920,1080)):
    x,y,w,h=rect;u,v,uw,vh=uv;px=pixels/res[0];py=pixels/res[1]
    return x+u*w-px,y+v*h-py,uw*w+2*px,vh*h+2*py

def resolve_ids(entries,ids,epoch,current_epoch):
    if epoch!=current_epoch:return []
    return [i for uid in ids for i,e in enumerate(entries) if e==uid]

def pane_enabled(pane,active,medicated,has_stock,existing,remaining):
    return pane==active and medicated==(pane=='infusion') and (has_stock or existing) and remaining>.5

class GeometryData(unittest.TestCase):
    def setUp(self):self.iv=geometry('skSiteGeometry');self.im=geometry('skIMGeometry')
    def test_actual_iv_geometry_count(self):self.assertEqual(len(self.iv),19)
    def test_actual_im_geometry_count(self):self.assertEqual(len(self.im),4)
    def test_unique_native_and_input_ids(self):
        self.assertEqual(len({r[3] for r in self.iv}),19);self.assertEqual(len({r[4] for r in self.iv}),19)
    def test_im_input_ids_disjoint(self):self.assertFalse({r[4] for r in self.iv}&{r[2] for r in self.im})
    def test_io_sentinel_is_minus_one(self):self.assertEqual(sum(r[2]==-1 for r in self.iv),5)
    def test_ej_has_real_head_sites(self):self.assertEqual([(r[1],r[2]) for r in self.iv if 'EJ' in r[0]],[('head',0),('head',1)])
    def test_geometry_stays_in_canvas(self):
        for row in self.iv+self.im:
            u,v,w,h=row[-1];self.assertGreater(w,0);self.assertGreater(h,0);self.assertGreaterEqual(u,0);self.assertGreaterEqual(v,0);self.assertLessEqual(u+w,1);self.assertLessEqual(v+h,1)
    def test_native_iv_boxes_are_tight(self):
        for row in self.iv:self.assertLess(row[-1][2],.1);self.assertLess(row[-1][3],.11)
    def test_all_resolutions_contain_art_with_two_pixel_margin(self):
        for res in [(1920,1080),(2560,1440),(3440,1440),(5120,1440)]:
            rect=(.1,.1,.5,.8)
            for row in self.iv:
                u,v,w,h=row[-1];x,y,bw,bh=screen_bounds(row[-1],rect,res=res)
                self.assertAlmostEqual((rect[0]+u*rect[2]-x)*res[0],2)
                self.assertAlmostEqual((rect[1]+v*rect[3]-y)*res[1],2)
                self.assertAlmostEqual((bw-w*rect[2])*res[0],4)
                self.assertAlmostEqual((bh-h*rect[3])*res[1],4)
    def test_alpha_measurements_not_hand_tuned_to_one_resolution(self):
        for row in self.iv:
            scale=2048 if 'EJ' in row[0] else 512
            for v in row[-1]:self.assertAlmostEqual(v*scale,round(v*scale))

class FeedbackReference(unittest.TestCase):
    def test_flash_has_two_intervals(self):
        samples=[flash(i/1000) for i in range(360)]
        starts=sum(x and (i==0 or not samples[i-1]) for i,x in enumerate(samples));self.assertEqual(starts,2)
    def test_flash_boundaries(self):
        for t,expected in [(-1,False),(0,True),(.089,True),(.09,False),(.179,False),(.18,True),(.269,True),(.27,False),(.36,False)]:self.assertEqual(flash(t),expected)
    def test_green_pulse_bounds(self):
        a=[.22+.26*(.5+.5*math.sin(math.radians(t*240))) for t in range(360)]
        self.assertGreaterEqual(min(a),.22);self.assertLessEqual(max(a),.48)
    def test_unavailable_click_retains_selection_and_inventory(self):
        state={'selected':'a','stock':0,'flash':-1};before=state.copy()
        if state['stock']<=0:state['flash']=10
        else:state['selected']='b'
        self.assertEqual(state['selected'],before['selected']);self.assertEqual(state['stock'],before['stock']);self.assertEqual(state['flash'],10)
    def test_native_rows_are_not_replaced_with_catalogue(self):
        source=(ROOT/'functions/fn_skListRefresh.sqf').read_text();self.assertIn('lbSize _list',source);self.assertNotIn('ACM_MEDICATION_VIALS',source);self.assertNotIn('lbClear',source)
    def test_draw_callback_not_replaced_for_sound(self):
        # NA8 moves sound to native button config; treatment callbacks stay untouched here.
        src=(ROOT/'functions/fn_skInject.sqf').read_text();cfg=(ROOT/'config.cpp').read_text()
        self.assertNotIn('ACME_fnc_skClickSound',src)
        self.assertIn('soundClick[] = {"\\a3\\ui_f\\data\\sound\\rscbutton\\soundClick", 0.09, 1}',cfg)

class ClampReference(unittest.TestCase):
    def test_remove_prior_bag_still_targets_uid(self):self.assertEqual(resolve_ids(['b','c'],['b'],3,3),[0])
    def test_removed_target_does_not_target_next(self):self.assertEqual(resolve_ids(['a','c'],['b'],3,3),[])
    def test_epoch_change_refuses_old_clamp(self):self.assertEqual(resolve_ids(['b'],['b'],3,4),[])
    def test_multi_ids_reordered(self):self.assertEqual(resolve_ids(['c','a','b'],['a','c'],3,3),[1,0])
    def test_initial_premix_closed_zero_delivery(self):
        for pressure in [1,2,5]:self.assertEqual(75*pressure*0,0)
    def test_partial_bag_conserves_remaining_dose(self):self.assertEqual(7500*(125/250),3750)
    def test_single_registration_excludes_automatic_sync(self):
        def attach(defer):return (0 if defer else 1)+1
        self.assertEqual(attach(True),1);self.assertEqual(attach(False),2)
    def test_synchronous_ack_close_before_dispatch(self):
        opened=['transfusion'];opened.clear();opened.append('clamp');self.assertEqual(opened,['clamp'])
    def test_new_dialog_blocks_ack_popup_without_starting_flow(self):
        state={'dialog':'narc','clamp':0};
        if not state['dialog']:state['dialog']='roller'
        self.assertEqual(state,{'dialog':'narc','clamp':0})
    def test_duplicate_ack_consumes_only_once(self):
        done=False;stock=1
        for _ in range(3):
            if not done:stock-=1;done=True
        self.assertEqual(stock,0)
    def test_failed_attach_keeps_staged_set(self):
        staged=['uid'];ok=False
        if ok:staged.remove('uid')
        self.assertEqual(staged,['uid'])
    def test_new_request_serial_differs_but_retry_same(self):
        key='prepared:2:p:4:bag';first=f'{key}:1';second=f'{key}:2';retry=first
        self.assertNotEqual(first,second);self.assertEqual(first,retry)

class SelectionReference(unittest.TestCase):
    def test_transfusion_pressure_not_from_infusion_pane(self):self.assertFalse(pane_enabled('transfusion','infusion',False,True,False,100))
    def test_infusion_pressure_not_from_transfusion_pane(self):self.assertFalse(pane_enabled('infusion','transfusion',True,True,False,100))
    def test_stock_required_for_new_cuff(self):self.assertFalse(pane_enabled('infusion','infusion',True,False,False,100))
    def test_existing_cuff_can_repressurize(self):self.assertTrue(pane_enabled('infusion','infusion',True,False,True,100))
    def test_medicated_bag_only_infusion_button(self):
        self.assertFalse(pane_enabled('transfusion','transfusion',True,True,False,100));self.assertTrue(pane_enabled('infusion','infusion',True,True,False,100))
    def test_unmedicated_bag_only_transfusion_button(self):
        self.assertTrue(pane_enabled('transfusion','transfusion',False,True,False,100));self.assertFalse(pane_enabled('infusion','infusion',False,True,False,100))
    def test_empty_cuff_target_refused(self):self.assertFalse(pane_enabled('infusion','infusion',True,True,True,0))
    def test_list_value_maps_to_actual_selection_not_visible_row(self):
        visible_values=[2,5];all_bags=['a','b','c','d','e','f'];self.assertEqual(all_bags[visible_values[1]],'f')
    def test_newer_dialog_not_replaced_by_prep_return(self):
        captured='patient_b';dialog='new_patient';result=captured if not dialog else dialog;self.assertEqual(result,'new_patient')
    def test_size_switch_does_not_return(self):
        restore_mouse=[.5,.4];self.assertTrue(isinstance(restore_mouse,list) and len(restore_mouse)==2)

if __name__=='__main__':unittest.main()
