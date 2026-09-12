private _display = findDisplay 86000;
if (isNull _display) exitWith {[]};

private _patient = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
if (isNull _patient) exitWith {[]};

private _bodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _selectedIV = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _accessSite = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
private _inventoryMode = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_Inventory", 0];

private _ctrlInventoryPanel = _display displayCtrl 86005;
private _row = lbCurSel _ctrlInventoryPanel;
if (_row < 0) exitWith {[]};

private _data = _ctrlInventoryPanel lbData _row;
if (_data == "") exitWith {[]};

private _parts = _data splitString "|";
if ((count _parts) < 2) exitWith {[]};

private _itemClass = _parts select 0;
private _actionClass = _parts select 1;
private _vehicle = objectParent ACE_player;
private _target = [ACE_player, _patient, _vehicle] select _inventoryMode;

[_patient, _bodyPart, _selectedIV, _accessSite, _inventoryMode, _target, _itemClass, _actionClass, _vehicle]
