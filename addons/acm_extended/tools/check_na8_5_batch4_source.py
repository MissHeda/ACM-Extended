#!/usr/bin/env python3
"""Check B4 source contracts and preservation. This does not execute or compile SQF."""
from __future__ import annotations
import argparse, hashlib, json, re, sys
from pathlib import Path
import xml.etree.ElementTree as ET
from source_scan import lex

def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(root): return {p.relative_to(root).as_posix():digest(p) for p in root.rglob('*') if p.is_file()}
def block(text, name):
    m=re.search(r'\bclass\s+'+re.escape(name)+r'\s*\{',text)
    if not m: raise ValueError(name)
    depth=0
    for t in lex(text[m.start():]):
        if t.kind != 'symbol': continue
        if t.value=='{': depth+=1
        elif t.value=='}':
            depth-=1
            if depth==0:return text[m.start():m.start()+t.offset+1]
    raise ValueError('Unclosed '+name)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source',type=Path);ap.add_argument('baseline',type=Path)
    ap.add_argument('--b2',type=Path);ap.add_argument('--json',type=Path)
    a=ap.parse_args();r=a.source;b=a.baseline;result=[]
    def check(name,condition,details=None):result.append({'check':name,'passed':bool(condition),'details':details})
    def source(name):return (r/'functions'/('fn_'+name+'.sqf')).read_text(encoding='utf-8-sig')
    old=inventory(b);new=inventory(r)
    cfg=(r/'config.cpp').read_text(encoding='utf-8-sig');post=source('postInit')
    check('config version',bool(re.search(r'version\s*=\s*"0\.9\.999r-73-NA8\.5-B4"',cfg)))
    check('postInit version','ACME_infusion_version = "0.9.999r-73-NA8.5-B4";' in post)
    removed=sorted(set(old)-set(new));expected=['functions/fn_infusion'+x+'.sqf' for x in ['Presets','PresetRate','PresetApply','PresetCommit','PresetResult']]+['tools/check_na8_5_batch3_source.py']
    check('only obsolete B3 preset code and checker removed',removed==sorted(expected),removed)
    runtime=[p for p in r.rglob('*') if p.is_file() and p.suffix.lower() in ('.sqf','.cpp','.hpp')]
    joined='\n'.join(p.read_text(encoding='utf-8-sig') for p in runtime)
    for value in ('ACME_fnc_infusionPresets','ACME_fnc_infusionPresetRate','ACME_fnc_infusionPresetApply','ACME_fnc_infusionPresetCommit','ACME_fnc_infusionPresetResult','ACME_infusionPresetCommit','ACME_infusionPresetResult','ACME_sedation_propofolEquiv','ACME_sedation_induceThreshold','Apply rate'):
        check('retired runtime token: '+value,value not in joined)
    for name in ('onClampLoad','setClampPosition','cycleDropSet'):
        f='functions/fn_'+name+'.sqf'
        if a.b2:check('exact manual B2 control: '+name,digest(a.b2/f)==new[f])
    check('propofol allowed in preparation',bool(re.search(r'ACME_infusion_allowedMedications\s*=\s*\[[^;]*"Propofol"',post,re.S)))
    check('propofol reads native scalar effect','[_patient, "Propofol_IV", false]' in source('propofolOnBoard'))
    check('propofol not rescaled',not any(t.value=='*' for t in lex(source('propofolOnBoard'))))
    check('ketamine native weights','(_im * 0.5) + (_iv * 0.8)' in source('ketamineOnBoard'))
    check('existing ketamine threshold retained','["ACME_ket_induceThreshold", 7]' in source('ketamineSedationTick'))
    check('propofol AI induction uses native full effect','_propLoad >= 1' in source('ketamineSedationTick'))
    check('AI owner gate and player exemption',all(v in source('ketamineSedationTick') for v in ('!local _patient','isPlayer _patient')))
    check('laryngoscopy graded shared exposure','ACME_fnc_laryngoReflexChance' in source('laryngoPassTube') and 'ACME_fnc_sedationComponents' in source('laryngoReflexChance'))
    for name in ('infusionDeliver','infusionRegisterCore','infusionHandler','getBloodVolumeChange'):
        folder='overrides' if name=='getBloodVolumeChange' else 'functions';rel=folder+'/fn_'+name+'.sqf'
        check('admitted dose path unchanged: '+name,old.get(rel)==new.get(rel))
    check('all medication config unchanged',block(cfg,'ACM_Medication')==block((b/'config.cpp').read_text(encoding='utf-8-sig'),'ACM_Medication'))
    for name in ('propofolOnBoard','thoraClosureMode','thoraClosureArt','ivMinigameSyncBand'):
        check('new registered function exists: '+name,(r/'functions'/('fn_'+name+'.sqf')).is_file() and bool(re.search(r'\bclass\s+'+name+r'\b',cfg)))
    check('seal has real held identity','if (_held == "seal") exitWith' in source('thoraMouseDown'))
    seal=source('thoraMouseDown').split('if (_held == "seal") exitWith',1)[1].split('private _tubeMedic',1)[0]
    check('seal branch native seal effect and inventory debit','ACM_breathing_fnc_applyChestSeal' in seal and '_medS removeItem "ACM_ChestSeal"' in seal)
    check('seal branch never inserts/drains tube',all(v not in seal for v in ('Thoracostomy_insertChestTube','thoraPassiveDrain','ACME_thora_tube_%1')))
    check('held and placed shared artwork',all('ACME_fnc_thoraClosureArt' in source(n) for n in ('thoraTick','thoraRenderTube')))
    check('actual placed tube takes priority over suture flag','if (_placed) then {"tube"} else {"seal"}' in source('thoraRenderTube'))
    check('doctor permission retained','[_medic, 2] call ace_medical_treatment_fnc_isMedic' in source('thoraClosureMode'))
    check('observer uses state not own permissions','ACME_Thora_ClosureSeen' in source('thoraTick') and 'isMedic' not in source('thoraRenderTube'))
    sync=source('ivMinigameSyncBand')
    check('band observer performs no patient writes',all(v not in sync for v in ('ACME_fnc_setVarNet','ACME_fnc_ownerDispatch','_patient setVariable','ACME_fnc_ivMinigameSaveState')))
    check('band observer runs from existing tick','[] call ACME_fnc_ivMinigameSyncBand;' in source('ivMinigameTick'))
    check('restore does not republish physical band','ACME_fnc_ivMinigameBandFlag' not in source('ivMinigameRestoreState'))
    check('stale view cannot set physical band','_band set [0, _activeHere]' in source('ivStateLocal'))
    check('physical band has owner and epoch guards',all(v in source('ivStateLocal') for v in ('!local _patient','_epoch !=','ACME_IV_BandOnPart_%1','private _snapshot')))
    check('flip clears prior view before switching',source('ivMinigameFlip').index('ACME_fnc_ivMinigameBandFlag')<source('ivMinigameFlip').index('setVariable ["ACME_IV_View"'))
    check('all peripheral band snapshots in reset schema',all(('"ACME_IV_BandState_'+str(i)+'"') in source('clinicalFields') for i in (2,3,4,5)))
    for label,predicate in (
        ('media',lambda p:Path(p).suffix.lower() in ('.paa','.ogg','.wss','.wav','.p3d','.rtm')),
        ('chest seal',lambda p:p.startswith('functions/fn_chestSeal') and p.endswith('.sqf')),
        ('ventilator',lambda p:p.startswith('functions/fn_vent') and p.endswith('.sqf')),
        ('overrides',lambda p:p.startswith('overrides/'))):
        lhs={p:h for p,h in old.items() if predicate(p)};rhs={p:h for p,h in new.items() if predicate(p)}
        check(label+' byte preservation',lhs==rhs,{'original':len(lhs),'candidate':len(rhs)})
    for rel in ('XEH_settings.hpp','XEH_preInit.sqf','functions/fn_ivSiteData.sqf','functions/fn_ivSiteIndex.sqf','functions/fn_ivMinigameRemoveBand.sqf','functions/fn_ivVeinSet.sqf'):
        check('preserved: '+rel,old.get(rel)==new.get(rel))
    raw_tokens=[t.value.lower() for p in runtime for t in lex(p.read_text(encoding='utf-8-sig'))]
    check('no direct debug RPT calls',all(t not in raw_tokens for t in ('diag_log','diag_logslowframe','diag_logslowframecapture','diag_captureframe','diag_captureframetofile')))
    check('stringtable XML parses',ET.parse(r/'stringtable.xml').getroot() is not None)
    check('no Python bytecode in addon',not any(p.endswith(('.pyc','.pyo')) for p in new))
    report={'scope':'Source contracts and byte preservation only; no SQF execution','baseline_files':len(old),'candidate_files':len(new),'modified':sorted(p for p in old.keys()&new.keys() if old[p]!=new[p]),'added':sorted(new.keys()-old.keys()),'removed':removed,'passed':sum(x['passed'] for x in result),'total':len(result),'checks':result}
    if a.json:a.json.parent.mkdir(parents=True,exist_ok=True);a.json.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    for x in result:
        if not x['passed']:print('FAIL:',x['check'])
    print(f"{report['passed']}/{report['total']} source checks passed; {len(old)} baseline files, {len(new)} candidate files.")
    return 0 if report['passed']==report['total'] else 1
if __name__=='__main__':raise SystemExit(main())
