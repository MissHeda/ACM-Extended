from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FUN=ROOT/"addons/acm_extended/functions"
CFG=(ROOT/"addons/acm_extended/config.cpp").read_text()
helper=(FUN/"fn_infusionMedicationStateCommit.sqf").read_text()
assert 'class infusionMedicationStateCommit {};' in CFG
assert 'setVariable ["ACME_infusion_BagMedications", _entries, _public]' in helper
assert 'setVariable ["ACME_infusion_HasBagMedications", !(_entries isEqualTo []), _public]' in helper
viol=[]
for p in FUN.glob('*.sqf'):
    if p.name=='fn_infusionMedicationStateCommit.sqf': continue
    t=p.read_text()
    for token in ['setVariable ["ACME_infusion_BagMedications"','setVariable ["ACME_infusion_HasBagMedications"']:
        if token in t: viol.append((p.name,token))
    if '"ACME_infusion_BagMedications"' in t and 'ACME_fnc_setVarNet' in t:
        # targeted writer patterns, not ordinary reads
        for line in t.splitlines():
            if 'ACME_infusion_BagMedications' in line and 'ACME_fnc_setVarNet' in line: viol.append((p.name,line.strip()))
    if '"ACME_infusion_HasBagMedications"' in t and 'ACME_fnc_setVarNet' in t:
        for line in t.splitlines():
            if 'ACME_infusion_HasBagMedications' in line and 'ACME_fnc_setVarNet' in line: viol.append((p.name,line.strip()))
assert not viol,viol
callers=[p.name for p in FUN.glob('*.sqf') if 'ACME_fnc_infusionMedicationStateCommit' in p.read_text()]
for required in ['fn_clinicalReset.sqf','fn_clearAllAilments.sqf','fn_discardYTubing.sqf','fn_transfusionPullBag.sqf','fn_preparedAttachLocal.sqf','fn_fluidCommit.sqf','fn_infusionClampLocal.sqf','fn_infusionRegisterCore.sqf','fn_infusionRetire.sqf','fn_clinicalBagMove.sqf','fn_handleInfusions.sqf']:
    assert required in callers,(required,callers)
print("fork phase 44 infusion medication state contract checks: PASS")
