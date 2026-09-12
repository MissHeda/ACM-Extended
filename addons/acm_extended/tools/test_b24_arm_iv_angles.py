#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / 'functions' / 'fn_ivMinigameTick.sqf').read_text(encoding='utf-8-sig')

class B24ArmIVAngleSourceContracts(unittest.TestCase):
    def test_arms_use_fifteen_degree_base(self):
        self.assertIn('private _artSide = if (_patientLeft) then {"left"} else {"right"};', SRC)
        self.assertIn('ACME_iv_armEdgeStart', SRC)
        self.assertIn('ACME_iv_armEdgeExtraTiltDeg', SRC)

    def test_legs_use_fixed_fifteen_degree_family(self):
        self.assertIn('_bpT in ["leftarm", "leftleg"]', SRC)
        self.assertNotIn('_frame = "";', SRC)
        self.assertIn('ACME_iv_legTiltDeg', SRC)

    def test_arm_edges_smooth_toward_thirty(self):
        self.assertIn('private _edgeFrac = linearConversion', SRC)
        self.assertIn('ACME_iv_armEdgeExtraTiltDeg', SRC)

    def test_ej_uses_fixed_anatomical_fifteen_degree_family(self):
        self.assertIn('then {"_ej_15_%1"} else {"_15_%1"}', SRC)
        self.assertIn('ACME_iv_ejTiltDeg', SRC)

    def test_limb_center_reference_uses_measured_edges(self):
        self.assertIn('_refU = (_edgeLeft + _edgeRight) * 0.5;', SRC)

if __name__ == '__main__': unittest.main()
