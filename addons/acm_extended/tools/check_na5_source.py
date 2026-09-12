#!/usr/bin/env python3
"""NA5 static contracts and asset comparison. This does not compile or execute SQF."""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import val
from source_scan import lex, source_files, matching, split_args

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(root:Path,baseline:Path):
    checks=[]
    def check(name,ok,detail=''):checks.append(dict(name=name,passed=bool(ok),detail=detail))
    def text(name):return (root/name).read_text(encoding='utf-8-sig')
    files=source_files(root);sqf=[p for p in files if p.suffix.lower()=='.sqf']
    errors=[e for p in sqf for e in val.check(str(p))]
    check('all_SQF_structural_screen',not errors,dict(files=len(sqf),errors=errors))
    config_errors=[e for p in files if p.suffix.lower() in {'.cpp','.hpp'} for e in val.check(str(p))]
    check('config_header_structural_screen',not config_errors,config_errors)
    check('strict_UTF8_source_decode',all(p.read_bytes().decode('utf-8-sig') is not None for p in files))
    double=[str(p.relative_to(root)) for p in files if '\\\\' in p.read_text(encoding='utf-8-sig')]
    check('no_doubled_path_backslashes',not double,double)
    ET.parse(root/'stringtable.xml');check('stringtable_parses',True)
    cfg=text('config.cpp');post=text('functions/fn_postInit.sqf')
    version=re.search(r'\bversion\s*=\s*"([^"]+)"',cfg).group(1)
    check('version_strings_match_NA5',version=='0.9.999r-73-NA5' and f'ACME_infusion_version = "{version}"' in post)
    check('version_stays_below_1',version.startswith('0.9.999'))
    names=[t.value for t in lex(text('functions/fn_clinicalFields.sqf')) if t.kind=='string' and t.value.startswith('ACME_')]
    counts=Counter(n.lower() for n in names)
    check('clinical_schema_unique_case_insensitive_names',all(v==1 for v in counts.values()),[k for k,v in counts.items() if v>1])
    check('new_state_in_reset_schema',all(x in names for x in ['ACME_piCuffs','ACME_do2_dilution','ACME_airwayGrade','ACME_airwayTraumaBump']))
    check('receipt_ledger_not_cleared_as_patient_state','ACME_piReceipts' not in names)
    check('new_anchors_clock_encoded',all(x in text('functions/fn_clinicalSnapshot.sqf') for x in ['ACME_piCuffs','ACME_do2_dilution','"cba"']))
    check('new_collections_validated',all('case "'+x+'"' in text('functions/fn_clinicalValidate.sqf') for x in ['ACME_piCuffs','ACME_do2_dilution']))
    oxygen=text('functions/fn_oxygenDelivery.sqf')
    check('oxygen_uses_declared_patient','_patient' not in [t.value for t in lex(oxygen)])
    check('oxygen_uses_native_active_BVM','call ACM_core_fnc_bvmActive' in oxygen and 'ACME_bvm_inProgress' not in oxygen)
    check('dilution_publication_only_actual_change','_saline != _previousActual' in oxygen and 'local _unit' in oxygen)
    check('dilution_analytic_anchor','_previousActual' in oxygen and '_previousEffective' in oxygen)
    airway=text('functions/fn_airwayGrade.sqf')
    check('airway_actual_ACM_fields',all(x in airway for x in ['ACM_airway_AirwayCollapse_State','ACM_airway_AirwayObstructionVomit_State','ACM_airway_AirwayObstructionBlood_State']))
    check('airway_removed_nonexistent_ACM_fields',all(x not in airway for x in ['"ACM_airway_Occluded"','"ACM_airway_Blood"']))
    burn=text('functions/fn_airwayHasFacialBurn.sqf')
    check('head_burn_uses_native_table','ace_medical_damage_woundClassNames' in burn and 'getOrDefault ["head"' in burn and 'floor (_id / 10)' in burn)
    check('burn_query_no_publisher','setVariable' not in burn and 'setVarNet' not in burn)
    check('reflex_boolean_consumer','&& {_patient getVariable ["ACM_airway_AirwayReflex_State", false]}' in text('functions/fn_laryngoFail.sqf'))
    check('attempt_grade_UI_initialized',all(f'uiNamespace setVariable ["ACME_laryngo_{x}"' in text('functions/fn_laryngoInit.sqf') for x in ['mp','cl']))
    check('fresh_blood_uses_native_threshold','ACM_circulation_IV_Bags_FreshBloodEffect' in text('functions/fn_salineAcidosisTrack.sqf') and '> 0.83' in text('functions/fn_salineAcidosisTrack.sqf'))
    check('vent_battery_real_fields',all(x in text('functions/fn_ventBatteryTick.sqf') for x in ['ACME_vent_measRR','ACME_vent_bpm','ACME_vent_pip']))
    check('vent_prompt_local_only',all(x not in text('functions/fn_ventTechPrompt.sqf') for x in ['remoteExec','targetEvent','globalEvent','setVarNet']))
    check('vent_grant_bound_to_patient_code',all(x in text('functions/fn_ventItemGate.sqf') for x in ['ACME_vent_techAuthCode','ACME_vent_techAuthTarget']))
    check('vent_service_stub_still_disclosed','display-only in this build' in text('functions/fn_ventPanelNavClick.sqf'))
    check('unused_HR_ROSC_delegates_removed',all(x not in cfg+post for x in ['ACME_orig_updateHeartRate','ACME_orig_updateCirculationState','ACME_native_fnc_updateHeartRate','ACME_native_fnc_updateCirculationState']))
    for name in ['getEtCO2','onCardiacArrest','onUnconscious']:
        check('retained_delegate_'+name,('class '+name+' ') in cfg or ('class '+name+'{') in cfg)
    rr=text('overrides/fn_updateRespirationRate.sqf')
    check('RR_reads_native_target_directly','ACME_rrRestBaseline' not in rr and 'private _base = _unit getVariable ["ACM_core_TargetVitals_RespirationRate", 18];' in rr)
    threshold=text('functions/fn_rhythmThresholdTick.sqf')
    check('threshold_release_no_saved_target','getVariable ["ACME_rhythm_savedTargetHR"' not in threshold)
    check('threshold_release_no_tachy_feedback','["ACM_core_TargetVitals_HeartRate", _hr]' not in threshold)
    check('cuff_complete_context','["_patient", "_part", "_index", "_type", "_accessType", "_site", "_iv"' in text('functions/fn_pressureInfuserAttach.sqf'))
    check('cuff_no_preparation_tally','ACME_infusion_bagTally' not in text('functions/fn_pressureInfuserAttach.sqf'))
    check('cuff_owner_route','case "pressureCuff"' in text('functions/fn_ownerDispatch.sqf'))
    flow=text('overrides/fn_getIVFlowRate.sqf')
    check('cuff_flow_per_bag','getOrDefault [_bagId, []]' in flow and 'ACME_pressureInfuserMult' not in flow)
    check('cuff_protects_medicated_bag','!_medicated' in flow and '_hasDrug' in text('functions/fn_pressureInfuserCommit.sqf'))
    check('drainer_passes_identity_both_paths',text('overrides/fn_getBloodVolumeChange.sqf').count('_accessSite, _acmeBagClamp, _bagUid]')==2)
    check('cuff_duplicate_ack_guard','_entry select 3' in text('functions/fn_pressureInfuserAck.sqf'))
    check('cuff_retry_reuses_existing_handler','private _cuffs = missionNamespace getVariable ["ACME_piPending"' in text('functions/fn_clinicalInit.sqf'))
    check('deflated_cuff_remains_fitted','_pressure < 0.08' not in text('functions/fn_pressureInfuserTick.sqf'))
    binary={'.paa','.ogg','.wav','.wss','.p3d','.rtm'}
    assets=[p for p in baseline.rglob('*') if p.is_file() and p.suffix.lower() in binary]
    check('all_original_binary_assets_identical',all((root/p.relative_to(baseline)).is_file() and digest(p)==digest(root/p.relative_to(baseline)) for p in assets),len(assets))
    chest=list((baseline/'functions').glob('fn_chestSeal*.sqf'))
    check('all_chest_seal_functions_identical',all(digest(p)==digest(root/p.relative_to(baseline)) for p in chest),len(chest))
    check('thoracostomy_insertion_removal_unchanged',digest(baseline/'functions/fn_thoraMouseDown.sqf')==digest(root/'functions/fn_thoraMouseDown.sqf'))
    check('network_scalar_helper_unchanged',digest(baseline/'functions/fn_setVarNet.sqf')==digest(root/'functions/fn_setVarNet.sqf'))
    check('clinical_circulation_binding_unchanged',digest(baseline/'overrides/fn_updateCirculationState.sqf')==digest(root/'overrides/fn_updateCirculationState.sqf'))
    check('source_file_paths_no_case_collisions',len([str(p.relative_to(root)).lower() for p in root.rglob('*') if p.is_file()])==len(set(str(p.relative_to(root)).lower() for p in root.rglob('*') if p.is_file())))
    check('original_addon_files_not_removed',all((root/p.relative_to(baseline)).is_file() for p in baseline.rglob('*') if p.is_file()))
    return dict(kind='Static source contracts only; not SQF compilation or execution',checks=checks,passed=sum(x['passed'] for x in checks),failed=sum(not x['passed'] for x in checks))

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('addon',type=Path);ap.add_argument('baseline',type=Path);ap.add_argument('--json',type=Path);a=ap.parse_args()
    r=run(a.addon,a.baseline)
    for row in r['checks']:print(('PASS ' if row['passed'] else 'FAIL ')+row['name']+((': '+str(row['detail'])) if not row['passed'] else ''))
    print(f"{r['passed']} passed, {r['failed']} failed")
    if a.json:a.json.write_text(json.dumps(r,indent=2)+'\n')
    raise SystemExit(int(bool(r['failed'])))
