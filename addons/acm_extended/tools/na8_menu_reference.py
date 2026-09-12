#!/usr/bin/env python3
"""NA8 source-data and policy reference model. This is NOT an Arma config compiler or SQF VM.
Only named classes, simple inheritance, and literal category fields are read. Runtime merging,
macros other than the actions-container name, canTreat predicates and callbacks are not evaluated.
"""
from __future__ import annotations
import argparse, json
from dataclasses import dataclass, field
from pathlib import Path
from source_scan import lex, matching, addons_root

# Literal data shared by the SQF collector and renderer; this remains a policy
# reference model, not execution of either function in an Arma runtime.
_examine_source = (Path(__file__).resolve().parents[1] / 'functions/fn_menuExamineGroups.sqf').read_text()
EXAMINE_GROUPS = json.loads(_examine_source[_examine_source.index('\n[') + 1:])

@dataclass
class Entry:
    name: str
    base: str = ''
    category: str | None = None
    evidence: list[str] = field(default_factory=list)

def read_actions(path: Path) -> list[Entry]:
    ts=lex(path.read_text(encoding='utf-8-sig'));pairs=matching(ts)
    def body_classes(lo,hi):
        out=[];i=lo
        while i<hi:
            if ts[i].value.lower()!='class':
                if ts[i].value in {'{','(','['} and i in pairs:i=pairs[i]+1
                else:i+=1
                continue
            name=ts[i+1].value;j=i+2;base=''
            if j<hi and ts[j].value==':':base=ts[j+1].value;j+=2
            while j<hi and ts[j].value not in {'{',';'}:j+=1
            if j>=hi:break
            if ts[j].value==';':i=j+1;continue
            end=pairs[j];cat=None;k=j+1
            while k<end:
                if ts[k].value in {'{','[','('} and k in pairs:k=pairs[k]+1;continue
                if k+2<end and ts[k].value.lower()=='category' and ts[k+1].value=='=' and ts[k+2].kind=='string':cat=ts[k+2].value
                k+=1
            out.append(Entry(name,base,cat,[f'{path.name}:{ts[i].line}']));i=end+1
        return out
    i=0
    while i<len(ts)-1:
        if ts[i].value.lower()=='class' and ts[i+1].value.lower() in {'ace_medical_treatment_actions','acegvar','gvar','egvar'}:
            j=i+2
            while j<len(ts) and ts[j].value not in {'{',';'}:j+=1
            if j<len(ts) and ts[j].value=='{':return body_classes(j+1,pairs[j])
        i+=1
    return []

def load(addon: Path, acm: Path, ace: Path) -> dict[str,Entry]:
    ace=addons_root(ace);acm=addons_root(acm)
    paths=[ace/'medical_treatment/ACE_Medical_Treatment_Actions.hpp',acm/'core/ACE_Medical_Treatment_Actions.hpp']
    paths += sorted(p for p in acm.rglob('ACE_Medical_Treatment_Actions.hpp') if p not in paths)
    paths += [addon/'config.cpp']
    entries={}
    for path in paths:
        for e in read_actions(path):
            k=e.name.lower()
            if k not in entries:entries[k]=e
            else:
                old=entries[k]
                if e.base:old.base=e.base
                if e.category is not None:old.category=e.category
                old.evidence+=e.evidence
    return entries

def lineage(entries,name):
    chain=[];key=name.lower()
    while key and key not in chain and len(chain)<64:
        chain.append(key);entry=entries.get(key)
        key=entry.base.lower() if entry else ''
    return chain

def category(entries,name):
    return next((entries[k].category for k in lineage(entries,name) if k in entries and entries[k].category is not None),'')

def policy(name,cat,chain):
    name=name.lower();chain=[x.lower() for x in chain]
    if 'usesyringe_10' in chain:return cat,'',True
    if name=='acme_syringekit_drawpatient':return 'medication','narc_box',False
    if name in {'slapawake','acme_inspectchest','usestethoscope'}:cat='examine'
    if cat=='examine':return cat,next((key for key,_,names,_ in EXAMINE_GROUPS if name in names),''),False
    ivroots={'insertiv_16_upper','removeiv_16_upper','insertio_fast1','removeio_fast1','opentransfusionmenu','bloodiv','acme_place18g_upper','acme_ivminigamestart','acme_establishej','acme_removeej'}
    if cat=='advanced' and (set(chain)&ivroots or name.startswith(('insertiv_','removeiv_','insertio_','removeio_'))):return 'medication','iv_access',False
    if name=='checkairway' or set(chain)&{'usesuctionbag','drainfluid_accuvac','acme_drainfluid_accuvac'}:return 'airway','adjuncts',False
    if name=='checkbreathing':return 'airway','ventilation',False
    if 'fentanyllozenge' in chain:return cat,'route_buc',False
    if set(chain)&{'penthrox','ammoniainhalant','naloxone'}:return cat,'route_in',False
    if set(chain)&{'paracetamol','painkillers'}:return cat,'route_po',False
    return cat,'',False

def report(entries):
    rows=[]
    for key,e in entries.items():
        cat=category(entries,key);result=policy(key,cat,lineage(entries,key))
        if result!=(cat,'',False):rows.append(dict(name=e.name,original_category=cat,category=result[0],bucket=result[1],hidden=result[2],lineage=lineage(entries,key),evidence=e.evidence))
    return {'scope':__doc__,'classes_read':len(entries),'policy_rows':rows}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('addon',type=Path);p.add_argument('acm',type=Path);p.add_argument('ace',type=Path);p.add_argument('--json',type=Path);a=p.parse_args()
    r=report(load(a.addon,a.acm,a.ace));text=json.dumps(r,indent=2)+'\n'
    if a.json:a.json.write_text(text)
    else:print(text)
