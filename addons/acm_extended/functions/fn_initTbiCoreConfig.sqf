ACME_tbi_baseICP = 10;  // todo[ref] normal ICP (mmhg)
ACME_tbi_icpMax = 40;  // todo[ref] severity-scaled ICP ceiling
// ICP and CPP accrual rates, tuned for prolonged field care. the raised-ICP brain is a silent killer that
// deteriorates over a long arc, not in seconds. ICP and CPP creep slowly, the rosner vasodilatory spiral stays
// gentle but is still a spiral, and overload and CO2 pushes land far more slowly than the old fluid-hits-fast
// defaults. raise any of these to make it bite sooner.
ACME_tbi_icpRisePerSec = 0.02;  // untreated structural ICP creep (was 0.05)
ACME_tbi_vasoRisePerSec = 0.05;  // active vasodilatory-cascade push, the spiral. the inline default was 0.2 and was the biggest killer.
ACME_tbi_co2RisePerSec = 0.2;  // CO2-retention, or hypoventilation, push. the inline default was 0.5.
ACME_tbi_severityPerSecLowCPP = 0.003;  // secondary-insult rate, sustained low CPP (was 0.01)
ACME_tbi_severityPerSecHypoxia = 0.004;  // secondary-insult rate, hypoxia (was 0.01)
