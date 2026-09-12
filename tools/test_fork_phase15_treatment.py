from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CFG=(ROOT/'addons/acm_extended/config.cpp').read_text()
PREP=(ROOT/'addons/core/XEH_PREP.hpp').read_text()
public=(ROOT/'addons/core/overrides/fnc_treatment.sqf').read_text()
native=(ROOT/'addons/core/functions/fnc_treatmentNative.sqf').read_text()
assert 'PREP(treatmentNative);' in PREP
assert 'ACM_core_fnc_treatmentNative' in public
assert 'ACME_native_fnc_treatment' not in public and 'ACME_native_fnc_treatment' not in CFG
assert 'ACME_fnc_procedureActionAllowed' in public
assert 'ACME_treatmentPreflightActive' in public
assert 'ACEFUNC(common,progressBar)' in native
assert not (ROOT/'addons/acm_extended/overrides/fn_treatment.sqf').exists()
assert not any((ROOT/'addons/acm_extended/overrides').glob('*.sqf'))
print('fork phase 15 treatment ownership checks: PASS')
