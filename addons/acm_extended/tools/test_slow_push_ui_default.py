from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8-sig", errors="strict")


def test_duration_row_layout_executes_and_tracks_push_button():
    s = read("functions/fn_skBodyActionRender.sqf")
    assert "\n{\n    private _durGap" not in s
    assert "private _pushRect = +(ctrlPosition _btn);" in s
    assert "_durLabel ctrlSetPosition [_pushRect select 0, _durY, _labelW, _durH];" in s
    assert "_durEdit ctrlSetPosition [(_pushRect select 0) + _labelW + _durGap, _durY, _editW, _durH];" in s


def test_blank_or_recommended_placeholder_keeps_push_enabled():
    s = read("functions/fn_skBodyActionRender.sqf")
    assert 'private _hasTypedDuration = !_ghost && {_rawDur != ""};' in s
    assert 'private _numDur = if (_hasTypedDuration) then {parseNumber _rawDur} else {3};' in s
    assert '_validPushTime = !_hasTypedDuration || {_numDur >= 1 && {_numDur <= 300}};' in s


def test_normal_push_blank_defaults_to_three_seconds():
    s = read("functions/fn_skConfirmInjection.sqf")
    assert "private _pushSec = 3;" in s
    assert 'if (_raw != "") then {' in s
    assert "if (_pushDurationValid) then {_pushSec = _typed;};" in s
    assert "Leave it blank to use 3 seconds." in s


def test_hardcore_push_blank_defaults_to_three_seconds():
    s = read("functions/fn_hardcorePushStart.sqf")
    assert "private _dur = 3;" in s
    assert "private _durValid = true;" in s
    assert 'if (_raw != "") then {' in s
    assert '_durValid = _dur >= 1 && {_dur <= 300};' in s


def test_recommended_times_remain_display_only_gray_guidance():
    body = read("functions/fn_skBodyActionRender.sqf")
    rec = read("functions/fn_medicationSuggestedPushSec.sqf")
    assert 'call ACME_fnc_medicationSuggestedPushSec' in body
    assert '_durEdit ctrlSetTextColor [0.56,0.58,0.62,0.82];' in body
    assert '_durEdit setVariable ["ACME_SK_GhostActive",true];' in body
    for med, seconds in [
        ("Adenosine", 3),
        ("Ketamine", 30),
        ("CalciumChloride", 300),
        ("CalciumGluconate", 120),
        ("Amiodarone", 300),
        ("Norepinephrine", 60),
        ("Esmolol", 60),
        ("Lidocaine", 60),
        ("Magnesium", 300),
        ("Propofol", 30),
        ("Midazolam", 60),
        ("Fentanyl", 30),
        ("Morphine", 60),
        ("Rocuronium", 30),
    ]:
        assert f'case "{med}": {{{seconds}}};' in rec


def test_seconds_edit_preserves_focus_and_does_not_swallow_keys():
    body = read("functions/fn_skBodyActionRender.sqf")
    tick = read("functions/fn_skUiTick.sqf")
    assert 'ctrlAddEventHandler ["SetFocus"' in body
    assert 'ctrlAddEventHandler ["KeyDown"' not in body
    assert 'call ACME_fnc_skBodyActionRender;' not in body.split('ctrlAddEventHandler ["KeyUp"', 1)[1].split('}];', 1)[0]
    assert 'ctrlIDC _focus) != 84831' in tick
    assert 'if (!_durFocused) then {' in body


def test_hardcore_push_plunger_tracks_authoritative_remaining_volume():
    carousel = read("functions/fn_skCarouselRender.sqf")
    tick = read("functions/fn_hardcorePushTick.sqf")
    assert 'ACME_SK_PushAnimPFH' in carousel
    assert '_normalPushAnimActive' in carousel
    assert 'if !(_normalPushAnimActive && {_slot == 2})' in carousel
    assert 'private _plUi = _open displayCtrl 84422;' in tick
    assert '_plUi ctrlSetPosition' in tick
    assert '_remainUi' in tick
