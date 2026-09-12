# ACM and ACE reference

Generated from the ACM and ACE sources by tools/build_reference.py. Nothing here is written by
hand. Regenerate it whenever either source is updated.

It lives in the addon tree on purpose, so it arrives with every upload of the mod and the exact
names, signatures and constants are available without the full sources present.

***

## Component tags

A CfgFunctions override must be filed under the tag of the component the function lives in. Filed
under the wrong tag it compiles under the wrong name and the original keeps running, silently.

| Component | Tag | Functions |
|---|---|---|
| ACM airway | `ACM_airway` | 30 |
| ACM breathing | `ACM_breathing` | 39 |
| ACM cbrn | `ACM_cbrn` | 40 |
| ACM circulation | `ACM_circulation` | 121 |
| ACM core | `ACM_core` | 93 |
| ACM damage | `ACM_damage` | 26 |
| ACM disability | `ACM_disability` | 23 |
| ACM evacuation | `ACM_evacuation` | 11 |
| ACM gui | `ACM_GUI` | 10 |
| ACM mission | `ACM_mission` | 11 |
| ACM zeus | `ACM_zeus` | 10 |

## Macros and constants

### ACE

| Macro | Definition | Header |
|---|---|---|
| `GET_BLOOD_VOLUME` | `(unit)      (unit getVariable [VAR_BLOOD_VOL, DEFAULT_BLOOD_VOLUME])` | addons/medical_engine/script_macros_medical.hpp |
| `DEFAULT_BLOOD_VOLUME` | `6.0 // in liters` | addons/medical_engine/script_macros_medical.hpp |
| `GET_HEART_RATE` | `(unit)        (unit getVariable [VAR_HEART_RATE, DEFAULT_HEART_RATE])` | addons/medical_engine/script_macros_medical.hpp |
| `GET_FRACTURES` | `(unit)         (unit getVariable [VAR_FRACTURES, DEFAULT_FRACTURE_VALUES])` | addons/medical_engine/script_macros_medical.hpp |
| `DEFAULT_FRACTURE_VALUES` | `[0,0,0,0,0,0]` | addons/medical_engine/script_macros_medical.hpp |
| `VAR_BLOOD_VOL` | `QEGVAR(medical,bloodVolume)` | addons/medical_engine/script_macros_medical.hpp |
| `VAR_HEART_RATE` | `QEGVAR(medical,heartRate)` | addons/medical_engine/script_macros_medical.hpp |
| `VAR_FRACTURES` | `QEGVAR(medical,fractures)` | addons/medical_engine/script_macros_medical.hpp |
| `VAR_PERIPH_RES` | `QEGVAR(medical,peripheralResistance)` | addons/medical_engine/script_macros_medical.hpp |
| `DEFAULT_PERIPH_RES` | `100` | addons/medical_engine/script_macros_medical.hpp |
| `GET_PAIN` | `(unit)              (unit getVariable [VAR_PAIN, 0])` | addons/medical_engine/script_macros_medical.hpp |
| `IS_UNCONSCIOUS` | `(unit)        (unit getVariable [VAR_UNCON, false])` | addons/medical_engine/script_macros_medical.hpp |
| `DEFAULT_HEART_RATE` | `80` | addons/medical_engine/script_macros_medical.hpp |

### ACM

