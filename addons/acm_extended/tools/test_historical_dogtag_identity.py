"""Execute native dogtag caching with name/SSN/blood/weight sources mocked.

Checks cache validation and reuse, not identity generation randomness or UI.
The cache intentionally accepts the native three-string core plus optional data.
"""
import pytest
from test_menu_death_lifecycle import ROOT, adapt, execute


def setup():
    text=(ROOT/'addons/core/overrides/fnc_getDogtagData.sqf').read_text()
    text=text.replace('GET_BLOODTYPE(_target)','_blood').replace('GET_BODYWEIGHT(_target)','_weightKg')
    return '''
        private _blood=2; private _weightKg=83.4; private _nameReads=0; private _bloodGenerated=0; private _ssnCalls=0;
        ACM_core_Dogtag_ShowWeight=true;
        ace_common_fnc_getName={_nameReads=_nameReads+1;"Casualty"};
        ace_dogtags_fnc_ssn={_ssnCalls=_ssnCalls+1;"111-22-333"};
        ACM_circulation_fnc_generateBloodType={_bloodGenerated=_bloodGenerated+1;4};
        ACM_circulation_fnc_convertBloodType={if ((_this select 0)==4) then {"O+"} else {"A+"}};
    '''+'ace_dogtags_fnc_getDogtagData={'+adapt(text)+'};'


@pytest.mark.parametrize('cached',['["Name","SSN","A+"]','["Name","SSN","A+","90 KG"]'])
def test_valid_core_identity_cache_is_returned_unchanged_without_regeneration(cached):
    execute(setup()+f'private _cached={cached}; _patient setVariable ["ace_dogtags_dogtagData",_cached];'+'''
        private _result=[_patient] call ace_dogtags_fnc_getDogtagData;
        [_result isEqualTo _cached,"valid cache changed"] call _check;
        [_nameReads==0 && {_bloodGenerated==0} && {_ssnCalls==0},"valid identity regenerated"] call _check;
    ''')


@pytest.mark.parametrize('cached',['nil','5','"bad"','[]','["Name","SSN"]','["Name",6,"A+"]','["Name","SSN",true]'])
def test_invalid_cache_regenerates_once_and_second_read_reuses_native_result(cached):
    execute(setup()+f'_patient setVariable ["ace_dogtags_dogtagData",{cached}];'+'''
        private _first=[_patient] call ace_dogtags_fnc_getDogtagData;
        private _second=[_patient] call ace_dogtags_fnc_getDogtagData;
        [_first isEqualTo ["Casualty","111-22-333","A+","83 KG"],"wrong native identity fields"] call _check;
        [_first isEqualTo _second && {_nameReads==1} && {_ssnCalls==1} && {_bloodGenerated==0},"cache regenerated repeatedly"] call _check;
    ''')


@pytest.mark.parametrize('weight',[True,False])
@pytest.mark.parametrize('alive',[True,False])
def test_missing_blood_type_uses_native_generation_and_dead_identity_remains_available(weight,alive):
    execute(setup()+f'_blood = -1; _patientAlive={str(alive).lower()}; ACM_core_Dogtag_ShowWeight={str(weight).lower()};'+'''
        private _result=[_patient] call ace_dogtags_fnc_getDogtagData;
        [_bloodGenerated==1 && {(_result select 2)=="O+"},"missing blood type not generated natively"] call _check;
    '''+f'[(_result select 3)=="{"83 KG" if weight else ""}","optional weight ignored"] call _check;'+'''
        [(_patient getVariable ["ace_dogtags_dogtagData",[]]) isEqualTo _result,"native cache not stored"] call _check;
    ''')


def test_registered_native_override_and_consumer_are_connected():
    registration=(ROOT/'addons/core/CfgFunctions.hpp').read_text()
    consumer=(ROOT/'addons/core/overrides/fnc_checkDogtag.sqf').read_text()
    assert registration.count('class getDogtagData {')==1
    assert r'file = QPATHTOF(overrides\fnc_getDogtagData.sqf);' in registration
    assert '_target call ACEFUNC(dogtags,getDogtagData)' in consumer
