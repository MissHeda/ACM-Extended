// the severity of one alarm: 3 is HIGH and red, 2 is medium and yellow, and 1 is LOW and gray.
// it reads the same table fn_ventalarmtick uses for the audible pattern, ACME_vent_alarmHigh and _alarmmed.
// the window and the buzzer must never disagree about how bad something is: a screen that shows yellow while the
// machine screams its five-beep HIGH pattern is worse than either alone, because now the medic does not know which
// to believe.
params [["_name", ""]];
if ((missionNamespace getVariable ["ACME_vent_alarmHigh", []]) findIf {_x isEqualTo _name} >= 0) exitWith {3};
if ((missionNamespace getVariable ["ACME_vent_alarmMed",  []]) findIf {_x isEqualTo _name} >= 0) exitWith {2};
1
