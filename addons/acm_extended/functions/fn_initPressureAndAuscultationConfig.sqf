// over-resuscitation crackle rate split, used by the stethoscope override. heavy edema gives fast crackles and
// milder edema gives normal crackles, so both crackle variants have a real trigger.
ACME_edema_crackleFastVol = 1.0;  // the ACM Overload_Volume at or above which the crackles read Fast. it was bumped from 0.5 to 1.0 to
                                            // track the gentler curve, at the same severity point near 0.5, so "Fast" still means moderate to severe edema
                                            // rather than firing at what is now only mild overload.

// direct pressure over a fractured limb. it is a severe pain stimulus, and it wakes the patient from a light
// ko or obtundation only.
ACME_DP_fracturePainEnabled = true;
ACME_DP_fracturePainAmount = 1.0;
ACME_DP_fracturePainCooldown = 8;
ACME_DP_fractureWakeMinSpO2 = 85;
ACME_DP_fractureWakeMinMAP = 60;
ACME_DP_fractureWakeGrace = 8;

// direct-pressure free-movement pose tuning, for the limb and the head.
ACME_DP_idleToPose = 0.8;  // idle seconds before adopting the holding pose
ACME_DP_lookDot    = 0.4;  // minimum horizontal facing dot toward the patient to hold the pose, about a 66 deg cone.
ACME_DP_treatTimeMult = 1.6;  // while a medic holds limb, head or self direct pressure, every timed action takes this much longer, because one hand is occupied.
