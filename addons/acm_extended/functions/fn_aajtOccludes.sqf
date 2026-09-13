/*
 * Returns whether an AAJT-S placement proximally occludes this ACE body-part index.
 * 2/3 are arms, 4/5 are legs. Inguinal placement is unilateral; Zone 3 REBOA is bilateral.
 */
params ["_patient", "_partIndex"];
if (isNull _patient) exitWith {false};
switch (_partIndex) do {
    case 2: {_patient getVariable ["ACME_AAJT_axillaleft", false]};
    case 3: {_patient getVariable ["ACME_AAJT_axillaright", false]};
    case 4: {
        (_patient getVariable ["ACME_AAJT_zone3", false])
            || {(_patient getVariable ["ACME_AAJT_inguinal", false]) && {(_patient getVariable ["ACME_AAJT_inguinalSide", ""]) == "leftleg"}}
    };
    case 5: {
        (_patient getVariable ["ACME_AAJT_zone3", false])
            || {(_patient getVariable ["ACME_AAJT_inguinal", false]) && {(_patient getVariable ["ACME_AAJT_inguinalSide", ""]) == "rightleg"}}
    };
    default {false};
}
