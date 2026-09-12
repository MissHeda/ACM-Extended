// TBI and CPP subsystem, a decoupled physiology loop.
// CPP is MAP minus ICP. the severity worsens on sustained low CPP, from hypotension or high ICP, and on
// hypoxia. ICP drives the cushing reflex and a timed herniation cascade. osmotherapy lowers ICP, capped by
// sodium. pressors raise MAP, but only when the volume is adequate, which is the blood-before-pressor gate.
// the user-tunable values live in the CBA addon options and register in XEH_preInit.sqf. they are the CPP
// target, the ICP thresholds, the stage clock, the hypoxia threshold, the volume floor, the pressor cap and
// applyvitals. do not assign them here, because postinit runs after preinit and would stomp the user's choice.
// the values below are tuned and each carries a rationale in its comment. none is validated against a cited
// clinical reference yet. sites that still need a reference check carry todo[ref].
ACME_tbi_activePatients = [];
ACME_autoBP_patients = [];
