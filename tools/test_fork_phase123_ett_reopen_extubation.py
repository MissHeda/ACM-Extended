#!/usr/bin/env python3
"""Phase 123: ETT reopen reconstructs persisted geometry and extubation requires collar-off/cuff-down."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
F=ROOT/'addons/acm_extended/functions'
open_=(F/'fn_laryngoOpen.sqf').read_text()
init=(F/'fn_laryngoInit.sqf').read_text()
ext=(F/'fn_laryngoExtubate.sqf').read_text()
cfg=(ROOT/'addons/acm_extended/config.cpp').read_text()
assert 'if (_patient getVariable ["ACME_ETT_Secured", false]) then' in open_
assert '0.999' not in open_[open_.index('// already intubated'):open_.index('// can this airway')]
secured=init[init.index('if (uiNamespace getVariable ["ACME_laryngo_reopenSecured"'):init.index('// coming back to a tube')]
assert 'ACME_ETT_Depth' in secured and '[_dsp, _savedDepth] call ACME_fnc_laryngoTubeFrames' in secured
resume=init[init.index('if (uiNamespace getVariable ["ACME_laryngo_resume"'):init.index('// suction mode.')]
for token in ['ACME_ETT_CuffInflated','ACME_ETT_TipFrac','ACME_laryngo_tubeAnchorRel','ACME_fnc_laryngoTubePose']:
    assert token in resume
assert 'if (_cuffUp) then' in resume and 'ACME_laryngo_state", "cuff"' in resume
assert 'ACME_ETT_Secured' in ext and 'ACME_ETT_CuffInflated' in ext
block=cfg[cfg.index('class ACME_Extubate'):cfg.index('class ACME_OpenAirwayView')]
assert "!(_patient getVariable ['ACME_ETT_Secured', false])" in block
assert "!(_patient getVariable ['ACME_ETT_CuffInflated', false])" in block
print('PASS phase123: ETT reopen preserves geometry and extubation enforces collar/cuff prerequisites')
