// what the capnograph is actually drawing.
// call it as [_patient] call ACME_fnc_capnoMorph, which returns [_shape, _severity].
// the number on an EtCO2 monitor tells you how much. the shape tells you why, and the shape is where all the
// teaching is. a medic who reads waveforms diagnoses a problem before the number has finished moving.
// the shapes, and what each one means:
// "flat" is nothing, with no CO2 coming back at all. on an intubated casualty this is the single most important
// trace in medicine, because the tube is not in the trachea. it is also what a dead patient with no circulation
// looks like, which is why it is read together with everything else.
// "shark" is a slow, sloping upstroke that never reaches a plateau. it is obstructive: the alveoli are emptying at
// different rates because the airways are narrowed. that is bronchospasm.
// "cleft" is a normal plateau with a notch bitten out of it. the patient took a breath. on a paralyzed casualty
// that means the paralytic is wearing off, and on a sedated one it means they are waking up and fighting the
// machine. either way somebody needs to know now.
// "normal" is a fast upstroke, a near-flat alveolar plateau and a sharp downstroke.
// the severity runs 0 to 1 and scales how pronounced the shape is, so a trace degrades gradually rather than
// switching between two cartoons.
params ["_patient"];
if (isNull _patient) exitWith { ["normal", 0] };

// a tube that is in and a machine that is running, and no gas coming back, is the one that has to win over
// everything else. it is also the only capnograph reading that is a diagnosis on its own.
if (_patient getVariable ["ACME_ETT_Inserted", false]
    && {(_patient getVariable ["ACME_ETT_Depth", 1]) < 0.999}
    && {(_patient getVariable ["ACME_ETT_Obstructing", false])}) exitWith { ["flat", 1] };

// dyssynchrony is owned by fn_ventDriveTick from actual unresolved respiratory effort/coughing. A fully
// paralyzed but awake patient cannot physically create a curare cleft simply by being aware; their awareness
// remains a separate hemodynamic/RSI error. As respiratory effort returns or misses the trigger window, the
// ventilator publishes the real coordination problem here.
private _cleft = 0;
if (_patient getVariable ["ACME_vent_driving", false]) then {
    _cleft = (_patient getVariable ["ACME_vent_dyssync", 0]) max 0 min 1;
};

// obstructive.
// fluid in the airway narrows it, and so does a tube that has migrated far enough to sit against the wall. no new
// state is invented, because both of these already exist and are already being tracked.
private _obstruct = 0;
private _fluid = (_patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0])
    max (_patient getVariable ["ACM_airway_AirwayObstructionBlood_State", 0]);
if (_fluid > 0) then { _obstruct = _obstruct max ((_fluid / 3) min 1); };
private _depth = _patient getVariable ["ACME_ETT_Depth", 1];
if ((_patient getVariable ["ACME_ETT_Inserted", false]) && {_depth < 0.85}) then {
    _obstruct = _obstruct max (linearConversion [0.85, 0.3, _depth, 0, 1, true]);
};

// a cleft outranks a shark fin when both are present, because somebody breathing against a machine is the more
// urgent of the two and the notch is the more legible sign.
if (_cleft > 0.12) exitWith { ["cleft", _cleft] };
if (_obstruct > 0.12) exitWith { ["shark", _obstruct] };
["normal", 0]
