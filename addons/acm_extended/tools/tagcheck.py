#!/usr/bin/env python3
"""Screen function registrations against source references and detect duplicate resolved names.

A source reference is evidence for review, not proof of execution or runtime override selection.
Comments, ordinary message strings, and declaration-only assignments do not satisfy the check.
No function call graph, control-flow feasibility, or final compiled PBO is evaluated here.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
from dataclasses import dataclass, field
import json
from pathlib import Path
import re
from source_scan import Token, addons_root, code_streams, lex, matching, source_files

@dataclass
class Node:
    name: str
    line: int
    attrs: dict[str,str] = field(default_factory=dict)
    children: list['Node'] = field(default_factory=list)

def config_tree(text: str) -> list[Node]:
    ts=lex(text); pairs=matching(ts)
    def block(lo: int, hi: int) -> list[Node]:
        nodes=[]; i=lo
        while i<hi:
            if ts[i].kind=='ident' and ts[i].value.lower()=='class' and i+1<hi:
                name=ts[i+1].value; j=i+2
                while j<hi and ts[j].value not in {'{',';'}: j+=1
                if j<hi and ts[j].value=='{' and j in pairs:
                    end=pairs[j]; node=Node(name,ts[i].line)
                    k=j+1
                    while k<end:
                        if ts[k].value=='{' and k in pairs: k=pairs[k]+1; continue
                        if k+2<end and ts[k].kind=='ident' and ts[k+1].value=='=' and ts[k+2].kind=='string':
                            node.attrs[ts[k].value.lower()]=ts[k+2].value
                        k+=1
                    node.children=block(j+1,end);nodes.append(node);i=end+1;continue
                i=j+1;continue
            i+=1
        return nodes
    return block(0,len(ts))

def parse_config(path: Path) -> list[dict]:
    roots=config_tree(path.read_text(encoding='utf-8'))
    cfg=next((n for n in roots if n.name.lower()=='cfgfunctions'),None)
    if cfg is None: raise ValueError(f'CfgFunctions is missing: {path}')
    rows=[]
    for group in cfg.children:
        default_tag=group.attrs.get('tag',group.name)
        def visit(n:Node,tag:str,folder:str|None,depth:int):
            tag=n.attrs.get('tag',tag); localfile=n.attrs.get('file')
            if not n.children and depth>=2:
                path=localfile or ((folder.rstrip('\\/')+'\\fn_'+n.name+'.sqf') if folder else None)
                rows.append({'name':n.name,'tag':tag,'resolved':f'{tag}_fnc_{n.name}',
                             'file':path,'line':n.line})
            else:
                for child in n.children: visit(child,tag,localfile or folder,depth+1)
        visit(group,default_tag,group.attrs.get('file'),0)
    return rows

FNAME=re.compile(r'[A-Za-z]\w*_fnc_\w+\Z',re.I)

def collect_references(root:Path,base:str|None=None)->dict[str,list[dict]]:
    result=defaultdict(list)
    for path in source_files(root):
        text=path.read_text(encoding='utf-8-sig'); lines=text.splitlines()
        component=path.relative_to(root).parts[0] if base else None
        for ts in code_streams(text,path.suffix.lower() in {'.hpp','.cpp','.inc'}):
            for i,t in enumerate(ts):
                if t.line<=len(lines) and lines[t.line-1].lstrip().startswith('#define'): continue
                resolved=None;kind=None
                if t.kind=='ident' and FNAME.fullmatch(t.value):
                    if i+1<len(ts) and ts[i+1].value=='=': continue
                    resolved=t.value;kind='code-reference'
                if base and t.kind=='ident' and i+2<len(ts) and ts[i+1].value=='(':
                    macro=t.value.upper(); j=i+2; args=[]
                    while j<len(ts) and ts[j].value!=')':
                        if ts[j].kind=='ident': args.append(ts[j].value)
                        elif ts[j].value!=',': break
                        j+=1
                    if j<len(ts) and ts[j].value==')':
                        if macro in {'FUNC','QFUNC','LINKFUNC'} and len(args)==1:
                            resolved=f'{base}_{component}_fnc_{args[0]}';kind='macro-reference'
                        elif macro in {'EFUNC','QEFUNC'} and len(args)==2:
                            resolved=f'{base}_{args[0]}_fnc_{args[1]}';kind='macro-reference'
                        elif macro in {'ACEFUNC','QACEFUNC'} and len(args)==2:
                            resolved=f'ace_{args[0]}_fnc_{args[1]}';kind='macro-reference'
                if resolved:
                    result[resolved.lower()].append({'file':str(path.relative_to(root)),'line':t.line,'kind':kind,'name':resolved})
    return dict(result)

def load_entry_points(ext:Path,acm:Path,ace:Path)->dict:
    path=ext/'tools/external_entry_points.json'
    if not path.is_file():return {}
    entries=json.loads(path.read_text(encoding='utf-8'));out={}
    roots={'addon':ext,'ace':addons_root(ace).parent,'acm':addons_root(acm).parent}
    for item in entries:
        if not isinstance(item,dict) or not item.get('reason','').strip() or not item.get('source','').strip():
            raise ValueError('External entry points require a reason and source.')
        root=roots.get(item.get('source_root'))
        source=root/item['source'] if root else None
        if source is None or not source.is_file():raise ValueError('External entry-point evidence source is missing.')
        evidence=source.read_text(encoding='utf-8-sig')
        if not item.get('evidence') or item['evidence'] not in evidence:
            raise ValueError('External entry-point evidence text was not found in its source.')
        key=item['name'].lower()
        if key in out:raise ValueError('Duplicate external entry-point contract.')
        out[key]=item
    return out

def run(ext:Path,acm:Path,ace:Path)->dict:
    rows=parse_config(ext/'config.cpp')
    duplicates=defaultdict(list)
    for row in rows: duplicates[row['resolved'].lower()].append(row)
    duplicates={k:v for k,v in duplicates.items() if len(v)>1}
    upstream={}
    for root,base in [(addons_root(acm),'ACM'),(addons_root(ace),'ace')]:
        for k,v in collect_references(root,base).items(): upstream.setdefault(k,[]).extend(v)
    own=collect_references(ext)
    external=load_entry_points(ext,acm,ace)
    overrides=[]
    for row in rows:
        if not row['file'] or '/overrides/' not in row['file'].replace('\\','/').lower():continue
        row=dict(row);k=row['resolved'].lower()
        if k in upstream: row['status']='upstream-reference';row['evidence']=upstream[k][:5]
        elif k in own: row['status']='addon-reference';row['evidence']=own[k][:5]
        elif k in external: row['status']='documented-external-entry';row['evidence']=[external[k]]
        else:
            row['status']='no-code-reference';row['evidence']=[]
            row['other_tags']=[v[0]['name'] for n,v in upstream.items() if n.endswith('_fnc_'+row['name'].lower())]
        overrides.append(row)
    missing=[]
    for row in rows:
        name=(row['file'] or '').replace('\\','/').lstrip('/')
        if name.lower().startswith('acm_extended/') and not (ext/name.split('/',1)[1]).is_file(): missing.append(row)
    return {'scope':'Static source-reference screening; does not prove execution or runtime binding.',
            'registrations':len(rows),'overrides':overrides,'duplicate_resolved_names':duplicates,'missing_local_files':missing}

def main()->int:
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('addon',type=Path);ap.add_argument('acm',type=Path);ap.add_argument('ace',type=Path)
    ap.add_argument('--json',type=Path);a=ap.parse_args()
    try:r=run(a.addon,a.acm,a.ace)
    except (ValueError,OSError,UnicodeError) as e:ap.error(str(e))
    print(r['scope']);print('Registrations:',r['registrations'],'Overrides:',len(r['overrides']))
    for status in ['upstream-reference','addon-reference','documented-external-entry','no-code-reference']:
        print(status+':',sum(x['status']==status for x in r['overrides']))
    print('Duplicate resolved names:',len(r['duplicate_resolved_names']));print('Missing local files:',len(r['missing_local_files']))
    for row in r['overrides']:
        if row['status']=='no-code-reference':print(f"  config.cpp:{row['line']} {row['resolved']} alternatives={row.get('other_tags',[])}")
    for name,rows in r['duplicate_resolved_names'].items():print('  DUPLICATE',name,[r['line'] for r in rows])
    if a.json:a.json.parent.mkdir(parents=True,exist_ok=True);a.json.write_text(json.dumps(r,indent=2)+'\n')
    return int(bool(r['duplicate_resolved_names'] or r['missing_local_files'] or any(x['status']=='no-code-reference' for x in r['overrides'])))
if __name__=='__main__':raise SystemExit(main())
