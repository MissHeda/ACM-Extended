#!/usr/bin/env python3
"""Phase 121: Narc Box source columns are wide enough and carousel navigation has no interpolated motion."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
F=ROOT/'addons/acm_extended/functions'
inject=(F/'fn_skInject.sqf').read_text()
dynamic=(F/'fn_skDynamicLayout.sqf').read_text()
render=(F/'fn_skCarouselRender.sqf').read_text()
move=(F/'fn_skCarouselMove.sqf').read_text()
assert '_uiW / 5.25' in inject and 'call ACME_fnc_uiCanvas' in inject
assert 'private _rightX' in inject and 'displayCtrl 84006' in inject and 'displayCtrl 84007' in inject
assert '_nativeMedGeometry ctrlSetPosition [_rightX' in inject
assert '_medCaption ctrlSetPosition [_rightX' in inject
assert '_duration = 0;' in dynamic
assert '_duration = 0;' in render
assert 'waitAndExecute' not in move and '_motion' not in move
assert 'call ACME_fnc_skSelectStored' in move and 'call ACME_fnc_skBuildHotspots' in move
assert '[0] call ACME_fnc_skDynamicLayout' in move and '[0] call ACME_fnc_skCarouselRender' in move
print('PASS phase121: Narc Box lists widened and carousel motion commits are immediate')
