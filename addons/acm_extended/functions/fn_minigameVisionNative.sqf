/* Share one ACM Extended focus effect across procedure displays.
   The historical function name is retained for callers. Native NV resources stay untouched. */
disableSerialization;
params [["_display", displayNull, [displayNull]], ["_acquire", true, [true]]];
if (!hasInterface) exitWith {};
private _users = (uiNamespace getVariable ["ACME_NV_FocusUsers", []]) select {
    !isNull _x && {_x getVariable ["ACME_NV_Active", false]}
};
if (_acquire && {!isNull _display}) then {_users pushBackUnique _display;} else {_users = _users - [_display];};
uiNamespace setVariable ["ACME_NV_FocusUsers", _users];
private _amount = missionNamespace getVariable ["ACME_minigameNV_focusBlur", 0.35];
if (!(_amount isEqualType 0) || {!finite _amount}) then {_amount = 0.35;};
_amount = _amount max 0 min 1;
private _handle = uiNamespace getVariable ["ACME_NV_FocusHandle", -1];
if (_users isEqualTo [] || {_amount <= 0}) exitWith {
    if (_handle >= 0) then {ppEffectDestroy _handle;};
    uiNamespace setVariable ["ACME_NV_FocusHandle", -1];
    uiNamespace setVariable ["ACME_NV_FocusAmount", -1];
};
if (_handle < 0) then {
    // Allocation failure leaves NV unchanged. Never reuse another mod's effect handle.
    private _retry = uiNamespace getVariable ["ACME_NV_FocusRetry", 0];
    if (diag_tickTime >= _retry) then {
        for "_i" from 0 to 7 do {
            _handle = ppEffectCreate ["DynamicBlur", 17490 + _i];
            if (_handle >= 0) exitWith {};
        };
        uiNamespace setVariable ["ACME_NV_FocusRetry", diag_tickTime + 2];
        if (_handle >= 0) then {
            _handle ppEffectEnable true;
            _handle ppEffectForceInNVG true;
            uiNamespace setVariable ["ACME_NV_FocusHandle", _handle];
            uiNamespace setVariable ["ACME_NV_FocusAmount", -1];
        };
    };
};
if (_handle >= 0 && {_amount != (uiNamespace getVariable ["ACME_NV_FocusAmount", -1])}) then {
    _handle ppEffectAdjust [_amount];
    _handle ppEffectCommit 0;
    uiNamespace setVariable ["ACME_NV_FocusAmount", _amount];
};
