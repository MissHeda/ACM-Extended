// over-resuscitation pulmonary-edema breath sounds, meaning wet crackles, one per respiratory-rate bucket so the
// rate selection of the stethoscope, fast, slow or normal, lines up with the actual respiration of the patient.
// they are selected when the stethoscope_lungstate field of the patient is 3, set by the updateLungState override
// from ACM's Overload_Volume. the format mirrors ACM's own breath sounds: {file, db, pitch}.
class CfgSounds {
    class ACM_Stethoscope_Breath_Normal_Crackles {
        name = "ACM_Stethoscope_Breath_Normal_Crackles";
        sound[] = {"acm_extended\sound\breathing_normal_crackles.wav", "db+16", 1};
        titles[] = {};
    };
    class ACM_Stethoscope_Breath_Fast_Crackles {
        name = "ACM_Stethoscope_Breath_Fast_Crackles";
        sound[] = {"acm_extended\sound\breathing_fast_crackles.wav", "db+16", 1};
        titles[] = {};
    };
    class ACM_Stethoscope_Breath_Slow_Crackles {
        name = "ACM_Stethoscope_Breath_Slow_Crackles";
        sound[] = {"acm_extended\sound\breathing_slow_crackles.wav", "db+16", 1};
        titles[] = {};
    };
    // HPMK deploy, a one-shot: the foil and shell rustle when the blanket is wrapped.
    class ACM_HPMK_Wrap {
        name = "ACM_HPMK_Wrap";
        sound[] = {"acm_extended\sound\HPMK_sfx.wav", "db+4", 1};
        titles[] = {};
    };
    // HPMK remove, a one-shot: the unwrap and pack-away rustle.
    class ACM_HPMK_Remove {
        name = "ACM_HPMK_Remove";
        sound[] = {"acm_extended\sound\HPMK_remove_sfx.wav", "db+4", 1};
        titles[] = {};
    };
    // chest seal apply, a one-shot: peel and stick.
    class ACM_ChestSeal_Apply {
        name = "ACM_ChestSeal_Apply";
        sound[] = {"acm_extended\sound\chest_seal_sfx.wav", "db+4", 1};
        titles[] = {};
    };
    // ACCUVAC power-down, a one-shot: it plays when the suction timer completes.
    class ACM_Suction_Off {
        name = "ACM_Suction_Off";
        sound[] = {"acm_extended\sound\suction_off_sfx.wav", "db+2", 1};
        titles[] = {};
    };
    // the "Expose" sfx, staged for a future system that cuts and exposes the casualty. they are shipped and registered
    // now so they are ready to trigger, and they are not wired to any action yet.
    class ACM_Expose_1 {
        name = "ACM_Expose_1";
        sound[] = {"acm_extended\sound\expose1_sfx.wav", "db+2", 1};
        titles[] = {};
    };
    class ACM_Expose_2 {
        name = "ACM_Expose_2";
        sound[] = {"acm_extended\sound\expose2_sfx.wav", "db+2", 1};
        titles[] = {};
    };
    class ACM_Expose_3 {
        name = "ACM_Expose_3";
        sound[] = {"acm_extended\sound\expose3_sfx.wav", "db+2", 1};
        titles[] = {};
    };
    class ACM_Expose_4 {
        name = "ACM_Expose_4";
        sound[] = {"acm_extended\sound\expose4_sfx.wav", "db+2", 1};
        titles[] = {};
    };
    class ACM_Expose_Chest {
        name = "ACM_Expose_Chest";
        sound[] = {"acm_extended\sound\expose_chest.wav", "db+2", 1};
        titles[] = {};
    };
    // junctional treatment sfx.
    // packing, with combat gauze: a one-shot of about 15.9 s, which is about the 15 s pack timer.
    class ACME_JunctionalPacking {
        name = "ACME_JunctionalPacking";
        sound[] = {"acm_extended\sound\junctionalwound_packing_sfx.wav", "db+3", 1};
        titles[] = {};
    };
    // wrapping, with a pressure bandage: about 7.3 s, looped for the duration of the wrap timer. it is re-played by
    // fn_junctionalwrapsfxstart so it still covers the timer if treatmenttime is retuned.
    class ACME_JunctionalWrapping {
        name = "ACME_JunctionalWrapping";
        sound[] = {"acm_extended\sound\junctionalwound_wrapping_sfx.wav", "db+3", 1};
        titles[] = {};
    };
    // tie-off, about 0.85 s: a one-shot, always played when the wrap timer completes.
    class ACME_JunctionalTie {
        name = "ACME_JunctionalTie";
        sound[] = {"acm_extended\sound\junctionalwound_packing_tie_sfx.wav", "db+3", 1};
        titles[] = {};
    };
    // HPMK wrap, a one-shot: played when "Wrap in HPMK" is pressed.
    class ACME_HPMK_Wrap {
        name = "ACME_HPMK_Wrap";
        sound[] = {"acm_extended\sound\HPMK_wrap.wav", "db+4", 1};
        titles[] = {};
    };
    // HPMK unwrap, a one-shot: played when "Unwrap HPMK" is pressed.
    class ACME_HPMK_Unwrap {
        name = "ACME_HPMK_Unwrap";
        sound[] = {"acm_extended\sound\HPMK_unwrap.wav", "db+4", 1};
        titles[] = {};
    };
    // direct pressure, a one-shot of about 0.85 s: the hands-on-wound press, played the instant "Apply Direct Pressure"
    // is pressed, from the ACME_DirectPressure callbackstart.
    class ACME_DirectPressure {
        name = "ACME_DirectPressure";
        sound[] = {"acm_extended\sound\direct_pressure_sfx.wav", "db+3", 1};
        titles[] = {};
    };
    // junctional leaking, a one-shot of about 2.4 s: an ambient wet arterial leak, replayed by the junctional bleed pfh
    // at random 5 to 10 s intervals while the wound is still bleeding.
    class ACME_JunctionalLeaking {
        name = "ACME_JunctionalLeaking";
        sound[] = {"acm_extended\sound\junctionalwound_leaking_sfx.wav", "db+2", 1};
        titles[] = {};
    };
};
