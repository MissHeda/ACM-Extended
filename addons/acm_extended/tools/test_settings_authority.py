from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8-sig", errors="strict")


def setting_scope(text: str, name: str) -> int:
    # ACME settings are literal CBA arrays. Capture through category/default into the isGlobal slot.
    pattern = re.compile(
        r'\[\s*"' + re.escape(name) +
        r'"\s*,\s*"(?:CHECKBOX|SLIDER|LIST|EDITBOX|COLOR)"'
        r'[\s\S]*?\]\s*,\s*([012])\s*,\s*(?:\{|\w)',
        re.MULTILINE,
    )
    m = pattern.search(text)
    assert m, f"missing setting or scope: {name}"
    return int(m.group(1))


def test_true_client_preferences_are_local_only_and_non_overridable():
    pre = read("XEH_preInit.sqf")
    extra = read("XEH_settings.hpp")

    pre_client = [
        "ACME_hc_descriptors",
        "ACME_iv_uiScaleV3",
        "ACME_iv_trayIconBias",
        "ACME_iv_bruiseMaxAlpha",
        "ACME_iv_bruiseBoost14",
        "ACME_iv_palpModel",
        "ACME_iv_phenotypeForce",
        "ACME_iv_dotSize",
        "ACME_iv_prepDabAlpha",
        "ACME_iv_prepDabSize",
        "ACME_iv_prepHoldSec",
        "ACME_iv_prepFadeSec",
        "ACME_infusion_clampScrollStep",
        "ACME_infusion_clampScrollInvert",
        "ACME_infusion_clampSfxEnabled",
        "ACME_debug_enabled",
        "ACME_debug_showInfusions",
        "ACME_debug_showTBI",
        "ACME_debug_showAutoBP",
        "ACME_debug_showCirc",
        "ACME_debug_scale",
        "ACME_debug_showNetwork",
        "ACME_hang_useRope",
        "ACME_seizure_animEnabled",
    ]
    extra_client = [
        "ACME_tbi_debugHud",
        "ACME_a11y_colorblindMode",
        "ACME_a11y_bvmVentCircle",
        "ACME_a11y_bvmVentInflateSec",
        "ACME_a11y_menuLeftAlign",
        "ACME_menuNestEnabled",
        "ACME_menuColorHeaders",
        "ACME_a11y_colorblindStrength",
        "ACME_bloodTypeLock",
        "ACME_motion_interpolate",
        "ACME_motion_interpolationTime",
        "ACME_minigameNV_focusBlur",
    ]

    for name in pre_client:
        assert setting_scope(pre, name) == 2, name
    for name in extra_client:
        assert setting_scope(extra, name) == 2, name


def test_shared_gameplay_settings_are_global_only():
    pre = read("XEH_preInit.sqf")
    for name in [
        "ACME_obtunded_autoEnable",
        "ACME_iv_prepMarksToClean",
        "ACME_iv_fossaSpread",
        "ACME_hc_medications",
        "ACME_sys_tbi",
        "ACME_sys_junc",
        "ACME_allowThoracostomy",
        "ACME_skillMedicationPreparation",
    ]:
        assert setting_scope(pre, name) == 1, name


def test_no_acme_setting_uses_ambiguous_overridable_scope_zero():
    # CBA scope 0 means "local, but mission/server may overwrite it". ACME now intentionally uses:
    # 1 for shared gameplay and 2 for genuinely client-owned presentation/accessibility.
    combined = read("XEH_preInit.sqf") + "\n" + read("XEH_settings.hpp")
    setting_heads = re.finditer(
        r'\[\s*"(ACME_[^"]+)"\s*,\s*"(CHECKBOX|SLIDER|LIST|EDITBOX|COLOR)"',
        combined,
    )
    names = [m.group(1) for m in setting_heads]
    assert names
    for name in names:
        assert setting_scope(combined, name) in (1, 2), name
