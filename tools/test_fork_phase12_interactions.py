from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
POST=(ROOT/'addons/acm_extended/functions/fn_postInit.sqf').read_text()
CORECFG=(ROOT/'addons/core/CfgFunctions.hpp').read_text()
GUICFG=(ROOT/'addons/gui/CfgFunctions.hpp').read_text()

owners={
 'canDrag':ROOT/'addons/core/overrides/fnc_canDrag.sqf',
 'canCarry':ROOT/'addons/core/overrides/fnc_canCarry.sqf',
 'canTreatCached':ROOT/'addons/core/overrides/fnc_canTreatCached.sqf',
 'getDogtagData':ROOT/'addons/core/overrides/fnc_getDogtagData.sqf',
 'canOpenMenu':ROOT/'addons/gui/overrides/fnc_canOpenMenu.sqf',
 'collectActions':ROOT/'addons/gui/overrides/fnc_collectActions.sqf',
 'updateActions':ROOT/'addons/gui/overrides/fnc_updateActions.sqf',
}
for name,p in owners.items():
    assert p.exists(),p
    assert not (ROOT/'addons/acm_extended/overrides'/f'fn_{name}.sqf').exists(),name
    assert f'overrides\\fn_{name}.sqf' not in CFG,name
for token in ['ACME_obtunded','ACME_XStat_impaired','QGVAR(Lying_State)']:
    assert token in owners['canDrag'].read_text(),token
    assert token in owners['canCarry'].read_text(),token
assert 'class canTreatCached' in CORECFG
assert 'class canOpenMenu' in GUICFG
collect=owners['collectActions'].read_text()
assert 'ACME_native_fnc_collectActions' not in collect
assert 'ACME_fnc_menuActionInfo' in collect and 'ACME_menuExamineGroups' in collect
assert 'ACME_native_fnc_getDogtagData' not in owners['getDogtagData'].read_text()
assert 'ACME_fnc_installMedicalMenuRenderer' not in POST
assert 'ace_medical_gui_fnc_updateActions =' not in POST
print('fork phase 12 interaction/menu native merge checks: PASS')
