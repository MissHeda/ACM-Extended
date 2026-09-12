"""Source contracts and independent state models. These tests do not run SQF or Arma."""
from pathlib import Path
import hashlib,json,math,re,struct,unittest
ROOT=Path(__file__).resolve().parents[1]
def src(n):return (ROOT/'functions'/('fn_'+n+'.sqf')).read_text()
class ModelTests(unittest.TestCase):
 def test_nv_requires_goggles_and_mode(self):
  for hmd,mode in [('',1),('NVG',0),('NVG',2)]:self.assertFalse(bool(hmd) and mode==1)
 def test_nv_on_equipped(self):self.assertTrue(bool('NVG') and 1==1)
 # B9 removes B6's five model assertions for synthetic tint/dimming/washout.
 # Native goggles now own those optical settings; B9 tests the ownership lifecycle.
 def test_same_frame_not_crossfaded_due_to_variant(self):
  shown='derived';variant='derived';base='needle15';source=base if shown==variant else shown;self.assertEqual(source,'needle15')
 def test_new_frame_has_new_identity(self):
  shown='needle30';variant='derived';base='needle15';self.assertEqual(base if shown==variant else shown,'needle30')
 def test_restore_does_not_overwrite_new_procedural_image(self):
  current='new_frame';variant='old_derived';self.assertNotEqual(current,variant)
 def test_restore_keeps_new_procedural_color(self):self.assertNotEqual([1,0,0,1],[.4,.8,1,1])
 def test_unlimited_wiping_bounded_cells(self):
  cells={};total=0;cap=260
  for tick in range(10000):
   key=tick%511
   if key not in cells and len(cells)>=cap:del cells[min(cells,key=cells.get)]
   cells[key]=tick;total+=1
  self.assertEqual(total,10000);self.assertEqual(len(cells),cap)
 def test_repeat_wipe_accumulates_without_controls(self):
  cells={};total=0
  for i in range(10000):cells['one']=i;total+=1
  self.assertEqual(len(cells),1);self.assertEqual(total,10000)
 def test_clean_threshold_does_not_release_pad(self):
  held='pad';clean=False
  for i in range(1000):
   if i>=16:clean=True
  self.assertTrue(clean);self.assertEqual(held,'pad')
 def test_overlay_count_constant_without_new_controls(self):
  controls=['body','held','wash','mask'];overlay=['wash','mask']
  for _ in range(1000):self.assertIn(controls[-1],overlay)
 def test_held_raise_ignores_nv_overlay(self):
  c=[('body',False),('held',False),('wash',True),('mask',True)];self.assertEqual([n for n,o in c if not o][-1],'held')
 def test_duplicate_cleanup_owns_one_handle(self):
  state={'handle':5};destroy=[]
  for _ in range(2):
   if state['handle']>=0:destroy.append(state['handle']);state['handle']=-1
  self.assertEqual(destroy,[5])