| Macro | Definition | Header |
|---|---|---|
| `GET_OXYGEN` | `(unit) (unit getVariable [VAR_SPO2, 99])` | addons/main/script_macros.hpp |
| `VAR_SPO2` | `QACEGVAR(medical,spo2)` | addons/main/script_macros.hpp |
| `GET_IV` | `(unit) (unit getVariable [QEGVAR(circulation,IV_Placement),ACM_IV_PLACEMENT_DEFAULT_0])` | addons/main/script_macros.hpp |
| `GET_IO` | `(unit) (unit getVariable [QEGVAR(circulation,IO_Placement),ACM_IO_PLACEMENT_DEFAULT_0])` | addons/main/script_macros.hpp |
| `ALL_BODY_PARTS` | `["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]` | include/z/ace/addons/medical_engine/script_macros_medical.hpp |
| `GET_BODYPART_INDEX` | `(bodypart) (ALL_BODY_PARTS find toLowerANSI bodypart)` | addons/main/script_macros.hpp |
| `IN_CRDC_ARRST` | `(unit)         (unit getVariable [VAR_CRDC_ARRST, false])` | include/z/ace/addons/medical_engine/script_macros_medical.hpp |
| `LYING_ANIMATION` | `["ainjppnemstpsnonwrfldnon", "acm_lyingstate"]` | addons/main/script_macros.hpp |

## Signatures of everything this addon calls

Read out of the source. A wrong argument order here fails silently rather than erroring.

