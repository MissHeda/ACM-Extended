from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    p = ROOT / rel
    assert p.is_file(), f"missing {rel}"
    return p.read_text(encoding="utf-8", errors="replace")


def code_only(text: str) -> str:
    # Sufficient for regression checks: remove // comments and /* ... */ blocks.
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//.*", "", text)
    return text


moves = read("addons/core/CfgMoves.hpp")
getup = read("addons/core/functions/fnc_getUp.sqf")
getup_code = code_only(getup)
clear = read("addons/acm_extended/functions/fn_clearAllAilments.sqf")
init = read("addons/acm_extended/functions/fn_acreBabbleInit.sqf")
setf = read("addons/acm_extended/functions/fn_acreBabbleSet.sqf")
tick = read("addons/acm_extended/functions/fn_acreBabbleTick.sqf")
runtime = read("addons/acm_extended/functions/fn_initAcreBabbleRuntime.sqf")
master = read("addons/acm_extended/functions/fn_obtundedMasterChanged.sqf")
post = read("addons/core/XEH_postInit.sqf")

# Get Up root cause must remain documented in the actual move graph: this is an isolated looping state.
assert "class ACM_LyingState" in moves
lying = moves.split("class ACM_LyingState", 1)[1][:900]
assert "ConnectTo[] = {};" in lying
assert "InterpolateTo[] = {};" in lying

# Provider/self requests are routed to the patient owner.
assert 'if (!local _patient) exitWith' in getup
assert '"ACM_core_getUpRequest"' in getup
assert '[QGVAR(getUpRequest)' in post

# Priority 2 is intentional here: priority 1 cannot exit ACM_LyingState.
assert '[_patient, _roll, 2] call ACME_fnc_doAnim;' in getup
assert '[_p, _roll, 2] call ACME_fnc_doAnim;' in getup
assert '[_p, "AmovPpneMstpSnonWnonDnon", 2] call ACME_fnc_doAnim;' in getup
assert "ACME_fnc_animQueue" not in getup_code, "Get Up must not route through the priority-1 animation queue"

# Release the stale engine/ACME animation controller before consuming the action.
for token in [
    'setVariable ["ACME_animQ", [], false]',
    'setVariable ["ACME_animQEnd", 0, false]',
    'setVariable ["ACME_animQActive", false, false]',
    '"ACME_dah_gen"',
    'setUnitPos "AUTO"',
    'setUnconscious false',
    'setVariable ["ACM_core_Lying_State", false, true]',
]:
    assert token in getup, f"missing Get Up release guard: {token}"

# Two independent engine-state backstops are required so a swallowed playMove does not consume Get Up silently.
assert '], 0.15] call CBA_fnc_waitAndExecute;' in getup
assert '], 0.65] call CBA_fnc_waitAndExecute;' in getup
assert 'ace_medical_engine_uncon_anim' in getup

# Obtundation must not affect Get Up when its master is disabled.
assert 'missionNamespace getVariable ["ACME_sys_obtunded", false]' in getup
assert '&& {_patient getVariable ["ACME_obtunded", false]}' in getup

# Full-heal/Zeus cleanup must be capable of escaping the same isolated state.
assert '[_patient, "UnconsciousOutProne", 2] call ACME_fnc_doAnim;' in clear

# ACRE runtime: master OFF cannot bootstrap/register synthetic Babel.
assert 'ACME_acre_babbleId     = "ACME_Obtunded";' in runtime
assert 'ACME_acre_commonId     = "ACME_Common";' in runtime
assert 'ACME_acre_babbleReady  = false;' in runtime
assert 'ACME_acre_babbleSafe   = false;' in runtime
master_off = init.split('if !(missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith', 1)[1].split('};', 1)[0]
assert 'acre_api_fnc_babelAddLanguageType' not in master_off
assert '[false, false, true] call ACME_fnc_acreBabbleSet;' in master_off

