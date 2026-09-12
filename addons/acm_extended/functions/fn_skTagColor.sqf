/* B62: change the selected stored syringe tag. Works only on the stable selected syringe and remains inside
   dedicated Edit Tag mode. Reset the row before/after each use so selecting the same color twice is always valid. */
disableSerialization;
params ["_c","_row"];
if (_row < 0) exitWith {};
private _id = _c lbData _row;
if (_id == "") then {_id = "none";};
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _i = [_store,false] call ACME_fnc_skSelectedIndex;
if (_i < 0) exitWith {};
private _entry = +(_store select _i);
while {count _entry < 12} do {_entry pushBack "";};
_entry set [7,_id];
_store set [_i,_entry];
[ACE_player, _store] call ACME_fnc_narcStoreCommit;
_c lbSetCurSel -1;
_c ctrlShow false;
call ACME_fnc_skCarouselRender;
if (uiNamespace getVariable ["ACME_SK_TagEditMode",false]) then {
    [{
        params ["_id"];
        disableSerialization;
        private _d = findDisplay 84000;
        if (!isNull _d && {uiNamespace getVariable ["ACME_SK_TagEditMode",false]}) then {
            private _focusCtrl = _d displayCtrl (if (_id in ["","none"]) then {84470} else {84460});
            if (!isNull _focusCtrl) then {ctrlSetFocus _focusCtrl;};
        };
    },[_id],0.01] call CBA_fnc_waitAndExecute;
};
