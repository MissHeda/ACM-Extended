from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
AIR=ROOT/'addons/airway'
EXT=ROOT/'addons/acm_extended/functions'
prep=(AIR/'XEH_PREP.hpp').read_text()
state=(AIR/'functions/fnc_setAirwayState.sqf').read_text()
oral=(AIR/'functions/fnc_setOralAirwayItem.sqf').read_text()
checked=(AIR/'functions/fnc_clearAirwayCheckedTime.sqf').read_text()
for token in ['PREP(setAirwayState);','PREP(setOralAirwayItem);','PREP(clearAirwayCheckedTime);']:
    assert token in prep,token
for token in ['AirwayCollapse_State','AirwayObstructionBlood_State','AirwayObstructionVomit_State','AirwayObstructionVomit_Count','AirwayObstructionVomit_GracePeriod','AirwayObstructionVomit_PFH']:
    assert token in state,token
assert 'AirwayItem_Oral' in oral
assert 'AirwayChecked_Time' in checked
# Extended may read native airway state, but writes now cross airway-owned APIs.
viol=[]
for p in EXT.glob('*.sqf'):
    for line in p.read_text().splitlines():
        if 'setVariable ["ACM_airway_' in line:
            viol.append((p.name,line.strip()))
        if 'setVariable [_x' in line and 'ACM_airway_' in line:
            viol.append((p.name,line.strip()))
assert not viol,viol
state_callers=[p.name for p in EXT.glob('*.sqf') if 'ACM_airway_fnc_setAirwayState' in p.read_text()]
for required in ['fn_megacodeSetAirway.sqf','fn_megacodeScenarioTick.sqf','fn_laryngoConsequenceLocal.sqf','fn_laryngoFluidDrainLocal.sqf','fn_megacodeResetUnit.sqf','fn_ettAirwayProtect.sqf']:
    assert required in state_callers,(required,state_callers)
oral_callers=[p.name for p in EXT.glob('*.sqf') if 'ACM_airway_fnc_setOralAirwayItem' in p.read_text()]
for required in ['fn_airwayVomitOPA.sqf','fn_seizureCollapse.sqf','fn_vomitDislodgeOPA.sqf']:
    assert required in oral_callers,(required,oral_callers)
assert 'ACM_airway_fnc_clearAirwayCheckedTime' in (EXT/'fn_laryngoFluidDrainLocal.sqf').read_text()
print('fork phase 49 airway state ownership checks: PASS')