# A module-less mission gets a deterministic non-synthetic home language BEFORE ACME_Obtunded is registered.
assert 'private _common = missionNamespace getVariable ["ACME_acre_commonId", "ACME_Common"]' in init
assert 'private _realRegistry = _languageKeys - [_id, _common];' in init
assert '[_common, "Common"] call acre_api_fnc_babelAddLanguageType;' in init
assert '[_common] call acre_api_fnc_babelSetSpokenLanguages;' in init
assert '[_common] call acre_api_fnc_babelSetSpeakingLanguage;' in init
common_pos = init.index('[_common, "Common"] call acre_api_fnc_babelAddLanguageType;')
synth_pos = init.rindex('[_id, "Obtunded"] call acre_api_fnc_babelAddLanguageType;')
assert common_pos < synth_pos

# Existing mission Babel assignments are preserved rather than guessed/replaced.
assert 'if (_realRegistry isNotEqualTo [] && {_missionKnown isEqualTo []}) exitWith {' in init
assert 'if (_realRegistry isNotEqualTo []) then {' in init
assert 'private _missionKnown = _known - [_id, _common];' in init
assert 'ACME_acre_baselineKnown' in init
assert 'ACME_acre_baselineLanguage' in init
assert 'ACME_acre_ownsFallbackCommon' in init
assert 'ACME_acre_ownsFallbackCommon = false;' in runtime
assert 'if (missionNamespace getVariable ["ACME_acre_ownsFallbackCommon", false]) then {' in tick
assert 'private _missionKeys = (_registry apply {_x param [0, ""]}) - [_id, _common];' in tick

# Current ACRE source returns a numeric registry index from the public getter despite its API docs saying string.
# ACME must accept both so restore always knows the true pre-pulse language.
for text in (init, setf):
    assert 'acre_api_fnc_babelGetSpeakingLanguageId' in text
    assert 'isEqualType ""' in text
    assert 'isEqualType 0' in text
    assert 'acre_sys_core_languages' in text

# Every pulse saves both the known-language list and exact speaking language, then restore strips the synthetic key.
for token in [
    'ACME_acre_prevKnown',
    'ACME_acre_prevLanguage',
    'ACME_acre_baselineKnown',
    'ACME_acre_baselineLanguage',
    '_restoreKnown = _restoreKnown - [_id];',
    '[_restoreKnown] call acre_api_fnc_babelSetSpokenLanguages;',
    '[_prev] call acre_api_fnc_babelSetSpeakingLanguage;',
]:
    assert token in setf, f"missing ACRE restoration invariant: {token}"

# Repair state left by older builds where ACME_Obtunded became the only registered/known language.
assert '_restoreKnown isEqualTo [] && {_realRegistry isEqualTo []} && {_id in _keys}' in setf
assert '[_common, "Common"] call acre_api_fnc_babelAddLanguageType;' in setf
assert '_restoreKnown = [_common];' in setf
assert '_prev = _common;' in setf

# Babble can only be enabled by the authorized speech scheduler, and only when safe/ready.
assert 'missionNamespace getVariable ["ACME_acre_babbleSafe", false]' in tick
assert 'missionNamespace getVariable ["ACME_acre_babbleReady", false]' in tick
assert '[true, true] call ACME_fnc_acreBabbleSet;' in tick

all_acre_sqf = list((ROOT / "addons/acm_extended/functions").glob("*.sqf"))
enable_sites = []
for p in all_acre_sqf:
    src = code_only(p.read_text(encoding="utf-8", errors="replace"))
    if re.search(r"\[\s*true\s*,\s*true\s*\]\s*call\s+ACME_fnc_acreBabbleSet", src):
        enable_sites.append(p.name)
assert enable_sites == ["fn_acreBabbleTick.sqf"], f"unexpected babble enable sites: {enable_sites}"

# Master-off callback must force restoration before releasing obtunded units.
assert '[false, false, true] call ACME_fnc_acreBabbleSet;' in master

print("PASS phase142: Get Up escapes ACM_LyingState and ACRE Babel is fail-safe without a mission module")
