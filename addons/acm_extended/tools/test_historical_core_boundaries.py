"""Current native transaction and registration boundaries behind old locators.

Exact SQF fragments execute with the original predicates and writes. The finite
primitive's result is supplied explicitly: this tests rejection/fallback wiring,
not the engine's IEEE NaN/Infinity implementation or whole-bag integration.
"""
from pathlib import Path
import json
import re
import pytest
from source_scan import lex, matching
from medication_inventory import subtree
from test_menu_death_lifecycle import ROOT, adapt, execute
from test_historical_io_lifecycle import setup as io_setup

F=ROOT/'addons/acm_extended/functions'
C=ROOT/'addons/circulation/functions'


def block_at(text,opening):
    ts=lex(text);pairs=matching(ts)
    idx=next(i for i,t in enumerate(ts) if t.offset==opening)
    assert ts[idx].value=='{' and idx in pairs
    return text[opening:ts[pairs[idx]].offset+1]


def native_constants():
    headers=(ROOT/'addons/main/script_macros.hpp').read_text()+(ROOT/'include/z/ace/addons/medical_engine/script_macros_medical.hpp').read_text()
    result=''
    for name in ('ACM_IO_FAST1_M','ACM_IO_EZ_M','DEFAULT_BLOOD_VOLUME'):
        values=re.findall(r'^#define\s+'+name+r'\s+([0-9.]+)\b',headers,re.M)
        assert len(values)==1,(name,values)
        result+=name+'='+values[0]+';'
    return result


def test_ace_volume_bridge_delegates_inputs_and_return_without_second_integration():
    body=(ROOT/'addons/core/overrides/fnc_getBloodVolumeChange.sqf').read_text()
    execute('private _calls=[]; ACM_circulation_fnc_getBloodVolumeChange={_calls pushBack _this;4.25};'+
        'private _bridge={'+adapt(body)+'};'+'''
        private _value=[_patient,0.75,true] call _bridge;
        [_value==4.25,"bridge replaced canonical return"] call _check;
        [_calls isEqualTo [[_patient,0.75,true]],"bridge altered inputs or integrated twice"] call _check;
    ''')


@pytest.mark.parametrize('admitted',[0,-1,0.001,25])
@pytest.mark.parametrize('access',['ACM_IO_FAST1_M','ACM_IO_EZ_M','1','5'])
def test_only_positive_admitted_io_bag_volume_reaches_the_actual_response(admitted,access):
    text=(C/'fnc_getBloodVolumeChange.sqf').read_text()
    anchor='if (_admitted > 0 && {_accessType in [ACM_IO_FAST1_M, ACM_IO_EZ_M]}) then '
    assert text.count(anchor)==1
    start=text.index(anchor);opening=start+len(anchor)
    statement=anchor+block_at(text,opening)+';'
    expected=admitted>0 and access.startswith('ACM_IO_')
    execute(io_setup()+native_constants()+'''
        private _unit=_patient; private _targetBodyPart="leftleg";
        private _ioCalls=[];private _original=ACME_fnc_ioPainResponse;
        ACME_fnc_ioPainResponse={_ioCalls pushBack _this;_this call _original;};
    '''+f'private _admitted={admitted};private _accessType={access};'+adapt(statement)+
        f'[count _ioCalls=={int(expected)} && {{count _waits=={int(expected)}}},"IO bag admission gate wrong"] call _check;')


