// play the chest seal one-shot, and refuse to start a second copy while the first is still sounding.
// call it as [] call ACME_fnc_chestSealSnd.
//
// WHY IT EXISTS.
// the peel moves one frame per scroll notch, and a notch can arrive as fast as a hand can turn a wheel. every
// notch that starts or finishes a peel plays the seal one-shot, so a fast roll stacked several copies of the
// same 2.17 second clip on top of each other and the result was a loud smear rather than a sound.
//
// IT GUARDS THE AUDIO AND NOTHING ELSE.
// the wheel is NOT rate limited. a refused sound does not refuse the notch, so the peel still advances a frame,
// the burp still fires at full lift, and the medic works as fast as they want. only the second copy of the clip
// is dropped.
// dropping is the right answer rather than queuing. a queued copy would arrive after the motion that earned it
// had finished, so the sound would trail the hand and get further behind the longer the roll went on.
//
// THE CLOCK IS diag_tickTime AND THAT IS DELIBERATE.
// this is a real time cooldown on a real time sound, on one machine, and it must not stretch or pause with
// anything the mission does to its own clock. it is also never broadcast, so the two machines cannot disagree
// about it.
//
// THE LENGTH IS MEASURED, NOT TYPED. ffprobe reports sound/chest_seal_sfx.ogg at 2.171088 seconds. the knob
// carries that value, so re-cutting the audio means changing one number here rather than hunting the play sites.
if (!hasInterface) exitWith {false};

private _now = diag_tickTime;
private _until = uiNamespace getVariable ["ACME_CS_sndUntil", -1];
if (!(_until isEqualType 0) || {!finite _until}) then { _until = -1; };

// still sounding. drop this copy and say so, so a caller that wants to know can branch on it.
if (_now < _until) exitWith {false};

private _len = missionNamespace getVariable ["ACME_cs_sealSndLen", 2.171];
if (!(_len isEqualType 0) || {!finite _len} || {_len <= 0}) then { _len = 2.171; };

uiNamespace setVariable ["ACME_CS_sndUntil", _now + _len];
playSound "ACM_ChestSeal_Apply";
true