| Function | params |
|---|---|
| `ACM_GUI_fnc_inZone` | `["_zone", "_reference"]` |
| `ACM_airway_fnc_getAirwayState` | `["_patient"]` |
| `ACM_airway_fnc_getSuctionTime` | `["_patient", ["_type", 0]]` |
| `ACM_airway_fnc_handleAirwayObstruction_Vomit` | `["_patient"]` |
| `ACM_airway_fnc_handleSuctionLocal` | `["_patient"]` |
| `ACM_airway_fnc_insertAirwayItem` | `["_medic", "_patient", "_type"]` |
| `ACM_breathing_fnc_Thoracostomy_close` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_Thoracostomy_drain` | `["_medic", "_patient", ["_type", 1]]` |
| `ACM_breathing_fnc_Thoracostomy_insertChestTube` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_Thoracostomy_resealChestTube` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_Thoracostomy_start` | `["_medic", "_patient", "_usedKit"]` |
| `ACM_breathing_fnc_applyChestSeal` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_canUseBVM` | `["_medic", "_patient", ["_inProgress", false]]` |
| `ACM_breathing_fnc_checkBreathingLocal` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_getBreathingState` | `["_patient"]` |
| `ACM_breathing_fnc_getEtCO2` | `["_patient"]` |
| `ACM_breathing_fnc_handleHemothorax` | `["_patient"]` |
| `ACM_breathing_fnc_handlePneumothorax` | `["_patient"]` |
| `ACM_breathing_fnc_inspectChest` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_performNCD` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_performNCDLocal` | `["_medic", "_patient"]` |
| `ACM_breathing_fnc_updateLungState` | `["_patient", ["_healed", false]]` |
| `ACM_breathing_fnc_updateRespirationRate` | `["_unit", "_oxygenSaturation", ["_oxygenDemand", 0], ["_respirationRateAdjustment", 0], ["_coSensitivityAdjustment", 0], "_deltaT", "_syncValue"]` |
| `ACM_breathing_fnc_useOxygenTankReserve` | `["_unit"]` |
| `ACM_breathing_fnc_useStethoscope` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_AED_AdministerShock` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_AED_BeginCharge` | `["_medic", "_patient", ["_manual", false]]` |
| `ACM_circulation_fnc_AED_CanAdministerShock` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_AED_CanMeasureBP` | `["_medic", "_patient", "_bodyPart"]` |
| `ACM_circulation_fnc_AED_MeasureBP` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_AED_MotionDetected` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_AED_TrackCPR` | `["_patient"]` |
| `ACM_circulation_fnc_Syringe_Draw` | `["_medic", "_patient", "_bodyPart", ["_size", 10]]` |
| `ACM_circulation_fnc_Syringe_Draw_Button` | `[["_type", 0]]` |
| `ACM_circulation_fnc_Syringe_Draw_Move` | `(none)` |
| `ACM_circulation_fnc_Syringe_Inject` | `["_medic", "_patient", "_bodyPart", "_classname", ["_size", 10], ["_iv", true], ["_returnSyringe", true]]` |
| `ACM_circulation_fnc_Syringe_PrepareFinish` | `["_medic", "_medication", "_dose", ["_size", 10]]` |
| `ACM_circulation_fnc_Syringe_UpdateMedicationList` | `(none)` |
| `ACM_circulation_fnc_TransfusionMenu_AddBag` | `["_medic", "_patient", "_target", "_itemClassname", "_actionClassname"]` |
| `ACM_circulation_fnc_TransfusionMenu_MoveBag` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_TransfusionMenu_RemoveBag` | `["_IVBags", "_IVBagsOnBodyPart", "_targetIndex", "_itemClassName", "_type", "_returnVolume", "_totalVolume"]` |
| `ACM_circulation_fnc_TransfusionMenu_UpdateBagList` | `[["_update", false]]` |
| `ACM_circulation_fnc_TransfusionMenu_UpdateSelection` | `(none)` |
| `ACM_circulation_fnc_beginCPR` | `["_medic", "_patient"]` |
| `ACM_circulation_fnc_canInsertIV` | `["_patient", ["_bodyPart", ""], ["_type", 0], ["_accessSite", -1]]` |
| `ACM_circulation_fnc_convertBloodType` | `["_bloodType", ["_returnType", 0]]` |
| `ACM_circulation_fnc_displayAEDMonitor_generateEKG` | `["_rhythm", "_spacing", "_arrayOffset"]` |
| `ACM_circulation_fnc_formatFluidBagName` | `["_type", "_targetVolume", ["_bloodType", -1], ["_noPrefix", false]]` |
| `ACM_circulation_fnc_getCardiacMedicationEffects` | `["_patient"]` |
| `ACM_circulation_fnc_getEKGHeartRate` | `["_patient"]` |
| `ACM_circulation_fnc_hasAED` | `["_patient", ["_bodyPart", ""], ["_type", 0]]` |
| `ACM_circulation_fnc_hasIO` | `["_patient", ["_bodyPart", ""], ["_type", 0]]` |
| `ACM_circulation_fnc_hasIV` | `["_patient", ["_bodyPart", ""], ["_type", 0], ["_accessSite", -1]]` |
| `ACM_circulation_fnc_measureBP` | `["_medic", "_patient", "_bodyPart", ["_stethoscope", false]]` |
| `ACM_circulation_fnc_openTransfusionMenu` | `["_medic", "_patient", "_bodyPart"]` |
| `ACM_circulation_fnc_recentAEDShock` | `["_patient", ["_monitor", false]]` |
| `ACM_circulation_fnc_setIV` | `["_medic", "_patient", "_bodyPart", "_type", "_state", ["_iv", true], ["_accessSite", -1]]` |
| `ACM_circulation_fnc_updateCirculationState` | `["_patient"]` |
| `ACM_core_fnc_beginContinuousAction` | `["_args", "_onStart", "_onCancel", "_perFrame", ["_allowProne", false], ["_dialogID", -1]]` |
| `ACM_core_fnc_bvmActive` | `["_patient"]` |
| `ACM_core_fnc_cprActive` | `["_patient"]` |
| `ACM_core_fnc_getBloodPressure` | `["_unit"]` |
| `ACM_core_fnc_getUp` | `["_patient"]` |
| `ACM_core_fnc_handleCriticalVitals` | `["_patient"]` |
| `ACM_core_fnc_isForcedUnconscious` | `["_patient"]` |
| `ACM_core_fnc_progressBarAction` | `["_args", "_onComplete", "_onCancel", "_text", "_time", ["_condition", false]]` |
| `ACM_damage_fnc_clotWoundsOnBodyPart` | `["_patient", "_bodyPart", ["_woundsToClot", 1], ["_maxWoundSeverity", 1], ["_unstable", true], ["_continued", false]]` |
| `ACM_damage_fnc_getBandageTime` | `["_medic", "_patient", "_bodyPart", "_bandage"]` |
| `ACM_damage_fnc_getBodyPartInternalBleeding` | `["_patient", "_partIndex"]` |
| `ACM_evacuation_fnc_canConvert` | `["_medic", "_patient"]` |
| `ACM_mission_fnc_generatePatient` | `["_object", "_location", "_initiator", "_severity", "_type", ["_singlePatient", true]]` |
| `ace_common_fnc_addCanInteractWithCondition` | `["_conditionName", "_conditionFunc"]` |
| `ace_common_fnc_addToInventory` | `["_unit", "_classname", ["_container", ""], ["_ammoCount", -1]]` |
| `ace_common_fnc_ambientBrightness` | `(none)` |
| `ace_common_fnc_canInteractWith` | `["_unit", "_target", ["_exceptions", []]]` |
| `ace_common_fnc_displayTextStructured` | `[["_text", ""], ["_size", 1.5, [0]], ["_target", ACE_player, [objNull]], ["_width", 10, [0]]]` |
| `ace_common_fnc_doAnimation` | `["_unit", "_animation", ["_priority", 0]]` |
| `ace_common_fnc_getCountOfItem` | `["_unit", "_itemType"]` |
| `ace_common_fnc_getName` | `["_unit", ["_showEffective", false], ["_useRaw", false]]` |
| `ace_common_fnc_isAwake` | `["_unit"]` |
| `ace_common_fnc_isBeingCarried` | `["_target"]` |
| `ace_common_fnc_isBeingDragged` | `["_target"]` |
| `ace_common_fnc_isPlayer` | `["_unit", ["_excludeRemoteControlled", false]]` |
| `ace_common_fnc_lightIntensityFromObject` | `["_unit", "_lightSource"]` |
| `ace_common_fnc_progressBar` | `["_totalTime", "_args", "_onFinish", "_onFail", ["_localizedTitle", ""], ["_condition", {true}], ["_exceptions", []], ["_dialog", true]]` |
| `ace_common_fnc_uniqueItems` | `["_target", ["_includeMagazines", 0]]` |
| `ace_fastroping_fnc_deployRopes` | `["_vehicle", ["_player", objNull], ["_ropeClass", ""]]` |
| `ace_hearing_fnc_earRinging` | `["_strength"]` |
| `ace_hearing_fnc_updateHearingProtection` | `["_slot"]` |
| `ace_interact_menu_fnc_addActionToClass` | `(none)` |
| `ace_interact_menu_fnc_createAction` | `[ "_actionName", "_displayName", "_icon", "_statement", "_condition", ["_insertChildren", {}], ["_customParams", []], ["_position", {[0, 0, 0]}], ["_d` |
| `ace_interact_menu_fnc_keyDown` | `["_menuType"]` |
| `ace_interact_menu_fnc_keyUp` | `["_menuType", "_calledByClicking"]` |
| `ace_interaction_fnc_hideMouseHint` | `(none)` |
| `ace_interaction_fnc_showMouseHint` | `["_textLMB", "_textRMB", ["_textMMB", ""], ["_extraIconSets", []]]` |
| `ace_map_fnc_compileFlashlightMenu` | `["", "_player"]` |
| `ace_map_fnc_determineMapLight` | `["_unit"]` |
| `ace_map_fnc_getUnitFlashlights` | `["_unit"]` |
| `ace_map_fnc_switchFlashlight` | `["_unit", "_newFlashlight"]` |
| `ace_medical_damage_fnc_getTypeOfDamage` | `["_typeOfProjectile"]` |
| `ace_medical_engine_fnc_setUnconsciousAnim` | `[["_unit", objNull, [objNull]], ["_isUnconscious", true, [false]]]` |
| `ace_medical_fnc_addDamageToUnit` | `[ ["_unit", objNull, [objNull]], ["_damageToAdd", -1, [0]], ["_bodyPart", "", [""]], ["_typeOfDamage", "", [""]], ["_instigator", objNull, [objNull]],` |
| `ace_medical_fnc_adjustPainLevel` | `["_unit", "_addedPain"]` |
| `ace_medical_fnc_setUnconscious` | `[["_unit", objNull, [objNull]], ["_knockOut", true, [false]], ["_minWaitingTime", 0, [0]], ["_forcedWakup", false, [false]]]` |
| `ace_medical_gui_fnc_countTreatmentItems` | `["_items"]` |
| `ace_medical_gui_fnc_formatItemCounts` | `["_medicCount", "_patientCount", "_vehicleCount"]` |
| `ace_medical_gui_fnc_menuPFH` | `(none)` |
| `ace_medical_gui_fnc_openMenu` | `["_target"]` |
| `ace_medical_gui_fnc_updateActions` | `["_display"]` |
| `ace_medical_gui_fnc_updateTriageCard` | `["_ctrl", "_target"]` |
| `ace_medical_status_fnc_getBloodLoss` | `["_unit"]` |
| `ace_medical_status_fnc_getBloodPressure` | `["_unit"]` |
| `ace_medical_status_fnc_getCardiacOutput` | `["_unit"]` |
| `ace_medical_status_fnc_getMedicationCount` | `["_target", "_medication", ["_getCount", true]]` |
| `ace_medical_status_fnc_hasStableVitals` | `["_unit"]` |
| `ace_medical_status_fnc_isInStableCondition` | `["_unit"]` |
| `ace_medical_status_fnc_setCardiacArrestState` | `["_unit", "_active"]` |
| `ace_medical_status_fnc_setUnconsciousState` | `["_unit", "_active"]` |
| `ace_medical_status_fnc_updateWoundBloodLoss` | `["_unit"]` |
| `ace_medical_treatment_fnc_addToLog` | `["_unit", "_logType", "_message", "_arguments"]` |
| `ace_medical_treatment_fnc_addToTriageCard` | `["_unit", "_item"]` |
| `ace_medical_treatment_fnc_bandage` | `["_medic", "_patient", "_bodyPart", "_classname", "", "", "", "_bandageEffectiveness"]` |
| `ace_medical_treatment_fnc_canCPR` | `["", "_patient"]` |
| `ace_medical_treatment_fnc_canTreat` | `["_medic", "_patient", "_bodyPart", "_classname"]` |
| `ace_medical_treatment_fnc_hasItem` | `["_medic", "_patient", "_items"]` |
| `ace_medical_treatment_fnc_hasTourniquetAppliedTo` | `["_unit", "_bodyPart"]` |
| `ace_medical_treatment_fnc_isMedic` | `["_unit", ["_medicN", 1]]` |
| `ace_medical_treatment_fnc_ivBag` | `["_medic", "_patient", "_bodyPart", "_classname", "_itemUser", "_usedItem"]` |
| `ace_medical_treatment_fnc_medicationLocal` | `["_patient", "_bodyPart", "_classname"]` |
| `ace_medical_vitals_fnc_updateHeartRate` | `["_unit", "_hrTargetAdjustment", "_deltaT", "_syncValue"]` |
| `ace_weaponselect_fnc_putWeaponAway` | `["_unit"]` |

### Called but not found in either source

These resolve at runtime, are defined by this addon, or do not exist. Anything here that is
meant to be an ACM or ACE function is a name to check.

- `ACM_circulation_fnc_Syringe_UpdatePlunger`
- `ace_medical_status_fnc_getBloodVolumeChange`
- `ace_weather_fnc_calculateTemperature`

## Counts

- ACM functions indexed: 414
- ACE functions indexed: 2264
- Called by this addon and resolved: 131
- Called by this addon and unresolved: 3


## House rule: American English, always

Every string, comment, patch note and wiki line uses American spelling. edema, hemorrhage,
apneic, eupneic, bradypneic, tachypneic, esophagus, anesthetic, color, gray, center, liter,
meter, caliber, maneuver, behavior, aging, catalog, -ize not -ise, -yze not -yse.

Swept whole-tree at v0.9.999r-10. Keep it clean rather than re-sweeping.

Two traps when sweeping:

1. FOUR IDENTIFIERS MUST KEEP THEIR BRITISH SPELLING. Two break the game if renamed.
   ACE_Flashlight_Colour      ACE owns it. fn_lightExtras reads this exact config entry.
   ace_flashlight_colour      same entry, named in a comment.
   ACME_laryngo_oesophRadius  published setting key, a rename orphans saved values.
   ACME_altitude_minMetres    published setting key, same.

2. FOUR FILES CARRY A RAW 0xb0 DEGREE BYTE AND ARE NOT VALID UTF-8: config.cpp,
   fn_ivSiteRelabel.sqf, fn_medDescriptor.sqf, fn_headElevateStart.sqf. Any script that
   opens the tree with utf-8 and a bare try/except will SKIP them silently. Read and write
   through latin-1, which is a lossless byte round trip, and compare the non-ASCII byte
   list before and after.

Words that look British but are already correct American and must not be touched:
paralysis, analysis, organism, parameter, diameter, dialog (ArmA spells it dialog).
Only the verb forms paralyse, paralysed, paralysing, analyse, analysed, analysing are wrong.

***

## Traps found the hard way, v0.9.999r-11 to r-19

Every one of these compiles, runs, and produces a wrong result in silence. None of them error. This
is the list to read before touching ACM or ACE integration again.

### 1. LINKFUNC captures the function VALUE, not the name

ACE registers CBA event handlers with `LINKFUNC(x)`, which expands to plain `FUNC(x)` in a release
build (`ace main/script_debug.hpp:12`). The handler therefore holds a copy of the function AS IT WAS
when ACE's `XEH_postInit` ran.

Consequence: **wrapping a global ACE function does NOT affect anything that reaches it through a CBA
event.** A wrapper on `ace_common_fnc_displayTextStructured` catches direct calls and misses every
`CBA_fnc_targetEvent` route.

Who uses which:

| Caller | Route | Reached by a wrapper |
|---|---|---|
| ACM `fnc_checkAirway.sqf:292` | direct call | yes |
| ACE `fnc_checkResponse.sqf:35` | direct call | yes |
| ACM `fnc_checkBreathingLocal.sqf:76` | `CBA_fnc_targetEvent` | NO |
| our `fn_inspectChestLocal` | `CBA_fnc_targetEvent` | NO |

The fix for an event route is to resolve the text BEFORE sending, inside a function you own. Do not
convert the targetEvent to a direct call: these run on machines where the medic may be remote, and a
direct call silently drops the hint in multiplayer.

### 2. GET_AIRWAYSTATE is a function call, not a variable read

`ACM main/script_macros.hpp:229` defines it as `([unit] call EFUNC(airway,getAirwayState))`. Reading
a variable of a similar name returns a default and quietly bypasses this addon's own
`overrides/fn_getAirwayState.sqf`. Always expand a macro before trusting what it looks like.

### 3. Airway inflammation and lung damage live in CBRN, not airway

    script_macros.hpp:461   GET_AIRWAY_INFLAMMATION   QEGVAR(CBRN,AirwayInflammation)
    script_macros.hpp:467   GET_LUNG_TISSUEDAMAGE     QEGVAR(CBRN,LungTissueDamage)
    script_macros.hpp:465   threshold mild 15
    script_macros.hpp:469   threshold mild 20

ACM's own cbrn component WRITES these with `QGVAR`, giving the lowercase `ACM_cbrn_` form, while the
macros READ the uppercase `ACM_CBRN_` form. That works only because ArmA namespace variable names
are case-insensitive. Do not "fix" one to match the other.

### 4. The duplicate override registrations are DELIBERATE

`config.cpp` declares `canCarry`, `checkPulseLocal`, `getBloodVolumeChange` and `updateActions`
twice, once in an `ACME_overwrite_*` class and once in a class named exactly like ACM's own wrapper.
That is a collision merge, explained in the comment at `config.cpp:1396`, and it is load-bearing.

When two wrapper classes define the same function name, ACM's entry wins the registry. Declaring a
class with ACM's name merges our file path into the winning entry. This was proven in game:
`getBloodVolumeChange` never ran, so the Y saline clamp, the cold and warmed blood flow and the
empty-marker drain hold were all dead.

**Removing either set puts override resolution back to chance.** It looks like a defect and is not.
It was filed as one twice during r-11 and r-12 before the comment was read.

### 5. Match stringtable text with localize, never an English literal

`fn_ivSiteRelabel` matched `"(Upper)"` as a literal for months. ACM builds those rows from
`STR_ACM_Circulation_IV_Upper`, so on any localized client the literal never matches and the entire
relabel silently does nothing. If a string comes from a stringtable, resolve the key.

Corollary: a key that does NOT exist localizes to its own key text rather than erroring. The test
for "does this key exist" is `localize _k != _k`.

### 6. A bare try/except on a UTF-8 read will skip four files

`config.cpp`, `fn_ivSiteRelabel.sqf`, `fn_medDescriptor.sqf` and `fn_headElevateStart.sqf` each carry
a raw `0xb0` degree byte and are not valid UTF-8. Any tooling that opens the tree with utf-8 and
swallows the exception will silently miss them. Read and write through latin-1, which is a lossless
byte round trip, and compare the non-ASCII byte list before and after.

### 7. Python heredoc backslashes

`config.cpp` file paths use SINGLE backslashes. Writing them from a python heredoc with escaped
backslashes produces a double, which ArmA reports as file-not-found at RUNTIME, not at build. Use raw
strings and assert the match count before writing.

### 8. Row position in the injury list is not stable

ACM pushes the selected body part name at `fnc_updateInjuryList.sqf:186`, after the general-tab rows
and after a blank spacer inserted at line 174. Its index moves depending on how injured the casualty
is. Match injury list rows by CONTENT, never by index.

### 9. Where each injury list event fires, and with what

| Event | Line | Carries |
|---|---|---|
| `updateInjuryListGeneral` | 172 | whole-patient rows: bleeding status, blood loss tiers |
| `updateInjuryListPart` | 564 | `_entries` and `_selectionN`, after IV rows are pushed at 353 |
| `updateInjuryListWounds` | 601 | `_woundEntries`, after all five wound categories are built |

All three pass their array BY REFERENCE and fire before the list is filled, so rows can be rewritten
rather than repainted. Rewriting after the fact with a per-frame handler is the wrong approach and
was removed in r-11.

### 10. healingLogic fires the treatment event BEFORE it logs

`core/overrides/fnc_healingLogic.sqf:62` fires the event, `:65` onward writes the log, same frame. A
handler on the treatment event therefore has its data recorded before the log is written. This is
what makes the auto-heal path reachable without overriding a 593-line function.

`ACM_circulation_setIVLocal` params, verified at `fnc_setIVLocal.sqf:23`:

    ["_medic", "_patient", "_bodyPart", "_type", "_iv", "_accessSite"]

healingLogic reads it as `params ["", "", "", "", "_iv", "_accessSite"]`, discarding a body part it
already has.

### 11. IDCs are unique per display, not globally

`87801` and `87802` each appear twice, in the ventilator panel and the laryngoscope view. That is
correct. A global uniqueness sweep will report false positives.

Also: giving an idc to a BASE control class hands the same idc to every child that does not override
it. `IV_Title` is inherited by `IV_Instruction` and `IV_SlotHdr`. Make a sibling class instead.

### 12. Verify a self-check before trusting it

Three checks written during this work reported failures that were the checker's fault, not the
code's:

- an arity check that counted commas without tracking quote state flagged nine call sites, all of
  which contained a comma inside a string literal
- a spelling check without the `(?=e|a)` lookahead flagged "optimistic" and would flag "organism"
- an equivalence checker with an incomplete word list flagged three files whose only change was
  "neighbour" to "neighbor"

When a check fails, confirm the check before changing the code.
