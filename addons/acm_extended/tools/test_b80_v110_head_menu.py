from historical_source import read_source
from pathlib import Path
import pytest
from historical_source import assert_release_identity
ROOT=Path(__file__).resolve().parents[1]
def txt(p): return read_source(ROOT/p, encoding='utf-8',errors='ignore')
checks=[]
def check(name, ok):
    checks.append((name,bool(ok)))

cfg=txt('config.cpp'); post=txt('functions/fn_postInit.sqf'); dbg=txt('functions/fn_debugMenu.sqf')
seq=txt('functions/fn_headElevMedicSeq.sqf'); tilt=txt('functions/fn_headElevApplyTilt.sqf')
stop=txt('functions/fn_headElevateStop.sqf'); susp=txt('functions/fn_headElevSuspend.sqf')
prep=txt('functions/fn_medicAnimationPrep.sqf'); menu=txt('overrides/fn_updateActions.sqf')
check('debug reads runtime version', 'ACME_infusion_version' in dbg and 'ACME DEBUG v%2' in dbg)
check('provider DraggerBase wrapper', 'class ACME_HeadElevProviderLift: DraggerBase' in cfg)
check('patient grab wrapper exact RTM inheritance', 'class ACME_HeadElevPatientGrab: AinjPpneMrunSnonWnonDb_grab' in cfg)
check('patient release wrapper exact RTM inheritance', 'class ACME_HeadElevPatientRelease: AinjPpneMrunSnonWnonDb_release' in cfg)
check('provider sequence uses lift wrapper', '_dragger = "ACME_HeadElevProviderLift"' in seq)
check('provider waits for one preflight', '_prepUntil' in seq and 'currentWeapon _u == ""' in seq)
check('duplicate holster suppression', '_elapsed < 1.10' in prep and 'empty_hands_once' in prep)
check('patient elevate uses wrapper', '"ACME_HeadElevPatientGrab"' in tilt)
check('patient lower uses wrapper', '"ACME_HeadElevPatientRelease"' in stop)
check('patient suspend uses wrapper', '"ACME_HeadElevPatientRelease"' in susp)
check('alternate row color now white', 'ACME_menuRowColorAlternate = [1, 1, 1, 1];' in post)
check('renderer does not alternate ordinary rows', "select (_actionIndex mod 2)" not in menu and "ACME_menuRowColorDefault" in menu)
@pytest.mark.parametrize("name,ok", checks, ids=[c[0] for c in checks])
def test_historical_head_menu_contract(name, ok):
    assert ok, name


def test_release_identity():
    assert_release_identity()
