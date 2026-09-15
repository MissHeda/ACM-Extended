#include "..\script_component.hpp"
/*
 * Author: Blue
 * Check if surgical airway can be established on patient.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call ACM_airway_fnc_canEstablishSurgicalAirway;
 *
 * Public: No
 */

params ["_medic", "_patient"];

if ((!(IS_UNCONSCIOUS(_patient)) && alive _patient) || HAS_SURGICAL_AIRWAY(_patient)) exitWith {
    false;
};

// B127: establishSurgicalAirway marks the casualty InProgress immediately before handing lifetime ownership to
// beginContinuousAction. Do not expose the action while another maneuver already owns that controller, otherwise a
// rejected start can leave a phantom SurgicalAirway_InProgress state on the casualty.
!(missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false])
&& {!(alive (_patient getVariable [QEGVAR(breathing,BVM_Medic), objNull]))}
&& {!(alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull]))}
&& {!(_patient getVariable [QGVAR(SurgicalAirway_InProgress), false])};