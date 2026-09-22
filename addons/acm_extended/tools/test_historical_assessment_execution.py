"""Execute assessment presentation and state cleanup without changing physiology.

The actual checked-out SQF runs in SQF-VM. Objects, localization, UI, inventory
and event boundaries are explicit stand-ins. These tests do not render Arma UI.
"""
from pathlib import Path
import re
import pytest
from test_menu_death_lifecycle import ROOT, adapt, execute

F=ROOT/'addons/acm_extended/functions'


def chest_setup():
    source=(ROOT/'addons/breathing/functions/fnc_inspectChestLocal.sqf').read_text()
    return '''
        private _airway=1; private _logs=[];
        ACM_airway_fnc_getAirwayState={_airway};
        ACME_fnc_clinTerm={""};
        ace_medical_treatment_fnc_addToLog={_logs pushBack _this;};
        missionNamespace setVariable ["ACME_hc_descriptors",false];
    '''+'private _inspect={'+adapt(source)+'};'


@pytest.mark.parametrize('ptx,htx,expected',[
    (False,False,['Normal']), (True,False,['Normal','Uneven']),
    (False,True,['Normal','Uneven','Bruising']), (True,True,['Normal','Uneven','Bruising'])])
def test_breathing_chest_assessment_formats_every_selected_finding(ptx,htx,expected):
    keys=['STR_ACM_Breathing_InspectChest_'+x for x in expected]
    execute(chest_setup()+f'_patient setVariable ["ACM_breathing_Pneumothorax_State",{int(ptx)}]; _patient setVariable ["ACM_breathing_Hemothorax_Fluid",{0.8 if htx else 0}];'+
            f'private _expected={str(keys).replace(chr(39),chr(34))};'+'''
        [_medic,_patient] call _inspect;
        private _hints=((_events select 0) select 1) select 0;
        private _shown=format _hints;
        {[_shown find _x>=0,"visible finding missing: "+_x] call _check;} forEach _expected;
        private _primary=_logs select 0;
        private _logged=format ([_primary select 2]+(_primary select 3));
        {[_logged find _x>=0,"logged finding missing: "+_x] call _check;} forEach _expected;
        [count _logs==1,"unexpected secondary log"] call _check;
    ''')


@pytest.mark.parametrize('htx',[False,True])
@pytest.mark.parametrize('deviation',[250,350])
def test_tracheal_deviation_log_uses_its_own_three_arguments(htx,deviation):
    execute(chest_setup()+f'_patient setVariable ["ACM_breathing_TensionPneumothorax_State",true]; _patient setVariable ["ACM_breathing_TensionPneumothorax_Time",CBA_missionTime-{deviation}]; _patient setVariable ["ACM_breathing_Hemothorax_Fluid",{0.8 if htx else 0}];'+'''
        [_medic,_patient] call _inspect;
        [count _logs==2,"deviation entry missing"] call _check;
        private _entry=_logs select 1;
        [count (_entry select 3)==3,"secondary entry argument shape changed"] call _check;
        [(_entry select 2)=="%1 %2: %3","secondary log reused primary placeholders"] call _check;
        private _shown=format ((((_events select 0) select 1) select 0));
    '''+f'[_shown find "STR_ACM_Breathing_InspectChest_TrachealDeviation'+('_Slight' if deviation<300 else '')+'">=0,"deviation not visible"] call _check;')


@pytest.mark.parametrize('ptx,htx',[(False,False),(True,False),(False,True),(True,True)])
@pytest.mark.parametrize('hardcore',[False,True])
def test_mainstem_finding_is_in_both_hint_and_activity_log(ptx,htx,hardcore):
    finding='asymmetric rise, absent left' if hardcore else 'left chest not moving'
    execute(chest_setup()+f'_patient setVariable ["ACME_ETT_Mainstem",true]; _patient setVariable ["ACM_breathing_Pneumothorax_State",{int(ptx)}]; _patient setVariable ["ACM_breathing_Hemothorax_Fluid",{0.8 if htx else 0}]; missionNamespace setVariable ["ACME_hc_descriptors",{str(hardcore).lower()}];'+'''
        [_medic,_patient] call _inspect;
        private _entry=_logs select 0;
        private _shown=format ([_entry select 2]+(_entry select 3));
    '''+f'[_shown find "{finding}">=0,"mainstem observation omitted from log"] call _check;'+'''
        private _hint=format ((((_events select 0) select 1) select 0));
        [_hint find "left">=0,"mainstem observation omitted from hint"] call _check;
    ''')


@pytest.mark.parametrize('dead,arrest,blocked',[(True,False,False),(False,True,False),(False,False,True)])
@pytest.mark.parametrize('injured',[False,True])
def test_absent_respiration_and_retained_injury_evidence_do_not_reposition_or_heal(dead,arrest,blocked,injured):
    execute(chest_setup()+f'_patientAlive={str(not dead).lower()}; _airway={0 if blocked else 1}; _patient setVariable ["ACM_breathing_RespirationRate",{0 if arrest else 18}]; _patient setVariable ["ACM_breathing_Pneumothorax_State",{int(injured)}]; _patient setVariable ["ACM_breathing_Hemothorax_Fluid",{0.8 if injured else 0}];'+'''
        _patient setVariable ["ACME_obtunded",true];
        _patient setVariable ["ACM_core_Lying_State",true];
        _patient setVariable ["ACME_CS_holeData",[["front",0,0,true,true,"seal"]]];
        _patient setVariable ["ACME_CS_ncdPlacedSides",["left"]];
        missionNamespace setVariable ["ACME_hc_descriptors",true];
        private _variables=allVariables _patient;
        private _snapshot=_variables apply {_patient getVariable _x};
        [_medic,_patient] call _inspect;
        private _hint=format ((((_events select 0) select 1) select 0));
        [_hint find "InspectChest_None">=0,"absent respiration not reported"] call _check;
        [_hint find "Chest seals: 1 front, 0 rear">=0 && {_hint find "Unilateral Left NCD">=0},"equipment findings lost"] call _check;
        [(_variables apply {_patient getVariable _x}) isEqualTo _snapshot,"assessment changed patient state"] call _check;
        [count _moves==0 && {count _waits==0},"assessment repositioned patient"] call _check;
    '''+('[_hint find "None_Uneven">=0 && {_hint find "Bruising">=0},"injury evidence suppressed"] call _check;' if injured else ''))
