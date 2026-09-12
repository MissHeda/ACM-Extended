// rhythms a synchronized shock converts to sinus: AFib-RVR at 100, atrial tach at 101, controlled AFib at 103
// and SVT at 104. torsades at 102 is polymorphic, so defibrillate it unsynchronized and do not sync.
ACME_sync_cardiovertibleRhythms = [100, 101, 103, 104];
// torsades is shockable by defibrillation, because there is no r wave to sync to. a shock with SYNC off
// converts it to sinus.
ACME_sync_defibrillatableRhythms = [102];
ACME_sync_successChance         = 0.9;  // fallback per-shock conversion probability
// per-rhythm conversion probability. atrial tach, 101, and SVT, 104, cardiovert reliably, so their odds are
// very high. AFib, 100 and 103, may need repeats. defibrillation terminates torsades, 102, reliably.
ACME_sync_successByRhythm = createHashMapFromArray [
    [100, 0.9],  // AFib-RVR
    [101, 0.97],  // atrial tachycardia. very high
    [103, 0.9],  // controlled AFib
    [104, 0.97],  // SVT. very high
    [102, 0.95]  // torsades (defibrillation)
];
// AFib r-r irregularity, in fn_genrhythmekg. it scales off the beat period, so it shows even at a fast RVR.
ACME_rhythm_afibJitterDown  = 0.45;  // shorter-r-r jitter, fraction of beat period
ACME_rhythm_afibJitterUp    = 0.70;  // longer-r-r jitter, fraction of beat period
ACME_rhythm_afibPauseChance = 0.32;  // chance of an extra longer pause between complexes
// SYNC key and led placement on the 2048-wide LifePak panel texture, as [x,y,w,h] in px. the tooltip text is
// runtime-gated by Clinical Descriptors. nudge the positions in game with no rebuild, for example
// ACME_sync_btnPx = [1632,752,142,43].
ACME_sync_btnPx                 = [1548, 704, 134, 53];
ACME_sync_ledPx                 = [1564, 719, 30, 30];  // B21: doubled diameter, centered on the same SYNC indicator slot
ACME_sync_ledTexture            = "\a3\ui_f\data\map\markers\military\dot_ca.paa";  // filled circle (tunable)
ACME_sync_ledPulsePeriod        = 1.0;  // B21: 1 Hz, one full dim-bright-dim cycle per second
// QRS sync flags. these are small green downward arrows above each r wave, matching the ekg green.
ACME_sync_flagCount             = 24;  // max simultaneous arrows (one per visible QRS)
ACME_sync_flagYpx               = 578;  // arrow-row y (px), just above the r peaks (~601 px)
ACME_sync_flagWpx               = 16;  // arrow control width (px)
ACME_sync_flagHpx               = 18;  // arrow control height (px)
ACME_sync_flagArrowSize         = 1.0;  // structured-text size of the arrow glyph
ACME_sync_flagGlyph             = "v";  // arrow glyph; swap (e.g. "v") if your ui font lacks it
ACME_sync_qrsThreshold          = -25;  // ekg height below this = an r wave (r spikes are ~ -44..-50)
ACME_sync_minColSpacing         = 6;  // min columns between arrows (one arrow per broad complex)
