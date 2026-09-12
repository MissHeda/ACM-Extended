from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
mapping={
 'syringeDrawButton':'Syringe_Draw_Button', 'syringePrepareFinish':'Syringe_PrepareFinish',
 'syringeGetMedicationList':'Syringe_GetMedicationList','syringeUpdateMedicationList':'Syringe_UpdateMedicationList',
 'transfusionMoveBag':'TransfusionMenu_MoveBag','transfusionMoveBagCancel':'TransfusionMenu_MoveBag_Cancel'}
for old,new in mapping.items():
    p=ROOT/f'addons/circulation/functions/fnc_{new}.sqf'
    assert p.exists(),p
    assert not (ROOT/f'addons/acm_extended/overrides/fn_{old}.sqf').exists(),old
    assert f'overrides\\fn_{old}.sqf' not in CFG,old
assert 'ACME_lastSyringeBtnType = _type;' in (ROOT/'addons/circulation/functions/fnc_Syringe_Draw_Button.sqf').read_text()
prep=(ROOT/'addons/circulation/functions/fnc_Syringe_PrepareFinish.sqf').read_text()
assert 'ACM_circulation_SyringeDraw_DrawnAmount = 0' in prep
assert 'ACM_circulation_fnc_Syringe_Draw_Button =' not in POST
assert 'ACM_circulation_fnc_Syringe_PrepareFinish =' not in POST
assert 'ACME_fnc_ownerDispatch' in (ROOT/'addons/circulation/functions/fnc_TransfusionMenu_MoveBag.sqf').read_text()
print('fork phase 14 circulation UI native merge checks: PASS')
