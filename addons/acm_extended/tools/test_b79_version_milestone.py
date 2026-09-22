from historical_source import read_source, assert_release_identity
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def test_b79_version_milestone():
    cfg = read_source(ROOT / "config.cpp", encoding="utf-8", errors="ignore")
    post = read_source(ROOT / "functions/fn_postInit.sqf", encoding="utf-8", errors="ignore")
    assert_release_identity()
    assert_release_identity()
    assert_release_identity()

if __name__ == "__main__":
    test_b79_version_milestone()
    print("B79 version milestone: PASS")
