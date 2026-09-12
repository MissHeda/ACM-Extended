/* Native Epinephrine_IV dose is in mg. The circulation model owns the bounded pressor/HR
   response; native ACM retains medication adjustment, incompatibility, and cardiac effects.
   Coefficients below are gameplay tuning, not predictions of a real patient's MAP. */
params ["_patient", "_doseMg"];
if (isNull _patient || {!local _patient} || {!alive _patient} || {!finite _doseMg} || {_doseMg <= 0}) exitWith {};
private _mcg = _doseMg * 1000;
private _state = _patient getVariable ["ACME_circ_State", createHashMap];
private _ceiling = (missionNamespace getVariable ["ACME_circ_epiBolusMAPcap", 90]) max 1;
private _scale = (missionNamespace getVariable ["ACME_circ_epiBolusScaleMcg", 55]) max 1;
private _support = _ceiling * (1 - exp (-_mcg / _scale));
// Fast finite onset, then washout. A full 100 mcg mixture is NOT collapsed to a 10 mcg effect.
private _reserve = _state getOrDefault ["epiBolusReserve", 0];
_state set ["epiBolusReserve", (_reserve + _support) min _ceiling];
[_patient, _state] call ACME_fnc_circStateCommit;
ACME_circ_activePatients pushBackUnique _patient;
