from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
F = ROOT / "addons/acm_extended/functions"

def read(name):
    return (F / name).read_text(encoding="utf-8")

def main():
    restore = read("fn_clinicalRestore.sqf")
    reset = read("fn_clinicalReset.sqf")

    # Each owner-gated persistent family must be intercepted before the generic setVariable restore path.
    for bucket in ["_nrbRestore", "_hpmkRestore", "_obtundedRestore", "_blastRestore", "_rhythmHoldRestore"]:
        assert bucket in restore, bucket
    for fn in [
        "ACME_fnc_nrbStateCommit", "ACME_fnc_hpmkStateCommit", "ACME_fnc_obtundedStateCommit",
        "ACME_fnc_blastLungStateCommit", "ACME_fnc_blastLungArdsCommit", "ACME_fnc_rhythmNativeHoldCommit"
    ]:
        assert fn in restore, fn
        assert fn in reset, fn

    excluded = re.search(r'if \(_reset.*?!\(_name in \[(.*?)\]\)', reset, re.S)
    assert excluded, "reset exclusion list missing"
    block = excluded.group(1)
    for name in [
        "ACME_nrb_on", "ACME_nrb_hasO2", "ACME_nrb_delivering",
        "ACME_hpmk_state", "ACME_hpmk_on",
        "ACME_obtunded", "ACME_obtunded_manual", "ACME_obtunded_posture",
        "ACME_blastLung_State", "ACME_blastLung_ARDS",
        "ACME_rhythmNativeHoldKind", "ACME_rhythmNativeHoldRhythm",
    ]:
        assert name in block, name

    # Generic restore still exists for unrelated scalar state, but gated names must only appear in interception/commit code.
    generic = '_patient setVariable [_name, _value, true]'
    assert generic in restore
    print("Phase 67 persistent-state restore/reset ownership: PASS")

if __name__ == "__main__":
    main()
