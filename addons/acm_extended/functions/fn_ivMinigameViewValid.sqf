/* A delayed insertion belongs to one display visit, including after a round trip.
   Session validation alone cannot distinguish front/back flips in the same display. */
params ["_display", "_session", "_generation", "_bodyPart", "_view"];
!isNull _display
    && {_display isEqualTo (uiNamespace getVariable ["ACME_IV_DLG", displayNull])}
    && {[_session] call ACME_fnc_ivUiValid}
    && {_generation == (_display getVariable ["ACME_IV_ViewGeneration", 0])}
    && {_bodyPart isEqualTo (uiNamespace getVariable ["ACME_IV_BodyPart", ""])}
    && {_view isEqualTo (uiNamespace getVariable ["ACME_IV_View", ""])}
