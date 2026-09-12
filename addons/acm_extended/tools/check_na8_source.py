#!/usr/bin/env python3
"""NA8 static source contracts and optional byte-preservation checks. Does not compile/execute SQF."""
from __future__ import annotations
import argparse, hashlib, json, re, xml.etree.ElementTree as ET
from pathlib import Path
from source_scan import lex, matching
from tagcheck import parse_config

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(root:Path,baseline:Path|None=None,version:str="0.9.999r-73-NA8"):
    rows=[]
    def check(name,ok,detail=''):rows.append(dict(name=name,passed=bool(ok),detail=detail))
    def read(p):return (root/p).read_text(encoding='utf-8-sig')
    def fn(n):return read('functions/fn_'+n+'.sqf')
    cfg=read('config.cpp');post=fn('postInit');renderer=read('overrides/fn_updateActions.sqf');collector=read('overrides/fn_collectActions.sqf');policy=fn('menuActionInfo');body=fn('skUpdateBody');hot=fn('skBuildHotspots');inject=fn('skInject');tick=fn('skUiTick')
    check('versions_agree_expected',f'version = "{version}";' in cfg and f'ACME_infusion_version = "{version}";' in post)
    regs=parse_config(root/'config.cpp');names=[r['resolved'].lower() for r in regs]
    check('unique_resolved_functions',len(names)==len(set(names)))
    for name,file in [('ace_medical_gui_fnc_collectActions',r'\acm_extended\overrides\fn_collectActions.sqf'),('ACME_native_fnc_collectActions',r'\x\ACM\addons\gui\overrides\fnc_collectActions.sqf'),('ACME_fnc_skUpdateBody',r'\acm_extended\functions\fn_skUpdateBody.sqf'),('ACME_fnc_menuActionInfo',r'\acm_extended\functions\fn_menuActionInfo.sqf')]:
        check('binding_'+name,any(r['resolved'].lower()==name.lower() and r['file']==file for r in regs))
    check('collector_delegates_before_read',collector.index('call ACME_native_fnc_collectActions')<collector.index('private _actions'))
    check('collector_checks_native_prefix','_prefixValid' in collector and '_row param [0, ""]' in collector and '_row param [1, ""]' in collector and 'if (!_prefixValid) exitWith' in collector)
    check('collector_does_not_recompile_treatments','compile format' not in collector and '_row = +(_actions select _forEachIndex)' in collector)
    check('collector_retains_native_extra_rows','_mapped append (_actions select [count _configs])' in collector)
    check('collector_reorders_iv_before_narc','ace_medical_gui_actions = _iv + _narc + _rest;' in collector)
    check('collector_has_stable_identity','_row set [8, configName _x]' in collector and '_row set [9, _bucket]' in collector)
    check('collector_does_not_filter_by_live_condition','call _condition' not in collector)
    check('native_draw_actions_only_family_hidden','"usesyringe_10" in _lineage' in policy and policy.index('"usesyringe_10"')<policy.index('"opentransfusionmenu"'))
    check('iv_gated_to_original_advanced','(_category == "advanced")' in policy)
    check('iv_io_ej_and_legacy_fluids_classified',all('"'+s+'"' in policy for s in ['insertiv_16_upper','removeiv_16_upper','insertio_fast1','removeio_fast1','opentransfusionmenu','bloodiv','acme_place18g_upper','acme_ivminigamestart','acme_establishej','acme_removeej']))
    check('suction_roots_move_together',all('"'+s+'"' in policy for s in ['usesuctionbag','drainfluid_accuvac','acme_drainfluid_accuvac']))
    check('check_airway_and_breathing_classified','_name == "checkairway"' in policy and '_name == "checkbreathing"' in policy)
    check('route_order_specific_before_general',policy.index('if ("fentanyllozenge"')<policy.index('if ((_lineage findIf {_x in ["penthrox"')<policy.index('if ((_lineage findIf {_x in ["paracetamol"'))
    check('all_native_routes_retained',all('"'+s+'"' in policy for s in ['fentanyllozenge','penthrox','ammoniainhalant','naloxone','paracetamol','painkillers']))
    check('unknown_action_retained',policy.rstrip().endswith('[_category, "", false]'))
    check('category_label_shared_config','class ACE_Medical_Menu {' in cfg and 'class Medication: Triage {' in cfg and 'tooltip = "IV / Medication";' in cfg)
    check('category_internal_id_unchanged', 'selectedCategory = "IV / Medication"' not in renderer and '["medication", "iv_access", false]' in policy)
    check('iv_done_returns_medication','selectedCategory = "advanced"' not in fn('ivMinigameDone') and fn('ivMinigameDone').count('selectedCategory = "medication"')==2)
    check('group_labels_renamed','["adjuncts", "Airway", "airway"' in post and '["ventilation", "Breathing", "airway"' in post and '["suction", "Suction"' not in post)
    check('route_groups_only_head',post.count('{ace_medical_gui_selectedBodyPart == 0}')==3)
    check('grouping_checkbox_is_sole_gate','if (_nestEnabled) then {' in renderer and 'if (_leftAlign && {_nestEnabled})' not in renderer)
    check('grouping_effective_alignment','_leftAlign = _leftAlign || {_nestEnabled};' in renderer)
    check('both_route_label_sets',all(s in renderer for s in ["['By Mouth', 'PO']","['Inhaled', 'IN']","['Buccal', 'BUC']"]))
    check('resolved_descriptor_setting','missionNamespace getVariable ["ACME_hc_descriptors", false]' in renderer and 'ACME_hcEff_descriptors' not in renderer)
    check('group_metadata_precedes_name_fallback',renderer.index('_key = _x param [9')<renderer.index('_nameKeys getOrDefault'))
    check('one_group_condition_evaluation','if (call _condition) then {(_buckets get _key) pushBack _x;};' in renderer)
    check('children_keep_statement_and_items',"_child = +_x" in renderer and "_child set [2, {true}]" in renderer and '_child set [3' not in renderer)
    check('display_scoped_open_state_preserved',all(s in renderer for s in ['ACME_menuTarget','ACME_menuOpen','ACME_menuButtons','ACME_menuButtonGroup','ACME_menuRowTarget']))
    check('no_frame_gap_group_reset','diag_frameNo' not in renderer)
    check('header_does_not_set_pending_reopen','pendingReopen' not in renderer[renderer.index('_out pushBack ['):renderer.index('private _shownIndex')])
    check('only_setting_presentation_changed','(needs left-align)' not in read('XEH_settings.hpp') and 'Group medical menu into dropdowns"' in read('XEH_settings.hpp'))
    check('body_group_show_only_on_transition','if (_show != _wasShown)' in body and body.count('_group ctrlShow')==1)
    check('body_masks_follow_group_show',body.index('_group ctrlShow')<body.index('call ace_medical_gui_fnc_updateBodyImage'))
    check('only_anatomy_survives_first_reveal','[6005,6010,6015,6020,6025,6030]' in body and 'ctrlClassName' in body)
    check('captured_patient_not_global_gui_target','ACME_SK_ReturnPatient' in body and 'ace_medical_gui_target' not in body)
    check('body_refresh_rate_unchanged','_now + 0.1' in body)
    check('no_group_reveal_in_hotspot_builder','_group ctrlShow' not in hot)
    check('hotspot_builder_updates_before_tint',hot.index('call ACME_fnc_skUpdateBody')<hot.index('_image ctrlSetTextColor'))
    check('hotspot_requires_visible_actual_access','{_have}' in hot and '{ctrlShown _image}' in hot)
    check('only_vascular_and_im_geometry_used','ACME_fnc_skSiteGeometry' in hot and 'ACME_fnc_skIMGeometry' in hot and 'ACME_fnc_skSiteGeometry' in inject)
    check('native_art_hidden_after_prewarm',inject.index('_bodyGroup ctrlShow false;',inject.index('call ace_medical_gui_fnc_updateBodyImage'))>0)
    check('save_uses_draw_width_height','_saveRect set [2, _drawRect select 2];' in inject and '_saveRect set [3, _drawRect select 3];' in inject)
    check('save_uses_original_right_slot','_saveRect = +(ctrlPosition (_display displayCtrl 84005))' in inject)
    sounds=cfg[cfg.index('class ACM_circulation_SyringeDraw_Dialog {'):cfg.index('// static overlay label,')]
    check('button_original_bases_preserved',all(s in sounds for s in ['class Button_Draw: RscButton','class Button_Inject: Button_Draw','class Button_Push: Button_Inject']))
    check('three_buttons_explicit_click_sound',sounds.count('soundClick[] = {"\\a3\\ui_f\\data\\sound\\rscbutton\\soundClick", 0.09, 1};')==3)
    check('all_four_native_sound_events',all(sounds.count('sound'+v+'[] = ')==3 for v in ['Click','Enter','Push','Escape']))
    check('sound_patch_no_idc_or_callback_replacement','idc =' not in sounds and 'onButtonClick' not in sounds and 'action =' not in sounds)
    check('no_duplicate_runtime_sound_hook','ACME_fnc_skClickSound' not in inject)
    check('no_network_added_to_ui','remoteExec' not in body+hot+collector+policy and 'CBA_fnc_globalEvent' not in body+hot+collector+policy)
    check('stock_feedback_cadence_preserved','0.04' in inject and '0.09' in tick and '0.27' in tick and '0.36' in tick)
    check('two_pixel_hotspot_margin_retained','2 * pixelW' in hot and '4 * pixelW' in hot)
    check('native_callbacks_use_original_categories', 'callbackSuccess' not in collector and 'allowedSelections' not in collector)
    # Lexer screening is structural only, including edited quoted/config source.
    touched=['config.cpp','XEH_settings.hpp','functions/fn_postInit.sqf','functions/fn_skInject.sqf','functions/fn_skBuildHotspots.sqf','functions/fn_skUiTick.sqf','functions/fn_skUpdateBody.sqf','functions/fn_menuActionInfo.sqf','functions/fn_ivMinigameDone.sqf','overrides/fn_collectActions.sqf','overrides/fn_updateActions.sqf']
    unbalanced=[];commas=[];paths=[]
    for rel in touched:
        text=read(rel);ts=lex(text);pairs=matching(ts)
        if any(t.kind=='symbol' and t.value in '[]{}()' and i not in pairs for i,t in enumerate(ts)):unbalanced.append(rel)
        if any(a.value==',' and b.value in {']','}'} for a,b in zip(ts,ts[1:])):commas.append(rel)
        if '\\\\' in text:paths.append(rel)
    check('touched_structures_balanced',not unbalanced,repr(unbalanced));check('no_trailing_array_comma',not commas,repr(commas));check('no_doubled_slashes',not paths,repr(paths))
    try:ET.parse(root/'stringtable.xml');xml_ok=True
    except ET.ParseError:xml_ok=False
    check('stringtable_parses',xml_ok)
    if baseline:
        media=[p for p in baseline.rglob('*') if p.is_file() and p.suffix.lower() in {'.paa','.ogg','.wav','.wss','.p3d','.rtm'}]
        check('all_binary_assets_identical',all((root/p.relative_to(baseline)).is_file() and sha(p)==sha(root/p.relative_to(baseline)) for p in media),str(len(media)))
        chest=list((baseline/'functions').glob('fn_chestSeal*.sqf'));check('all_chest_seal_files_identical',all(sha(p)==sha(root/p.relative_to(baseline)) for p in chest),str(len(chest)))
        check('sk_geometry_identical',all(sha(root/f'functions/fn_{n}.sqf')==sha(baseline/f'functions/fn_{n}.sqf') for n in ['skSiteGeometry','skIMGeometry']))
        clinical=[p for p in (baseline/'overrides').glob('*.sqf') if p.name!='fn_updateActions.sqf']
        check('existing_non_menu_overrides_identical',all(sha(p)==sha(root/p.relative_to(baseline)) for p in clinical),str(len(clinical)))
        check('clinical_settings_unchanged',sha(root/'XEH_preInit.sqf')==sha(baseline/'XEH_preInit.sqf'))
        old_cfg=(baseline/'config.cpp').read_text()
        old_renderer=(baseline/'overrides/fn_updateActions.sqf').read_text()
        action_marker='class ace_medical_treatment_actions {'
        render_marker='private _shownIndex = 0;'
        fracture_block = '    // NA8: preserve ACM\'s action and replace only its completed assessment callback.\n    // ACM core/ACE_Medical_Treatment_Actions.hpp:217-228 defines its parent and conditions.\n    class InspectForFracture: CheckPulse {\n        callbackSuccess = "ACME_fnc_inspectForFracture";\n    };\n\n'
        action_tail = cfg[cfg.index(action_marker):]
        check('clinical_actions_only_fracture_callback_changed', action_tail.count(fracture_block)==1 and action_tail.replace(fracture_block, '', 1)==old_cfg[old_cfg.index(action_marker):])
        check('stable_action_render_tail_identical',renderer[renderer.index(render_marker):]==old_renderer[old_renderer.index(render_marker):])
        check('no_original_files_removed',all((root/p.relative_to(baseline)).is_file() for p in baseline.rglob('*') if p.is_file()))
    return {'scope':__doc__,'passed':sum(x['passed'] for x in rows),'total':len(rows),'checks':rows}
if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('addon',type=Path);ap.add_argument('--baseline',type=Path);ap.add_argument('--json',type=Path);ap.add_argument('--version',default='0.9.999r-73-NA8');a=ap.parse_args();r=run(a.addon,a.baseline,a.version)
    for c in r['checks']:
        if not c['passed']:print('FAIL',c['name'],c['detail'])
    print(f"Static checks: {r['passed']}/{r['total']}")
    if a.json:a.json.write_text(json.dumps(r,indent=2)+'\n')
    raise SystemExit(0 if r['passed']==r['total'] else 1)