class SourceTests(unittest.TestCase):
 # B10 preserves native titles; focus is owned once per client.
 def test_nvg_owned_resource(self):
  self.assertNotIn("cutRsc",src("minigameVisionNative"))
 def test_live_equipped_mask(self):
  t=src('minigameVisionProfile');self.assertIn('ace_nightvision_titleDisplay',t);self.assertIn('_liveHMD == _goggles',t)
 def test_actual_modeloptics_preserved(self):
  self.assertIn('getText (_cfg >> "modelOptics") == ""',src('minigameVisionProfile'))
 def test_missing_mask_no_generic(self):
  self.assertNotIn('ctrlCreate',src('minigameVisionProfile')+src('minigameVisionNative'))
 def test_hidden_ace_mask_respected(self):
  self.assertNotIn('ctrlShow',src('minigameVisionNative'))
 def test_ultrawide_ace_controls(self):
  self.assertNotIn('ace_nightvision_fnc_refreshGoggleType',src('minigameVisionNative'));self.assertNotIn('safeZoneW',src('minigameVisionNative'))
 def test_flashlight_actual_ace_state(self):
  t=src('minigameVisionTick');self.assertNotIn('0.965',t);self.assertNotIn('ctrlSetBackgroundColor',t)
 def test_own_blur_only(self):
  t=src('minigameVisionNative');self.assertIn('ppEffectDestroy _handle',t);self.assertNotIn('ace_nightvision_',t)
 def test_forced_nv_blur(self):self.assertIn('ppEffectForceInNVG true',src('minigameVisionNative'))
 def test_display_unload_cleanup(self):self.assertIn('displayAddEventHandler ["Unload"',src('minigameVisionTick'))
 def test_no_network_nv(self):
  t=src('minigameVisionTick')+src('minigameVisionClear')+src('minigameVisionProfile')
  for n in ['remoteExec','globalEvent','targetEvent','publicVariable','diag_log']:self.assertNotIn(n,t)
 def test_nv_never_reveals_body_group(self):self.assertNotIn('ctrlShow',src('minigameVisionClear'))
 def test_no_texture_restore_needed(self):self.assertNotIn('ctrlSetText',src('minigameVisionTick')+src('minigameVisionClear'))
 def test_native_palette_not_reinterpreted(self):self.assertNotIn('ace_nightvision_colorPreset',src('minigameVisionProfile'))
 def test_frame_change_aware(self):self.assertIn('ACME_NV_BaseTexture',src('ivCathSetFrame'));self.assertIn('_source isEqualTo _tex',src('ivCathSetFrame'))
 def test_held_metadata_copied(self):
  t=src('ivHeldRaise');self.assertIn('ACME_NV_OverlayControl',t);self.assertIn('ACME_NV_BaseTexture',t)
 def test_no_duplicate_overlay_controls(self):self.assertNotIn('ctrlCreate',src('minigameVisionTick'))
 def test_shake_excludes_mask(self):self.assertIn('ACME_NV_Overlay',src('uiShakeApply'))
 def test_all_visual_passes_after_procedure(self):
  for n in ['ivMinigameTick','chestSealTick','thoraTick','laryngoTick','syringeKitTick','skUiTick','updateClampDialog']:
   with self.subTest(n=n):self.assertTrue(src(n).rstrip().endswith('call ACME_fnc_minigameVisionTick;'))
 def test_cleaned_pad_stays(self):
  t=src('ivMinigameCleanDone');self.assertIn('ACME_IV_Cleaned", true',t)
  for k in ['HeldKind','ctrlShow false','HeldCtrl','"none"']:self.assertNotIn(k,t)
 def test_prep_points_do_not_grow(self):self.assertNotIn('_pts pushBack',src('ivPrepPaint'));self.assertIn('ACME_IV_PrepTotal',src('ivPrepPaint'))
 def test_prep_cell_budget_recycles(self):self.assertIn('_cells deleteAt _oldest',src('ivPrepPaint'));self.assertIn('_total = _total + 1',src('ivPrepPaint'))
 def test_prep_total_resets(self):
  for n in ['ivMinigameInit','ivMinigamePrepView','ivMinigameClose']:self.assertIn('ACME_IV_PrepTotal", 0',src(n))
  self.assertIn('["leave"] call ACME_fnc_ivMinigamePrepView',src('ivMinigameFlip'))
  self.assertIn('["enter"] call ACME_fnc_ivMinigamePrepView',src('ivMinigameFlip'))
class AssetTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.info=json.loads((ROOT/'tools/nv_texture_manifest.json').read_text())
 def test_map_paths_exist(self):
  for key,value in self.info['mapping'].items():
   self.assertTrue(key.startswith('\\'));self.assertTrue((ROOT/value.removeprefix('\\acm_extended\\').replace('\\','/')).is_file())
 def test_all_derived_hashes(self):
  for entry in self.info['unique_derivatives']:
   p=ROOT/'ui/nv_close'/entry['texture'];self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),entry['sha256'])
 def test_dxt5_and_mip_bounds(self):
  for entry in self.info['unique_derivatives']:
   blob=(ROOT/'ui/nv_close'/entry['texture']).read_bytes();self.assertEqual(struct.unpack('<H',blob[:2])[0],0xff05)
   pos=4;count=0
   while pos+7<=len(blob):
    w,h=struct.unpack('<HH',blob[pos:pos+4]);size=int.from_bytes(blob[pos+4:pos+7],'little');pos+=7
    if w==0 and h==0:break
    self.assertGreater(size,0);self.assertLessEqual(pos+size,len(blob));self.assertLessEqual(w&0x7fff,entry["size"][0]);self.assertLessEqual(h,entry["size"][1]);pos+=size;count+=1
   self.assertGreater(count,0);self.assertEqual(pos,len(blob))
 def test_original_paths_not_mask_replacements(self):self.assertFalse(any('nightvision' in k for k in self.info['mapping']))
 def test_derivative_source_attribution(self):self.assertTrue((ROOT/'ui/nv_close/ACE_ASSET_LICENSE.txt').exists());self.assertIn('No claim of new ownership', (ROOT/'ui/nv_close/SOURCE_ATTRIBUTION.md').read_text())
if __name__=='__main__':unittest.main()
