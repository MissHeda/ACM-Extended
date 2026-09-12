#!/usr/bin/env python3
"""Phase 132: wrapped HPMK presentation has no attachTo/physics relationship with the casualty."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
vis=(R/'addons/acm_extended/functions/fn_registerHpmkVisualRuntime.sqf').read_text()
server=(R/'addons/acm_extended/functions/fn_hpmkBlanketTick.sqf').read_text()
assert 'createSimpleObject [_class' in vis
assert '_vis attachTo [_patient' not in vis
assert '_vis attachTo [_anchor' not in vis
assert 'ACME_hpmk_wrappedVisuals set [_id, [_vis, _patient]]' in vis
assert 'getPosWorldVisual _patient' in vis
assert 'vectorDirVisual _patient' in vis and 'vectorUpVisual _patient' in vis
assert '0.05, []] call CBA_fnc_addPerFrameHandler' in vis
assert 'attachTo [_p' not in server
assert 'Land_HelipadEmpty_F' in server
print('PASS phase132: HPMK blanket is a detached local visual follower and cannot form a magic-carpet attach chain')
