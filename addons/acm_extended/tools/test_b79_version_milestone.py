from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def test_b79_version_milestone():
    cfg = (ROOT / "config.cpp").read_text(encoding="utf-8", errors="ignore")
    post = (ROOT / "functions/fn_postInit.sqf").read_text(encoding="utf-8", errors="ignore")
    assert 'version = "1.2.0-r0";' in cfg
    assert 'ACME_infusion_version = "1.2.0-r0"' in post
    assert 'ACME_buildBatch = "B79";' in post

if __name__ == "__main__":
    test_b79_version_milestone()
    print("B79 version milestone: PASS")
