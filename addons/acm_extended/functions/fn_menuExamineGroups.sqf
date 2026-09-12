/* Examination presentation only: keep common bedside assessments one click away.
 * Dropdowns are reserved for equipment-heavy or long secondary lists. Callback/eligibility
 * remains native ACE/ACM; this file only groups exact treatment classes for presentation. */
[
    ["examine_monitoring_equipment", "Monitoring Equipment", [
        "pressurecuff_attach", "measurebloodpressure", "measurebloodpressurestethoscope",
        "pressurecuff_remove", "placepulseoximeter", "removepulseoximeter"
    ], [0.95, 0.53, 0.74, 1]],
    ["examine_injuries", "Injuries & IV Sites", [
        "diagnose", "inspectforfracture", "inspectiv_upper", "inspectiv_middle", "inspectiv_lower"
    ], [0.58, 0.24, 0.92, 1]],
    ["examine_debug", "Debug", [
        "acme_tuneheadtilt", "acme_debugforceshake"
    ], [0.55, 0.55, 0.55, 1]]
]
