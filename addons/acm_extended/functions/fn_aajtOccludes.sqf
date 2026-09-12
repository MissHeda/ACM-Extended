/* Proximal inguinal occlusion; never manufactures/removes a real ACE tourniquet. */
params ["_patient", "_partIndex"];
(_partIndex in [4, 5]) && {_patient getVariable ["ACME_AAJT_inguinal", false]}
