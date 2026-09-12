// an ACE treatment-action condition. the framework passes [_medic, _patient, _bodyPart], where the body part is a
// string.
// show auto bp only when an AED is on the patient, mirroring ACM's own aed_canmeasurebp gate, including the body
// fallback to an unspecified-part AED.
params ["_medic", "_patient", ["_bodyPart", ""]];
if (isNull _patient) exitWith {false};
if (isNil "ACM_circulation_fnc_hasAED") exitWith {false};

// guard the type: _bodyPart must be a string for hasaed.
if !(_bodyPart isEqualType "") then {_bodyPart = ""};

private _hasAED = [_patient, _bodyPart, 3] call ACM_circulation_fnc_hasAED;
if (!_hasAED && {_bodyPart == "body"}) then {
    _hasAED = [_patient, "", 3] call ACM_circulation_fnc_hasAED;
};
_hasAED
