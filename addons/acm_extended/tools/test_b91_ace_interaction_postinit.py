from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
POST = (ROOT / "functions/fn_postInit.sqf").read_text(encoding="utf-8")

# Public release is v1.2.0-r0; internal batch advances.
assert 'ACME_buildBatch = "B92";' in POST
assert 'ACME_infusion_version = "1.2.0-r0"' in POST

# Regression: this sentence accidentally lost // and made the entire postInit fail to compile,
# which removed all ACE interaction actions in game.
assert '\n the flashlight filter flag must never strand ACE.' not in POST
assert '// the flashlight filter flag must never strand ACE.' in POST

# The ACE notOnMap extension and close/watchdog cleanup must remain intact.
assert '["notOnMap", {' in POST
assert 'call ace_common_fnc_addCanInteractWithCondition;' in POST
assert '["ace_interactMenuClosed", {' in POST
assert 'missionNamespace setVariable ["ACME_flashlightMenuActive", false];' in POST
assert 'call CBA_fnc_addPerFrameHandler;' in POST

# The retired diagnostics should stay retired.
for forbidden in ('diag_log', 'systemChat', 'hintSilent', 'ACME_flashlight_diag'):
    assert forbidden not in POST, forbidden

# Cheap structural guard for this critical file: ignore // comments and quoted strings, then
# verify delimiters remain balanced. This catches the common accidental edit class that caused B90.
def strip_sqf(s: str) -> str:
    out=[]; i=0; in_str=False
    while i < len(s):
        c=s[i]
        if in_str:
            if c == '"':
                if i+1 < len(s) and s[i+1] == '"':
                    i += 2; continue
                in_str=False
            i += 1; continue
        if c == '"':
            in_str=True; i += 1; continue
        if c == '/' and i+1 < len(s) and s[i+1] == '/':
            j=s.find('\n', i+2)
            if j == -1: break
            out.append('\n'); i=j+1; continue
        if c == '/' and i+1 < len(s) and s[i+1] == '*':
            j=s.find('*/', i+2)
            assert j != -1, 'unterminated block comment'
            i=j+2; continue
        out.append(c); i += 1
    assert not in_str, 'unterminated string'
    return ''.join(out)

clean = strip_sqf(POST)
pairs={')':'(',']':'[','}':'{'}; stack=[]
for ch in clean:
    if ch in '([{': stack.append(ch)
    elif ch in ')]}':
        assert stack and stack[-1] == pairs[ch], (ch, stack[-5:])
        stack.pop()
assert not stack, stack[-10:]

print('B92 ACE interaction/postInit regression checks: PASS')
