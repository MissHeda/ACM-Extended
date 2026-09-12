/*
 * Phase 24 subsystem ownership: Intubation geometry plus procedure darkness, adaptation and cyanosis presentation tunables.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

ACME_laryngo_toolScale = 0.44;  // laryngoscope size as a fraction of the head. it was 0.22, a toy next to a face.
ACME_laryngo_traySlot = 0.26;  // tray slot height, as a fraction of the head view. it is square in pixels now.
ACME_laryngo_frameGamma = 0.42;  // how fast an incoming head frame comes up. below 1 is fast, so a transition is
                                    // a clear blend of two real frames, instead of a long dim smear.
// B49 intubation geometry. The supplied 10 mL barrel's distal Luer tip is at ~[0.50,0.370] on its 1024 canvas.
// The pilot-valve target is measured on the currently drawn ETT frame, so syringe magnetism follows the tube.
ACME_laryngo_cuffRunTime = 1.0;
ACME_laryngo_cuffPilotUV = [0.548, 0.455];
ACME_laryngo_syrTipUV = [0.50, 0.370];
ACME_laryngo_cuffStartMl = 8.0;       // B52: air syringe begins pulled back to 8 mL.
ACME_laryngo_cuffMagnet = 0.17;        // B52: stronger pilot-valve magnet.
ACME_laryngo_cuffBoxUV = [0.15, 0.19]; // B52: forgiving acceptance box around the actual pilot valve.
ACME_laryngo_tubeVisualLiftV = 0.010;  // B52: hide advancing frame cutoff behind the tongue.
ACME_ETT_MinSeatFrame = 5;  // seat at least one frame deeper than the old frame-4 threshold for most airways.
ACME_darkness_boost = 1.25;  // multiplies ACE's alpha before the clamp. ACE tops out near 0.86 at a moonlit
                                    // ambient, because the map only needs to be hard to read. a minigame needs to be black, because 10 percent of
                                    // a white body image is still a readable silhouette.
ACME_darkness_maxAlpha = 1.0;  // fully black with no light. it was 0.97, which still let 3 percent of the panel show,
                                    // and 3 percent of a bright white body image is plenty to work by. it should be black.
ACME_darkness_cabinRelief = 0.97;  // a buttoned-up cabin gets a hint of instrument glow. it is not a reading light.
                                    // was 0.88, which combined with maxalpha to leave the cabin far too usable.
                                    // dark adaptation. a light should not be free.
ACME_darkness_adaptRelief = 0.11;  // how much fully dark-adapted eyes lift the shade. it is not enough to work by.
                                    // enough to make out a limb. it is the only thing that is ever less than black at night, and the torch is what
                                    // takes it away.
                                    // how much each color of light costs your night vision. it reads against the torch's own
                                    // ace_flashlight_colour, so it works for any flashlight ACE knows about, modded ones included.
                                    // red barely registers, because rod sensitivity falls off a cliff above about 620 nm. that is why red lens caps
                                    // exist at all.
                                    // green is the worst, and this is the part people get wrong. rods peak at about 498 nm, blue-green, so a green
                                    // lens sits almost exactly on their most sensitive wavelength and bleaches them as hard as white does. plenty
                                    // of people carry green in the belief that it is kind to their eyes. it is not, and the sim now tells them
                                    // so.
ACME_darkness_bleachByColor = [
    ["red",    0.08],
    ["orange", 0.35],
    ["yellow", 0.65],
    ["blue",   0.95],
    ["green",  1.00],
    ["white",  1.00]
];

ACME_darkness_constrictTau = 1.6;  // seconds for your pupils to shut when the light comes on. this is fast.
ACME_darkness_dilateTau = 16;  // seconds for your rods to recover when it goes off. this is slow, and that asymmetry
                                    // is the entire point. a torch switched off does not give you your night vision back. it makes you blinder
                                    // than you were before you switched it on.

ACME_cyanosis_spo2Floor = 90;  // above this saturation ACM's cyanosis row is suppressed. cyanosis needs roughly
                                    // 5 g/dl of deoxygenated hemoglobin to be visible, which is the mid eighties in someone with a normal
                                    // hemoglobin and lower in a casualty who has bled, which is why an exsanguinating patient can be
                                    // profoundly hypoxic and never look blue. set it to 100 to get ACM's original rows back.
ACME_darkness_beamScale = 1.55;  // beam width. it divides by each torch's own ACE_Flashlight_Size, exactly as ACE
                                    // does it, so a maglite throws a wider pool than a weapon light.
ACME_laryngo_lightBrightness = 0.14;
