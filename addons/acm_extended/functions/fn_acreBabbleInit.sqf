// register the obtunded language with acre2, if acre2 is even here.
// call ACME_fnc_acreBabbleInit once, from postinit, on a client.
// the babel system of acre2 garbles speech from anyone talking a language you do not know. B65 only switches an
// obtunded casualty into this synthetic language for brief, speech-aware pulses; their real language is the default
// between pulses and the whole mechanism is hard-gated by ACME_sys_obtunded.
// everything here is guarded. if acre2 is absent, or this build of it names its api differently, every call below
// simply does not happen and obtundation behaves exactly as it did before. there is no hard dependency and no
// error.
if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["ACME_acre_babbleReady", false]) exitWith { [false, false, true] call ACME_fnc_acreBabbleSet; };

// is acre2 actually loaded? check the addon rather than a single function, because function names move between
// versions and the addon name does not.
private _hasAcre = isClass (configFile >> "CfgPatches" >> "acre_main");
missionNamespace setVariable ["ACME_acre_present", _hasAcre];
if (!_hasAcre) exitWith {};

// Do not even register the synthetic language until the mission's Obtundation master is ON.  The master callback
// calls this initializer when an admin enables the system later in a running mission.
if !(missionNamespace getVariable ["ACME_sys_obtunded", false]) exitWith {
    [false, false, true] call ACME_fnc_acreBabbleSet;
};
if (!(missionNamespace getVariable ["ACME_acre_babbleEnable", false])) exitWith {};

// the language has to exist before anyone can be set to speak it. it is named so it is obvious in any acre debug
// output what it is and where it came from.
private _id = missionNamespace getVariable ["ACME_acre_babbleId", "ACME_Obtunded"];
if (!isNil "acre_api_fnc_babelAddLanguageType") then {
    [_id, "Obtunded"] call acre_api_fnc_babelAddLanguageType;
};

missionNamespace setVariable ["ACME_acre_babbleReady", true];
// Startup sanitation: a client may carry stale ACRE language state from an interrupted/reloaded session.
[false, false, true] call ACME_fnc_acreBabbleSet;
