params ["_itemClass", ["_actionClass", ""]];

private _a = toLowerANSI _actionClass;
private _i = toLowerANSI _itemClass;

((_a find "saline") >= 0) || {(_i find "saline") >= 0}
