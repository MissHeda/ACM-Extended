#!/usr/bin/env python3
"""Static checks for the NA8.1 IV and premixed infusion hotfix."""
from __future__ import annotations

from pathlib import Path
import argparse
import re
import sys

EXPECTED_VERSION = "0.9.999r-73-NA8.1"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("addon", nargs="?", type=Path, default=Path("."))
    ap.add_argument("--version", default=EXPECTED_VERSION, help="Exact expected build version; defaults to NA8.1")
    args = ap.parse_args()
    root = args.addon.resolve()
    cfg = (root / "config.cpp").read_text(encoding="utf-8-sig")
    post = (root / "functions/fn_postInit.sqf").read_text(encoding="utf-8-sig")
    sync = (root / "functions/fn_syncPremixedBags.sqf").read_text(encoding="utf-8-sig")
    ivinit = (root / "functions/fn_ivMinigameInit.sqf").read_text(encoding="utf-8-sig")

    checks: list[tuple[str, bool]] = []
    checks.append(("config version", f'version = "{args.version}";' in cfg))
    checks.append(("runtime version", f'ACME_infusion_version = "{args.version}";' in post))

    expected_callbacks = [
        'callbackSuccess = "[_medic, _patient, toLower _bodyPart, \'lower\'] call ACME_fnc_ivMinigameOpen";',
        'callbackSuccess = "[_medic, _patient, \'ej\', \'left\'] call ACME_fnc_ivMinigameOpen";',
        'callbackSuccess = "[_medic, _patient] call ACME_fnc_removeEJ";',
    ]
    for i, line in enumerate(expected_callbacks, 1):
        checks.append((f"medical callback {i}", cfg.count(line) == 1))

    unsafe = re.findall(r'callbackSuccess\s*=\s*"[^"\n]*\b_player\b[^"\n]*"\s*;', cfg, flags=re.I)
    checks.append(("no _player in treatment success callbacks", not unsafe))

    checks.append(("old unsafe premix params removed", 'params [["_only", objNull]];' not in sync))
    checks.append(("premix type guards object candidate", '_candidate isEqualType objNull' in sync))
    checks.append(("remote premix routes to patient owner", 'CBA_fnc_targetEvent' in sync and 'ACME_syncPremixedBagsLocal' in sync))
    checks.append(("premix event receiver registered", '["ACME_syncPremixedBagsLocal", {' in post))
    checks.append(("premix receiver requires locality", '!isNull _patient && {local _patient}' in post))
    checks.append(("medical menu passes target explicitly", '[_target] call ACME_fnc_syncPremixedBags;' in post))
    checks.append(("PFH passes explicit empty args", '[{[] call ACME_fnc_syncPremixedBags}, 1, []]' in post))

    bare = [line.strip() for line in post.splitlines() if line.strip() == 'call ACME_fnc_syncPremixedBags;']
    checks.append(("no bare premix calls in postInit", not bare))

    # NA8.5-B1 removes RPT markers. Inspect the actual layout/refresh calls rather than diagnostic strings.
    site_i = ivinit.find('call ACME_fnc_ivSiteData')
    body_i = ivinit.find('uiNamespace setVariable ["ACME_IV_BodyRect"')
    pfh_i = ivinit.find('uiNamespace setVariable ["ACME_IV_PFH", _pfh]')
    ready_i = ivinit.find('[] call ACME_fnc_ivMinigameRefreshBandSlot;')
    light_i = ivinit.find('call ACME_fnc_installLightKey')
    checks.append(("IV layout stages present", -1 not in [site_i, body_i, pfh_i, ready_i]))
    checks.append(("IV core layout stages ordered", 0 <= site_i < body_i < pfh_i < ready_i))
    checks.append(("flashlight bridge runs after core IV init", ready_i >= 0 and light_i > ready_i))
    checks.append(("flashlight bridge isolated next frame", 'CBA_fnc_execNextFrame' in ivinit[ready_i:]))

    failed = [name for name, ok in checks if not ok]
    for name, ok in checks:
        print(("PASS " if ok else "FAIL ") + name)
    print(f"NA8.1 checks: {len(checks)-len(failed)}/{len(checks)}")
    return int(bool(failed))


if __name__ == "__main__":
    raise SystemExit(main())
