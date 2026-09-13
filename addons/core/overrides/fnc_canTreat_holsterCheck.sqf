#include "..\script_component.hpp"
/*
 * ACE holster eligibility with one narrow ACME exception.
 *
 * Direct Pressure deliberately does not change the provider's selected weapon. The visible pressure pose owns the
 * provider's hands, but ACE's stock holster check only sees currentWeapon/weaponLowered. That made otherwise valid
 * medical-menu actions fail their eligibility check while Direct Pressure was active, including Stop Direct Pressure.
 *
 * While the provider is actively holding pressure on this same patient, treat the weapon requirement as satisfied.
 * Every other ACE treatment eligibility rule still runs normally in canTreat/canTreatCached.
 */
params ["_medic", "_patient", "_config"];

if (
    !isNull _medic
    && {_medic getVariable ["ACME_DP_Active", false]}
    && {(_medic getVariable ["ACME_DP_Patient", objNull]) isEqualTo _patient}
) exitWith {true};

ACEGVAR(medical_treatment,holsterRequired) == 0
|| {!isNull objectParent _medic}
|| {!isNull objectParent _patient}
|| {(ACEGVAR(medical_treatment,holsterRequired) in [2,4]) && {getText (_config >> "category") == "examine"}}
|| {currentWeapon _medic isEqualTo ""}
|| {(ACEGVAR(medical_treatment,holsterRequired) <= 2) && {weaponLowered _medic}}
