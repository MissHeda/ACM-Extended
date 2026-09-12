/* Use the supported patient's current body and verified elevation anchor.
   Never use a stale anchor after transport or a remote helper at map origin. */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]]];
if (isNull _medic || {isNull _patient}) exitWith {1e10};
private _distance = _medic distance _patient;
if (!isNull objectParent _medic || {!isNull objectParent _patient}) exitWith {_distance};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {_distance};
private _helper = _patient getVariable ["ACME_headElev_helper", objNull];
if (isNull _helper || {(typeOf _helper) != "ACME_RopeHelper"}
    || {attachedTo _patient != _helper}) exitWith {_distance};
private _anchor = _patient getVariable ["ACME_headElev_basePosASL", []];
if (count _anchor != 3 || {(_anchor findIf {!(_x isEqualType 0) || {!finite _x}}) >= 0}) exitWith {_distance};
if ((getPosASL _helper) vectorDistance _anchor > 2
    || {(getPosASL _patient) vectorDistance _anchor > 3}) exitWith {_distance};
_distance min ((getPosASL _medic) vectorDistance _anchor)
