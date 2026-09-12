// display mode is hard off, and the CBA setting that exposed it is removed.
// display mode opened the minigames as child displays of 46 instead of dialogs. that let the player move during
// a minigame, because a display does not lock movement the way a dialog does. it also broke the mouse, and it
// routed the flashlight down the display branch so the dialog-mode filter never ran. a saved "on" value in a
// CBA profile silently overrode this line, which the RPT showed as "thoraInit: displayMode=true". that is why
// every one of those symptoms persisted. with the setting gone nothing can turn it back on. the minigames are
// always dialogs, movement is locked, and the flashlight uses the dialog forward-to-ACE path.
// for the record, a display did work mechanically. the thoracostomy opened as a display, ACE's real interaction
// menu opened over it, and our flashlight action was in it. the problem is what that menu contains. ACE's menu
// is small on the map only because ACE filters it: an action that does not except "notOnMap" is hidden while
// the map is up, which leaves the flashlight and hide gps. off the map nothing filters it, so the whole menu
// arrives, with equipment, team management, gestures, medical and the medical menu draped across the patient.
// that is the opposite of a small popup inside the panel.
ACME_minigame_displayMode = false;
uiNamespace setVariable ["ACME_minigame_openedAsDisplay", false];
// ALERTS 2/2 default thresholds, per patient. these are the initial values the screen shows.
// fn_ventconnectpatient stores them on the player at connect, and these are the fallbacks.
ACME_vent_alertLowTVeDefault = 85;
ACME_vent_alertLeakDefault = 100;
ACME_vent_alertApneaDefault = 30;
// Absolute alarm limits in L/min. Separate from alveolar physiology adequacy.
ACME_vent_alertMVlowLpmDefault = missionNamespace getVariable ["ACME_vent_alertMVlowLpmDefault", 3.0];
ACME_vent_alertMVhighLpmDefault = missionNamespace getVariable ["ACME_vent_alertMVhighLpmDefault", 10.0];
ACME_vent_alertPEEPDefault = 5.0;
ACME_vent_pSupportDefault = 18;

ACME_vent_powerHoldSeconds = 4;  // hold MMB this long to power the ventilator down, like the real device.
ACME_vent_powerHoldArm = 0.45;  // but show nothing below this, because a normal click is on its way to a select.

ACME_vent_valueSplit = 0.56;  // where the ALERTS value column starts, as a fraction of the row. the label
                                    // sits left of it and never lights. the value sits right of it and is the only thing that highlights, because
                                    // it is the only thing you can change.
