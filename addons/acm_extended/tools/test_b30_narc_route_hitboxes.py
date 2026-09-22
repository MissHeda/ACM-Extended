"""Evaluate production Narc Box rectangles and stacking at button click points.

This is a source/math regression, not an Arma engine input test. It includes the
transparent native body canvas that previously intercepted most route clicks,
the separate route backings, and the optional epinephrine dose button.
"""
from historical_source import read_source
from pathlib import Path
import operator
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
INJECT = read_source(ROOT / 'functions/fn_skInject.sqf')
DOSE = read_source(ROOT / 'functions/fn_skEpinephrineDose.sqf')
INIT = read_source(ROOT / 'functions/fn_postInit.sqf')
OPS = {'+': (1, operator.add), '-': (1, operator.sub), '*': (2, operator.mul),
       '/': (2, operator.truediv), 'min': (1, min), 'max': (1, max)}


def scalar(code, env):
    """Evaluate just the scalar SQF arithmetic used by these real UI rectangles."""
    code = re.sub(r'missionNamespace getVariable \["([^"]+)",\s*([\d.]+)\]',
                  lambda m: str(env.get(m[1], float(m[2]))), code)
    tokens = re.findall(r'[A-Za-z_]\w*|\d+(?:\.\d+)?|[()+*/-]', code)
    index = 0

    def parse(level=0):
        nonlocal index
        token = tokens[index]
        index += 1
        if token == '(':
            value = parse()
            assert tokens[index] == ')'
            index += 1
        elif token[0].isalpha() or token[0] == '_':
            value = env[token]
        else:
            value = float(token)
        while index < len(tokens) and tokens[index] in OPS and OPS[tokens[index]][0] >= level:
            precedence, op = OPS[tokens[index]]
            index += 1
            value = op(value, parse(precedence + 1))
        return value

    result = parse()
    assert index == len(tokens), code
    return result


def assignment(name, env):
    code = re.search(r'private ' + name + r'\s*=\s*([^;]+);', INJECT)[1]
    env[name] = scalar(code, env)


def rectangle(name, env, source=INJECT):
    if name == '_bodyGroup':
        code = re.search(r'private _rect = \[([^\]]+)\]', source)[1]
    else:
        code = re.search(name + r' ctrlSetPosition \[([^\]]+)\]', source)[1]
    return tuple(scalar(part.strip(), env) for part in code.split(','))


def contains(rect, point):
    x, y, w, h = rect
    px, py = point
    return x <= px <= x+w and y <= py <= y+h


def layout(width=5120, height=1440, scale=1, expanded=False):
    sw, sh = width / height * scale, scale
    env = dict(safeZoneX=(1-sw)/2, safeZoneY=(1-sh)/2,
               safeZoneW=sw, safeZoneH=sh, pixelW=sw/width, pixelH=sh/height)

    # B61 keeps the compact/expanded tandem geometry but moves the route row completely below the body canvas.
    # Evaluate the production constants directly rather than assuming the older fixed rectangle.
    fill_v = float(re.search(r'ACME_SK_BodyFillV",\s*([\d.]+)', INJECT)[1])
    body_h = sh * (0.32 if expanded else 0.64) / fill_v
    body_w = body_h * env['pixelW'] / env['pixelH']
    body_rect = (env['safeZoneX'] + sw/2 - body_w/2,
                 env['safeZoneY'] + sh*(0.010 if expanded else 0.012), body_w, body_h)

    tw = sw / 11
    th = sh / 32
    tx = env['safeZoneX'] + sw/2 - tw/2
    gap = 2 * env['pixelW']
    half = (tw - gap) / 2
    route_y = env['safeZoneY'] + sh * (0.472 if expanded else 0.748)
    view_y = env['safeZoneY'] + sh / 1.08
    rects = {
        '_bodyGroup': body_rect,
        '_pulseBack': (tx, view_y, tw, th),
        '_toggleBtn': (tx, view_y, tw, th),
        '_routeIVBack': (tx, route_y, half, th),
        '_routeIMBack': (tx + half + gap, route_y, half, th),
        '_routeBtn': (tx, route_y, half, th),
        '_routeIM': (tx + half + gap, route_y, half, th),
    }
    names = ('_bodyGroup', '_pulseBack', '_toggleBtn', '_routeIVBack', '_routeIMBack', '_routeBtn', '_routeIM')
    layers = [(name, rects[name], INJECT.index('private ' + name + ' = _display ctrlCreate')) for name in names]

    anchor_id = re.search(r'displayCtrl (\d+)\)\) params \["_x", "_y", "_w", "_h"\]', DOSE)[1]
    anchor = {'84151': '_routeBtn', '84154': '_routeIM'}[anchor_id]
    x, y, w, h = rects[anchor]
    dose_rect = (x + w + sw/200, y, w*2.4, h)
    layers.append(('_dose', dose_rect, len(INJECT)))
    return sorted(layers, key=lambda item: item[2])


class NarcRouteHitboxes(unittest.TestCase):
    def test_full_route_button_area_receives_clicks(self):
        for size in ((1280,720), (1920,1080), (2560,1440), (3440,1440), (5120,1440)):
            for scale in (1, 1.4, 2):
                layers = layout(*size, scale)
                for route in ('_routeBtn', '_routeIM'):
                    rect = next(rect for name, rect, _ in layers if name == route)
                    x, y, w, h = rect
                    for u in (.01, .25, .5, .75, .99):
                        for v in (.01, .25, .5, .75, .99):
                            point = (x+u*w, y+v*h)
                            top = next(name for name, rect, _ in reversed(layers) if contains(rect, point))
                            with self.subTest(size=size, scale=scale, route=route, u=u, v=v):
                                self.assertEqual(top, route)

    def test_route_row_no_longer_overlaps_body_canvas_in_b61_layouts(self):
        # The visual clipping reported in B60 came from route controls sitting inside the body-group rectangle.
        # B61 deliberately leaves a real vertical gap in both compact and expanded states.
        for expanded in (False, True):
            layers = layout(expanded=expanded)
            body_rect = next(rect for name, rect, _ in layers if name == '_bodyGroup')
            bx, by, bw, bh = body_rect
            body_bottom = by + bh
            for route in ('_routeBtn', '_routeIM'):
                x, y, w, h = next(rect for name, rect, _ in layers if name == route)
                self.assertGreater(y, body_bottom)
                for u in (.1, .5, .9):
                    for v in (.1, .5, .9):
                        self.assertFalse(contains(body_rect, (x+u*w, y+v*h)))

    def test_toolbar_is_created_after_all_body_site_inputs(self):
        # Site overlays are separate display children. Even under a taller custom
        # body canvas the route toolbar must win over those input rectangles too.
        sites_done = INJECT.index('} forEach _inputs;')
        for route in ('_routeBtn', '_routeIM', '_toggleBtn'):
            self.assertGreater(INJECT.index('private ' + route + ' = _display ctrlCreate'), sites_done)


if __name__ == '__main__':
    unittest.main()
