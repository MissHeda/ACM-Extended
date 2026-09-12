// osmotherapy: HTS and mannitol step-lower the ICP proxy, raising the serum na+, with a sodium ceiling so you
// cannot infinitely osmo your way out, and above it it stops helping.
// there are two callers.
// continuous: handleinfusions passes the ml delivered this tick, quietly.
// bolus: a push action passes the full dose, with verbose feedback.
// _agent is "HTS3" or "Mannitol".
// _dose is the delivered amount this call, in ml, or in g for mannitol.
// _quiet at true means no player-facing messages, which is the per-tick continuous path.
params ["_patient", ["_agent", "HTS3"], ["_dose", 250], ["_quiet", false]];
if (isNull _patient) exitWith {false};
if (_dose <= 0) exitWith {false};

private _state = _patient getVariable ["ACME_tbi_State", createHashMap];
if (count _state == 0) exitWith {false};

private _sodium = _state getOrDefault ["sodium", 140];
private _sodiumCeil = missionNamespace getVariable ["ACME_tbi_sodiumCeiling", 160];  // todo[ref]: the soft na+ cap.

// above the ceiling, osmotherapy stops helping, and arguably harms.
if (_sodium >= _sodiumCeil) exitWith {
    if (!_quiet) then {
        ["Sodium ceiling reached - osmotherapy ineffective.", 1.5, ACE_player] call ace_common_fnc_displayTextStructured;
    };
    false
};

private _potency = missionNamespace getVariable [format ["ACME_tbi_osmICPdrop_%1", _agent], 8];  // todo[ref], per agent.
private _sodiumRise = missionNamespace getVariable [format ["ACME_tbi_osmNaRise_%1", _agent], 3];  // todo[ref], per agent.
private _refDose = missionNamespace getVariable [format ["ACME_tbi_osmRefDose_%1", _agent], 250];

private _icp = _state getOrDefault ["icp", 10];
private _scale = _dose / (_refDose max 1);
private _baseICP = missionNamespace getVariable ["ACME_tbi_baseICP", 10];
// OSMOTHERAPY CAN NEVER RAISE ICP.
// this was (_icp - drop) max _baseICP, and _baseICP is 10. head elevation eases ICP down with a floor of 0, in
// fn_tbiHandle, so a well positioned casualty routinely sits under 10. pushing HTS on that casualty ran
// (2 - 8) max 10 and SET THE ICP TO 10, so the correct treatment made the number worse.
// the floor still holds, because osmotherapy cannot dry a brain below its normal pressure. the result is simply
// clamped to the value it started at, so the push either lowers the ICP or does nothing.
private _icpNew = ((_icp - (_potency * _scale)) max _baseICP) min _icp;
_icp = _icpNew;
_sodium = (_sodium + (_sodiumRise * _scale)) min _sodiumCeil;

_state set ["icp", _icp];
_state set ["sodium", _sodium];
// stamp the bolus time. the severity-recovery term of fn_tbihandle multiplies the heal rate for a window after
// this, so a real HTS or mannitol push actively treats the underlying process, pulling water out of the brain,
// rather than only the ICP reading. the recovery still requires the physiology gates to be met, and this only
// speeds it when they are.
_state set ["lastOsmoTime", CBA_missionTime];
[_patient, _state] call ACME_fnc_tbiStateCommit;

if (!_quiet) then {
    private _headroom = (_sodiumCeil - _sodium) max 0;
    [format ["%1 bolus: ICP %2, Na+ %3 (%4 to ceiling)", _agent, round _icp, round _sodium, round _headroom], 2, ACE_player] call ace_common_fnc_displayTextStructured;
    // the activity-log line is removed, because it revealed the condition of the patient.
};
true
