#!/usr/bin/env python3
"""Read-only inventory of ACM_Medication. Resolves supplied-source inheritance, not engine config.
Usage: python medication_inventory.py --native PATH/ACM_Medication.hpp --addon PATH/config.cpp --out DIR
No third-party dependencies. Leaves unexpanded config expressions as strings.
"""
from __future__ import annotations
import argparse, copy, csv, json, re
from pathlib import Path

TOKEN = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:""|[^"\\]|\\.)*"|[A-Za-z_$][\w$]*|[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?|[^\s]')

def tokens(text):
    return [m.group() for m in TOKEN.finditer(text) if not m.group().startswith(('//','/*'))]

def empty(): return {'parent':None,'props':{},'classes':{}}

def merge(a,b):
    if b['parent']: a['parent']=b['parent']
    a['props'].update(b['props'])
    for k,v in b['classes'].items(): merge(a['classes'].setdefault(k,empty()),v)
    return a

def value(ts):
    text=' '.join(ts)
    if ts and ts[0]=='{' and ts[-1]=='}':
        parts=[]; st=0; buf=[]
        for t in ts[1:-1]:
            if t==',' and st==0:
                if buf: parts.append(value(buf));buf=[]
            else:
                buf.append(t);st+=(t=='{')-(t=='}')
        if buf:parts.append(value(buf))
        return parts
    if len(ts)==1:
        t=ts[0]
        if t.startswith('"'):return t[1:-1].replace('""','"')
        try:return float(t) if any(c in t for c in '.eE') else int(t)
        except ValueError:pass
    return text

def parse(text):
    ts=tokens(text); i=0
    def scope():
        nonlocal i
        out=empty()
        while i<len(ts) and ts[i]!='}':
            if ts[i]=='class':
                i+=1;name=ts[i];i+=1;node=empty()
                if i<len(ts) and ts[i]==':': i+=1;node['parent']=ts[i];i+=1
                if i<len(ts) and ts[i]=='{':
                    i+=1;child=scope();child['parent']=node['parent'];node=child
                    if i>=len(ts) or ts[i]!='}':raise ValueError('Unbalanced class '+name)
                    i+=1
                if i<len(ts) and ts[i]==';':i+=1
                merge(out['classes'].setdefault(name,empty()),node)
            else:
                key=[]
                while i<len(ts) and ts[i] not in ('=',';','}'):
                    key.append(ts[i]);i+=1
                if i<len(ts) and ts[i]=='=':
                    i+=1;vs=[];depth=0
                    while i<len(ts) and not(ts[i]==';' and depth==0):
                        vs.append(ts[i]);depth+=(ts[i]=='{')-(ts[i]=='}');i+=1
                    name=''.join(key).removesuffix('[]')
                    if name:out['props'][name]=value(vs)
                if i<len(ts) and ts[i]==';':i+=1
        return out
    return scope()

def subtree(text,name='ACM_Medication'):
    # Work only inside the named class: unrelated macros in the giant addon config are irrelevant.
    match=re.search(r'\bclass\s+'+re.escape(name)+r'\s*\{',text)
    if not match:raise ValueError('Missing class '+name)
    ts=tokens(text[match.start():]);depth=0;end=0
    for i,t in enumerate(ts):
        depth+=(t=='{')-(t=='}')
        if t=='}' and depth==0:end=i+1;break
    return parse(' '.join(ts[:end])+';')['classes'][name]

def resolve(classes,name,trail=()):
    if name in trail:raise ValueError('Inheritance cycle: '+str(trail+(name,)))
    n=classes[name];p=n['parent'];out={}
    if p:
        if p not in classes:raise ValueError(f'Missing parent {p} for {name}')
        out.update(resolve(classes,p,trail+(name,)))
    out.update(n['props']);return out

def inventory(native,addon):
    a=subtree(Path(native).read_text(encoding='utf-8-sig'))
    b=subtree(Path(addon).read_text(encoding='utf-8-sig'))
    merge(a,b)
    meds=a['classes']['Medications'];cs=meds['classes'];rows=[]
    for name,n in cs.items():
        if name.startswith('ACM_'):continue
        props=dict(meds['props']);props.update(resolve(cs,name))
        rows.append({'classname':name,'parent':n['parent'],**props})
    concentrations=[]
    for name,n in a['classes'].get('Concentration',empty())['classes'].items():
        concentrations.append({'source':name,**n['props']})
    groups={k:v['props'].get('classnames',[]) for k,v in a['classes'].get('MedicationType',empty())['classes'].items()}
    return {'method':'Supplied-source merge and inheritance; not Arma preprocessor/engine execution',
            'medication_classes':sorted(rows,key=lambda r:r['classname']),
            'concentrations':sorted(concentrations,key=lambda r:r['source']),
            'medication_types':groups}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--native',required=True,type=Path);ap.add_argument('--addon',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);args=ap.parse_args()
    result=inventory(args.native,args.addon);args.out.mkdir(parents=True,exist_ok=True)
    (args.out/'MEDICATION_MATRIX.json').write_text(json.dumps(result,indent=2)+'\n')
    fields=['classname','parent','administrationType','medicationType','timeTillMaxEffect','maxEffectTime','timeInSystem','minEffectDose','maxEffectDose','weightEffect','maxDose','hrIncrease','rrAdjust','coSensitivityAdjust','breathingEffectivenessAdjust','painReduce','viscosityChange']
    with (args.out/'MEDICATION_MATRIX.csv').open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(result['medication_classes'])
    print(f"{len(result['medication_classes'])} medication/effect classes; {len(result['concentrations'])} source concentrations")
if __name__=='__main__': main()
