// inflict blast lung, a primary blast injury, or pulmonary barotrauma.
// this is the injury that makes a ventilator genuinely necessary. the overpressure wave shreds the
// alveolar-capillary interface: the lungs flood and stiffen, gas exchange collapses, and the casualty cannot be
// fixed with an NPA and a bag. they need a secured airway, a high FiO2 and mechanical ventilation, and because
// the lung is stiff, volume control will drive the pressure into barotrauma territory and make it worse.
// pressure control is the right answer.
// it is deliberately rare and circumstantial: explosive and blast damage only.
// call it as [_patient, _severity] call ACME_fnc_blastLungInflict, where _severity is 0 to 1 and defaults to
// scaling from the damage.
params ["_patient", ["_severity", 0.5]];
// the system toggle, read live, so unticking blast lung in addon options stops this system immediately and
// completely with no mission restart.
if !(missionNamespace getVariable ["ACME_sys_blastLung", true]) exitWith {};
if (isNull _patient || {!alive _patient} || {!(_patient isKindOf "CAManBase")}) exitWith {};

_severity = (_severity max 0.15) min 1;

// stacking: a second blast worsens an existing blast lung rather than replacing it.
private _existing = _patient getVariable ["ACME_blastLung_State", 0];
private _new = ((_existing + _severity) min 1);
[_patient, _new, true, false] call ACME_fnc_blastLungStateCommit;
[_patient, "KEEP", (if (_existing <= 0) then {CBA_missionTime} else {"KEEP"}), CBA_missionTime, true] call ACME_fnc_blastLungEpisodeCommit;

// a primary blast injury frequently tears lung parenchyma, so there is a real chance of an accompanying
// pneumothorax, which is exactly why blast casualties need their chest checked before they go on a vent.
if ((random 1) < ((missionNamespace getVariable ["ACME_blastLung_ptxChance", 0.35]) * _new)) then {
    // A discrete new blast can renew a leak even during existing tension.
    if (!(_patient getVariable ["ACM_breathing_ChestInjury_State", false])) then {
        [_patient, true] call ACM_breathing_fnc_setChestInjuryState;
    };
    [_patient] call ACM_breathing_fnc_handlePneumothorax;
};

// blast lung hurts and drives the respiratory rate up, because the casualty is air-hungry.
[_patient, (0.3 * _new)] call ace_medical_fnc_adjustPainLevel;
