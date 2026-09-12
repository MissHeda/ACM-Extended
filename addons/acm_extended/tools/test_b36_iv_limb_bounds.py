"""Measured-art and geometry regression checks; does not execute the Arma renderer."""
from functools import lru_cache
from pathlib import Path
import math
import re
import unittest
import numpy as np
from paa import read_paa
from generate_iv_limb_bounds import render

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'functions' / 'fn_ivLimbBounds.sqf').read_text(encoding='utf-8')


@lru_cache(maxsize=1)
def profiles():
    result = {}
    for texture, body in re.findall(r'case "([^"\n]+)":\s*\{(.*?)\n    \};', SOURCE, re.S):
        rows = re.findall(r'\[([\d.]+), ([\d.]+), ([\d.]+)\]', body)
        result[texture.rsplit('\\', 1)[-1]] = np.array(rows, dtype=float)
    return result


def at(profile, v):
    return tuple(float(np.interp(v, profile[:, 0], profile[:, column])) for column in (1, 2))


@lru_cache(maxsize=2)
def alpha(texture):
    # Use the full-resolution mip, independently of the 1024-mip generator.
    return read_paa(ROOT / 'ui' / 'iv' / texture, want=2048)[1]


def independent_arm_run(row):
    """Inside the declared spans, the arm is wider than the separate torso strip."""
    changes = np.diff(np.r_[False, row >= 128, False].astype(int))
    starts, ends = np.flatnonzero(changes == 1), np.flatnonzero(changes == -1)
    start, end = max(zip(starts, ends), key=lambda pair: pair[1] - pair[0])
    return start / len(row), end / len(row)


def extra_angle(x, left, right):
    center = (left + right) * .5
    normalized = abs(x - center) / ((right - left) * .5)
    fraction = max(0, min(1, (normalized - .60) / (.90 - .60)))
    return (-1 if x > center else 1) * 15 * fraction


class RightArmLimbBounds(unittest.TestCase):
    def test_only_right_arm_and_known_views_are_enabled(self):
        self.assertEqual(set(profiles()), {'iv_right_arm_ca.paa', 'iv_right_arm_rear_ca.paa'})
        self.assertIn('toLower _bodyPart != "rightarm" || {!finite _v}', SOURCE)
        self.assertIn('switch (toLower _viewTexture)', SOURCE)
        self.assertIn('default {[]};', SOURCE)
        self.assertIn('if (_v < ((_profile select 0) select 0)', SOURCE)
        self.assertIn('_v > ((_profile select ((count _profile) - 1)) select 0)', SOURCE)
        self.assertNotRegex(SOURCE, r'\b(?:setVariable|ctrlSetAngle|remoteExec|publicVariable|setPos)\b')

    def test_profiles_are_finite_ordered_and_bounded(self):
        for texture, profile in profiles().items():
            with self.subTest(texture=texture):
                self.assertTrue(np.isfinite(profile).all())
                self.assertTrue((np.diff(profile[:, 0]) > 0).all())
                self.assertTrue((profile[:, 1] < profile[:, 2]).all())
                self.assertTrue(((profile >= 0) & (profile <= 1)).all())
                self.assertLessEqual(len(profile), 64)
                self.assertGreaterEqual(profile[0, 0], .26 if 'rear' not in texture else .22)
                self.assertLessEqual(profile[-1, 0], .79)

    def test_profiles_match_full_resolution_arm_and_exclude_torso(self):
        for texture, profile in profiles().items():
            image = alpha(texture)
            height = image.shape[0]
            worst = 0
            for row in range(math.ceil(profile[0, 0] * height - .5),
                             math.floor(profile[-1, 0] * height - .5) + 1):
                v = (row + .5) / height
                measured = independent_arm_run(image[row])
                predicted = at(profile, v)
                worst = max(worst, *(abs(a - b) for a, b in zip(measured, predicted)))
                center = sum(predicted) * .5
                self.assertTrue(measured[0] < center < measured[1])
            with self.subTest(texture=texture, max_edge_error=worst):
                self.assertLessEqual(worst, 2.5 / 2048)

    def test_reported_front_arm_bias_is_removed_along_forearm(self):
        profile = profiles()['iv_right_arm_ca.paa']
        expected = ((.402, .5776), (.50, .5503), (.60, .5239), (.681, .5005))
        for v, approximate_center in expected:
            bounds = at(profile, v)
            center = sum(bounds) * .5
            self.assertAlmostEqual(center, approximate_center, delta=.0015)
            self.assertEqual(extra_angle(center, *bounds), 0)
        wrist_center = sum(at(profile, .681)) * .5
        old_bounds = (.5237, .6297)
        self.assertGreater(sum(old_bounds) * .5 - wrist_center, .07)
        self.assertEqual(extra_angle(wrist_center, *old_bounds), 15)

    def test_rear_view_follows_its_own_opposite_slope(self):
        front = profiles()['iv_right_arm_ca.paa']
        rear = profiles()['iv_right_arm_rear_ca.paa']
        self.assertLess(sum(at(front, .68)), sum(at(front, .40)))
        self.assertGreater(sum(at(rear, .68)), sum(at(rear, .40)))
        self.assertAlmostEqual(sum(at(rear, .255)) * .5, .455, delta=.002)
        self.assertAlmostEqual(sum(at(rear, .681)) * .5, .577, delta=.002)

    def test_equal_local_edge_fractions_are_symmetric_and_capped(self):
        for profile in profiles().values():
            for v in np.linspace(profile[0, 0], profile[-1, 0], 41):
                left, right = at(profile, v)
                center, half = (left + right) * .5, (right - left) * .5
                for fraction in (0, .25, .60, .75, .90, 1):
                    a = extra_angle(center - half * fraction, left, right)
                    b = extra_angle(center + half * fraction, left, right)
                    self.assertAlmostEqual(a, -b, delta=1e-10)
                    self.assertLessEqual(abs(a), 15)
                    if fraction >= .90:
                        self.assertAlmostEqual(abs(a), 15, delta=1e-10)

    def test_zoom_and_pan_preserve_local_neutral_axis(self):
        profile = profiles()['iv_right_arm_ca.paa']
        for width, height in ((1920, 1080), (2560, 1440), (5120, 1440)):
            for zoom in (.66 / .925, 1, 1.5):
                bh = .925 * zoom
                bw = bh * height / width
                for pan in (-.20, 0, .20):
                    for v in (.402, .50, .60, .681):
                        u = sum(at(profile, v)) * .5
                        bx, by = .5 - bw * .5, .5075 - bh * .5 + pan
                        x, y = bx + bw * u, by + bh * v
                        restored_u, restored_v = (x - bx) / bw, (y - by) / bh
                        self.assertAlmostEqual(restored_v, v)
                        self.assertEqual(extra_angle(restored_u, *at(profile, restored_v)), 0)

    def test_generated_source_is_reproducible(self):
        self.assertEqual(SOURCE, render())


if __name__ == '__main__':
    unittest.main()
