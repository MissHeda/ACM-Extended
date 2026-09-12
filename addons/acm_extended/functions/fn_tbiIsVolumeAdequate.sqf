// the blood-before-pressor gate.
// pressors must not improve perfusion on a hypovolemic patient: squeezing an empty tank fakes a pressure while the
// perfusion worsens.
// this returns false when the patient is under-resuscitated, and any pressor-driven MAP support must check it first.
// when false, a pressor should provide little or no CPP benefit, and optionally a penalty, so the sim rewards blood
// first with a pressor to fine-tune, instead of a pressor instead of blood.
params ["_patient"];
if (isNull _patient) exitWith {false};

private _bloodVolume = _patient getVariable ["ACM_circulation_Blood_Volume", missionNamespace getVariable ["ACME_tbi_defaultBloodVolume", 6]];

// todo[ref]: set this to the adequate-resuscitation floor of your reference. the class-2 hemorrhage threshold of ACM
// is a reasonable anchor. above it the volume is adequate enough for a pressor to do real work, and below it blood
// comes first.
private _floor = missionNamespace getVariable ["ACME_tbi_volumeAdequateFloor", 5.1];

_bloodVolume >= _floor
