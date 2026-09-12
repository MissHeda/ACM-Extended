"""Focused regression for mixed-syringe reservation across vial selection changes.

Offline behavioral contract paired with the renderer branch; Arma UI testing remains required.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MixedVialContents(unittest.TestCase):
    def test_locked_a_stays_reserved_when_b_is_selected(self):
        source = (ROOT / "functions/fn_skListRefresh.sqf").read_text()
        reserve = source.split("private _fnReservedMl = {", 1)[1].split("private _fnStockInfo", 1)[0]
        self.assertNotIn("if (!_selected) exitWith", reserve)
        self.assertLess(reserve.index("forEach (uiNamespace getVariable [\"ACME_SK_CompoundComponents\""),
                        reserve.index("if (_selected) then"))
        self.assertIn('if (_stage == "" && {_selected}) then', reserve)

        # A has two locked pulls totaling 3 mL; B is selected with a 1 mL plunger tail.
        # Switching to B must not make A's contents/count return to their initial values.
        components = [("A", 2), ("A", 1)]
        starting_ml = {"A": 3, "B": 5}
        selected, tail = "B", 1
        remaining = {}
        for medication, start in starting_ml.items():
            locked = sum(volume for name, volume in components if name == medication)
            reserved = locked + (tail if medication == selected else 0)
            remaining[medication] = max(start - reserved, 0)
        self.assertEqual(remaining, {"A": 0, "B": 4})
        self.assertEqual({med: int(ml > 0) for med, ml in remaining.items()}, {"A": 0, "B": 1})


if __name__ == "__main__":
    unittest.main()
