// the ventilator as a treatment rather than only a hazard.
// until now the vent could only hurt, through barotrauma, gas trapping and over-ventilation. it had no way to
// actually fix a lung, because nothing turned its settings into oxygenation. this is that missing half, and it
// is built on the one concept that makes ventilator management make sense: shunt, which is blood flowing past
// alveoli that are not participating, because they are flooded, collapsed or squashed.
// shunt is why a drowning patient on 100 percent oxygen still desaturates: you cannot fix a flooded alveolus by
// putting richer air into the alveoli next door. FiO2 chases a shunt and loses. PEEP does not, because it
// splints the alveoli open through expiration so they can take part again, which is why PEEP rather than oxygen
// is the treatment for pulmonary edema and ARDS.
// the crucial split, and the whole lesson of this function, is this.
// a recruitable shunt is flooded or collapsed alveoli, from edema or blast lung. PEEP opens these, so it is
// treatable.
// a fixed shunt is a pneumothorax or a hemothorax. the lung is compressed rather than collapsed. PEEP does not
// open it and makes it worse. only a needle, a finger or a drain fixes this, and if you reach for PEEP instead
// you will tension them.
// call it as [_patient, _comp, _peep, _fio2, _recruit] call ACME_fnc_ventOxygenation.
params ["_patient", "_comp", "_peep", "_fio2", "_recruit"];

private _overload = _patient getVariable ["ACM_circulation_Overload_Volume", 0];  // fluid overload gives pulmonary edema.
private _ptx      = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _htxFluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];
private _blast    = _patient getVariable ["ACME_blastLung_State", 0];

// where is the shunt, and can PEEP reach it?
private _edemaN = linearConversion [0.2, 1.6, _overload, 0, 1, true];
private _blastN = _blast;
private _ptxN   = linearConversion [0, 3, _ptx, 0, 1, true];
private _htxN   = linearConversion [0, 1500, _htxFluid, 0, 1, true];

// recruitable: alveoli that are flooded or collapsed and still connected to an airway. PEEP splints them
// open.
private _shuntRecruitable = (0.38 * _edemaN) + (0.42 * _blastN);
// fixed: air or blood in the pleural space is crushing the lung. there is nothing for PEEP to splint open, and
// pushing harder only forces more air into the pleura. decompress it, drain it, then ventilate it.
private _shuntFixed = (0.40 * _ptxN) + (0.30 * _htxN);

// PEEP: how much of the recruitable shunt does it actually open?
// recruitment climbs from about 5 up to about 15 cmH2O, which is the range people actually use in ARDS. below 5
// you are letting the lung fall shut every breath, and above about 16 you stop recruiting and start
// overdistending: stretching the healthy alveoli that were doing the work, squeezing their capillaries, and
// making the shunt worse. that is the real trap of PEEP, and it is why more is not better.
private _peepRecruit = linearConversion [4, 15, _peep, 0, 1, true];
private _overdistend = linearConversion [16, 24, _peep, 0, 1, true];

// a long inspiratory time recruits too. this is what ACME_vent_recruit was computed for and never used.
private _openFrac = ((_peepRecruit * 0.85) + (_recruit * 0.30)) min 1;

private _shunt = _shuntFixed
    + (_shuntRecruitable * (1 - _openFrac))  // PEEP shrinks the treatable part.
    + (0.22 * _overdistend);  // and too much PEEP creates new shunt out of good lung.
_shunt = (_shunt max 0) min 0.75;
[_patient, _shunt, true, false] call ACME_fnc_ventShuntCommit;

// oxygenation.
// a shunt sets a ceiling that oxygen cannot beat. this is the single most important line in the file.
// blood that never meets a working alveolus arrives back unoxygenated whatever mixture is in the alveoli it
// missed. so the shunt fixes the best saturation obtainable, and FiO2 can only move you up to that ceiling and
// never past it. wind the oxygen to 100 percent on a flooded lung and you will watch the number stall in the
// eighties.
// that stall is the lesson. it is the moment a medic should stop reaching for the oxygen and start reaching for
// PEEP, or, if the shunt is a pneumothorax, for a needle. reaching for more FiO2 instead is the classic error,
// and it is now a mistake the sim will let them make and then quietly kill the patient with.
private _ceiling = 99 - (_shunt * 52);

// FiO2 lifts you toward the ceiling. with no shunt, room air is already fine and oxygen adds nothing, which is why
// an uninjured casualty does not benefit from being wound up to 100 percent. with a shunt, oxygen buys back part
// of the gap, and only part, and never the ceiling itself.
// on altitude: the percentage on the dial is not what reaches the alveoli. what matters is the pressure driving it
// in, and that falls as you climb. so the same FiO2 buys less oxygen up high, and a patient you had stable on the
// ground drifts down on the way up. winding the FiO2 higher is the correct answer, and now it is also a possible
// one, because FiO2 is finally graded. fn_altitudetick publishes the ratio, and at sea level it is 1.0 and this
// line changes nothing.
private _pRatio = _patient getVariable ["ACME_alt_pRatio", 1];
private _fio2Eff = ((_fio2 / 100) * _pRatio) max 0.21;
private _fio2Lift = linearConversion [0.21, 1.0, _fio2Eff, 0, 1, true];
private _targetSat = _ceiling - ((1 - _fio2Lift) * (_shunt * 30));

// a lung that is simply too stiff to move gas cannot oxygenate whatever mixture you offer it.
if (_comp < 0.35) then {
    _targetSat = _targetSat - (linearConversion [0.35, 0.20, _comp, 0, 8, true]);
};

((_targetSat max 55) min 99)
