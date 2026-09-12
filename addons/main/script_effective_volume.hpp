/*
 * ACM Extended B94 effective circulating-volume contract.
 *
 * The IV pipeline already accounts for gauge, clamp position, pressure infusers,
 * access complications and admitted volume before fluid reaches these three
 * compartments. Once admitted, blood, plasma and crystalloid are circulating
 * volume immediately. Do not make hemodynamic recovery wait on ACM's legacy
 * fixed plasma/saline-to-blood conversion rates; those rates are independent of
 * gauge and caused a full 14g bolus to take many extra minutes to become
 * "effective" after the bag had already emptied.
 *
 * Keep the individual compartments for product-specific chemistry, platelets,
 * citrate, saline/chloride load and serialization. Effective volume is their
 * current intravascular sum, capped at the normal circulating volume, with the
 * existing overload penalty retained.
 */
#ifndef ACM_EXTENDED_EFFECTIVE_VOLUME_B94
#define ACM_EXTENDED_EFFECTIVE_VOLUME_B94
#undef GET_EFF_BLOOD_VOLUME
#define GET_EFF_BLOOD_VOLUME(unit) (((DEFAULT_BLOOD_VOLUME min ((unit getVariable [QEGVAR(circulation,Blood_Volume), DEFAULT_BLOOD_VOLUME]) + (unit getVariable [QEGVAR(circulation,Plasma_Volume), 0]) + (unit getVariable [QEGVAR(circulation,Saline_Volume), 0]) - (unit getVariable [QEGVAR(circulation,Overload_Volume), 0]))) max 0))
#endif
