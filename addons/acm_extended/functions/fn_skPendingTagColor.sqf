/* B62: select the optional tag for the syringe currently being prepared. Single-click selection is backed by
   both LBSelChanged and MouseButtonUp in fn_skInject, and the row is always cleared for same-color reuse. */
disableSerialization;
params ["_ctrl", "_row"];
if (_row < 0) exitWith {};
private _id = _ctrl lbData _row;
if (_id == "") then {_id = "none";};
uiNamespace setVariable ["ACME_SK_PendingTagColor", _id];
_ctrl lbSetCurSel -1;
_ctrl ctrlShow false;
call ACME_fnc_skPendingTagRender;
if !(_id in ["","none"]) then {
    [{
        disableSerialization;
        private _d = findDisplay 84000;
        if (!isNull _d) then {ctrlSetFocus (_d displayCtrl 84601);};
    },[],0.01] call CBA_fnc_waitAndExecute;
};