@pytest.mark.parametrize('blood,plasma,saline,platelets,last,finite',[
    (5,.2,.1,5.5,4,True),
    ([],2,1,'bad',4,True),
    ('bad',[],'bad',[],[],True),
    (8,1,1,6,4,True),
    (-1,0,0,6,4,True),
    (5,.2,.1,5.5,4,False),
])
def test_actual_native_volume_exit_preserves_valid_values_and_routes_bad_values_to_fallbacks(blood,plasma,saline,platelets,last,finite):
    text=(C/'fnc_getBloodVolumeChange.sqf').read_text()
    fragment=text[text.index('private _fnc_finite = {'):]
    assert fragment.count('call _fnc_finite')==4
    assert 'finite _v' in fragment and 'finite _lastBlood' in fragment
    fragment=fragment.replace('finite _v','(_v call _engineFinite)').replace('finite _lastBlood','(_lastBlood call _engineFinite)')
    fragment=fragment.replace(', _syncValues]',']')
    # Control the engine predicate, without constructing fake numeric NaNs.
    valid=lambda v:isinstance(v,(float,int)) and finite
    fallback=last if valid(last) else 6
    expected=[blood if valid(blood) else fallback,plasma if valid(plasma) else 0,saline if valid(saline) else 0,platelets if valid(platelets) else 6]
    expected_volume=min(6,max(0,sum(expected[:3])))
    execute(native_constants()+f'private _engineFinite={{{str(finite).lower()}}};'+
        'private _unit=_patient; private _syncValues=false;'+
        ''.join('private '+name+'='+json.dumps(value)+';' for name,value in [('_bloodVolume',blood),('_plasmaVolume',plasma),('_salineVolume',saline),('_plateletCount',platelets)])+
        '_unit setVariable ["ace_medical_bloodVolume",'+json.dumps(last)+'];'+
        'private _exit={'+adapt(fragment)+'}; private _value=call _exit;'+
        f'[abs (_value-{expected_volume})<0.000001,"wrong circulating-volume return"] call _check;'+
        '[[_unit getVariable "ACM_circulation_Blood_Volume",_unit getVariable "ACM_circulation_Plasma_Volume",_unit getVariable "ACM_circulation_Saline_Volume",_unit getVariable "ACM_circulation_Platelet_Count"] isEqualTo '+json.dumps(expected)+',"fallback changed valid compartment or failed to repair invalid one"] call _check;')


def binding_setup(omit='',wrong_type=False):
    text=(F/'fn_clinicalBindings.sqf').read_text()
    pairs=re.findall(r'\["((?:ACM|ace)_\w+_fnc_\w+)",\s*"([^"]+)"\]',text)
    assert pairs and all('_fnc_' in name for name,marker in pairs)
    values={}
    for name,marker in pairs:values.setdefault(name,[]).append(marker)
    code=''
    for name,markers in values.items():
        if name==omit:
            if wrong_type:code+='missionNamespace setVariable ["'+name+'",17];'
            continue
        code+='missionNamespace setVariable ["'+name+'",{private _marker="'+','.join(markers)+'";true}];'
    return code+'ACME_fnc_clinicalBindings={'+adapt(text)+'};',pairs


@pytest.mark.parametrize('missing',['','ACM_core_fnc_onUnconscious','ace_medical_status_fnc_getBloodVolumeChange'])
@pytest.mark.parametrize('wrong_type',[False,True])
def test_delayed_native_binding_diagnostic_retains_real_results_and_detects_missing_bindings(missing,wrong_type):
    code,pairs=binding_setup(missing,wrong_type)
    init=(F/'fn_clinicalInit.sqf').read_text()
    marker='ACME_NA3_bindingResult = call ACME_fnc_clinicalBindings;'
    assert init.count(marker)==1
    start=init.rfind('[{',0,init.index(marker))
    end=init.index('call CBA_fnc_waitAndExecute;',start)+len('call CBA_fnc_waitAndExecute;')
    callback=init[start:end]
    execute(code+callback+'''
        [count _waits==1,"diagnostic was not scheduled exactly once"] call _check;
        private _job=_waits select 0; (_job select 1) call (_job select 0);
    '''+f'[(ACME_NA3_bindingResult select 0) isEqualTo {str(not missing).lower()},"binding diagnostic hid missing or mistyped code"] call _check;'+
        f'[count (ACME_NA3_bindingResult select 1)=={len(pairs)},"diagnostic dropped per-function rows"] call _check;'+
        f'[count ((ACME_NA3_bindingResult select 1) select {{!(_x select 1)}})=={sum(name==missing for name,_ in pairs)},"wrong diagnostic failure identity"] call _check;')


def test_treatment_override_is_registered_under_the_native_core_owner():
    config=(ROOT/'addons/core/CfgFunctions.hpp').read_text()
    tree=subtree(config,'CfgFunctions')
    owner=tree['classes']['overwrite_medical_treatment']
    assert owner['props']['tag']=='ace_medical_treatment'
    registered=owner['classes']['ace_medical_treatment']['classes']['treatment']['props']['file']
    assert ''.join(registered.split())==r'QPATHTOF(overrides\fnc_treatment.sqf)'
    assert '#include "CfgFunctions.hpp"' in (ROOT/'addons/core/config.cpp').read_text()
    assert (ROOT/'addons/core/overrides/fnc_treatment.sqf').is_file()
    # Do not reintroduce a second Extended override registration.
    old=r'\acm_extended\overrides\fn_treatment.sqf'
    assert old not in (ROOT/'addons/acm_extended/config.cpp').read_text()
