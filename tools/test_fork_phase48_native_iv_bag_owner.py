from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CIRC=ROOT/"addons/circulation"
EXT=ROOT/"addons/acm_extended/functions"
prep=(CIRC/"XEH_PREP.hpp").read_text()
owner=(CIRC/"functions/fnc_setIVBagsState.sqf").read_text()
bridge=(EXT/"fn_ivBagsCommit.sqf").read_text()
assert 'PREP(setIVBagsState);' in prep
assert 'setVariable [QGVAR(IV_Bags), _bags, _public]' in owner
assert 'ACM_circulation_fnc_setIVBagsState' in bridge
assert 'setVariable ["ACM_circulation_IV_Bags"' not in bridge
for p in EXT.glob('*.sqf'):
    text=p.read_text()
    assert 'setVariable ["ACM_circulation_IV_Bags"' not in text,p.name
    for line in text.splitlines():
        assert not ('ACM_circulation_IV_Bags' in line and 'ACME_fnc_setVarNet' in line),(p.name,line.strip())
print("fork phase 48 native IV-bag ownership checks: PASS")
