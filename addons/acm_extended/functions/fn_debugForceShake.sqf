// cycle the cabin-motion test switch: off, then cruise, then hard bank, then off.
// this exists because there is no shake has several causes that look identical from outside fn_motionshake, and
// four builds went into guessing at them one at a time. you can stand on the ground now, open any minigame, and
// know in ten seconds whether the motion system is alive and what it feels like at each level, with no test flight
// and no debug console.
private _v = missionNamespace getVariable ["ACME_motion_force", 0];
_v = (_v + 1) % 3;
missionNamespace setVariable ["ACME_motion_force", _v, true];

private _msg = switch (_v) do {
    case 1: {"Force shake: CRUISE. Open a minigame."};
    case 2: {"Force shake: HARD BANK."};
    default {"Force shake: OFF. Motion is back to reading the real vehicle."};
};
[_msg, 2] call ace_common_fnc_displayTextStructured;
