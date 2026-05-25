#!/usr/bin/env python3
"""test_validate_maxpat.py — plain-assert tests for scripts/validate_maxpat.py."""

import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VALIDATOR = os.path.join(ROOT, "scripts", "validate_maxpat.py")


def base_patcher(extra_boxes=None, extra_top=None):
    boxes = [
        {"box": {"id": "thisdev", "maxclass": "newobj", "text": "live.thisdevice"}},
    ]
    if extra_boxes:
        boxes.extend(extra_boxes)
    patcher = {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 0, "revision": 10, "architecture": "x64", "modernui": 1},
        "boxes": boxes,
        "lines": [],
    }
    if extra_top:
        patcher.update(extra_top)
    return {"patcher": patcher}


def run_validator(doc):
    with tempfile.NamedTemporaryFile("w", suffix=".maxpat", delete=False) as f:
        json.dump(doc, f)
        path = f.name
    try:
        r = subprocess.run(
            [sys.executable, VALIDATOR, path], capture_output=True, text=True
        )
        return r.returncode, r.stdout, r.stderr
    finally:
        os.unlink(path)


def test_clean_passes():
    rc, _, err = run_validator(base_patcher())
    assert rc == 0, f"clean patcher should pass; got rc={rc} err={err}"


def test_top_level_parameters_fails():
    doc = base_patcher(extra_top={"parameters": {"parameterbanks": {}}})
    rc, _, err = run_validator(doc)
    assert rc == 1 and "parameters" in err, f"expected parameters error; got rc={rc} err={err}"


def test_longname_collision_fails():
    a = {"box": {"id": "a", "maxclass": "live.dial", "parameter_enable": 1,
                 "saved_attribute_attributes": {"valueof": {"parameter_longname": "Gain"}}}}
    b = {"box": {"id": "b", "maxclass": "live.dial", "parameter_enable": 1,
                 "saved_attribute_attributes": {"valueof": {"parameter_longname": "Gain"}}}}
    rc, _, err = run_validator(base_patcher(extra_boxes=[a, b]))
    assert rc == 1 and "duplicate" in err, f"expected dup error; got rc={rc} err={err}"


def test_presentation_band_fails():
    b = {"box": {"id": "out", "maxclass": "live.dial",
                 "presentation": 1, "presentation_rect": [10, 150, 50, 20]}}
    rc, _, err = run_validator(base_patcher(extra_boxes=[b]))
    assert rc == 1 and "166px" in err, f"expected band error; got rc={rc} err={err}"


def test_missing_thisdevice_fails():
    doc = {"patcher": {"boxes": [], "lines": []}}
    rc, _, err = run_validator(doc)
    assert rc == 1 and "live.thisdevice" in err, f"expected thisdevice error; got rc={rc} err={err}"


def test_param_enable_without_longname_fails():
    b = {"box": {"id": "x", "maxclass": "live.dial", "parameter_enable": 1,
                 "saved_attribute_attributes": {"valueof": {}}}}
    rc, _, err = run_validator(base_patcher(extra_boxes=[b]))
    assert rc == 1 and "longname" in err, f"expected longname error; got rc={rc} err={err}"


TESTS = [
    test_clean_passes,
    test_top_level_parameters_fails,
    test_longname_collision_fails,
    test_presentation_band_fails,
    test_missing_thisdevice_fails,
    test_param_enable_without_longname_fails,
]


def main():
    fails = 0
    for t in TESTS:
        try:
            t()
            print(f"PASS  {t.__name__}")
        except AssertionError as e:
            fails += 1
            print(f"FAIL  {t.__name__}: {e}")
    if fails:
        print(f"\n{fails} test(s) failed")
        sys.exit(1)
    print(f"\nAll {len(TESTS)} tests passed")


if __name__ == "__main__":
    main()
