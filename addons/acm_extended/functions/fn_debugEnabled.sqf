// the shared debug gate for ACE actions and runtime debug tools.
// it accepts the CBA global var, the missionnamespace value, the uinamespace value or the emergency force flag.
private _enabled = false;
if (!isNil "ACME_debug_enabled") then { _enabled = _enabled || {ACME_debug_enabled}; };
_enabled = _enabled || {missionNamespace getVariable ["ACME_debug_enabled", false]};
_enabled = _enabled || {uiNamespace getVariable ["ACME_debug_enabled", false]};
_enabled = _enabled || {missionNamespace getVariable ["ACME_debug_forceOverlay", false]};
_enabled
