"use strict";
const assert = require("assert");
const fs     = require("fs");
const path   = require("path");
const os     = require("os");

const { patchAmxdEnums, _helpers } = require("../m4l/push_name_patch.js");
const { commonPrefix, trimToWordBound, makeDisplayNames } = _helpers;

const AMXD_PATH   = path.join(__dirname, "../m4l/NAM.amxd");
const HEADER_SIZE = 32;

function readAmxd(p) {
    const data = fs.readFileSync(p);
    return {
        header:  data.slice(0, HEADER_SIZE),
        patcher: JSON.parse(data.slice(HEADER_SIZE).toString("utf-8")),
        jsonLen: data.readUInt32LE(28),
    };
}

let passed = 0, failed = 0;
function test(name, fn) {
    try { fn(); console.log("  PASS", name); passed++; }
    catch (e) { console.error("  FAIL", name, "\n      ", e.message); failed++; }
}

// ─── display-name helpers ─────────────────────────────────────────────────────
test("commonPrefix: shared prefix", () => {
    assert.strictEqual(commonPrefix(["foobar", "foobaz", "fooqq"]), "foo");
});
test("commonPrefix: no shared prefix", () => {
    assert.strictEqual(commonPrefix(["abc", "xyz"]), "");
});
test("commonPrefix: single item", () => {
    assert.strictEqual(commonPrefix(["hello"]), "hello");
});
test("trimToWordBound: stops at last space", () => {
    // String ending in space → last space found immediately → full string returned
    assert.strictEqual(trimToWordBound("IR Collection - "), "IR Collection - ");
    assert.strictEqual(trimToWordBound("Fender "),          "Fender ");
    // No spaces → walks to start → returns ""
    assert.strictEqual(trimToWordBound("nospaces"),         "");
    // Space in middle → trims from last space to end
    assert.strictEqual(trimToWordBound("has middle"),       "has ");
});
test("makeDisplayNames: strips common prefix across files", () => {
    const names = makeDisplayNames(["IR Coll - A.wav", "IR Coll - B.wav"], /\.wav$/i);
    assert.deepStrictEqual(names, ["A", "B"]);
});
test("makeDisplayNames: no trim on single file", () => {
    assert.deepStrictEqual(makeDisplayNames(["Fender.nam"], /\.nam$/i), ["Fender"]);
});
test("makeDisplayNames: strips leading dash/space after prefix", () => {
    const names = makeDisplayNames(["Tweed - Close.wav", "Tweed - Far.wav"], /\.wav$/i);
    assert.deepStrictEqual(names, ["Close", "Far"]);
});

// ─── binary roundtrip ────────────────────────────────────────────────────────
test("header bytes 0-27 are byte-identical after patch", () => {
    const tmp = path.join(os.tmpdir(), "NAM_rt_test.amxd");
    fs.copyFileSync(AMXD_PATH, tmp);
    try {
        const orig    = readAmxd(AMXD_PATH);
        const testMap = {
            "nam_cat_idx":   ["Cat A", "Cat B"],
            "nam_model_idx": ["Alpha", "Beta", "Gamma"],
            "ir_cat_idx":    ["IR A"],
            "ir_file_idx":   ["Close", "Mid", "Far"],
        };
        patchAmxdEnums(tmp, testMap);
        const patched = readAmxd(tmp);

        assert.ok(patched.header.slice(0, 28).equals(orig.header.slice(0, 28)),
                  "header bytes 0-27 must be byte-identical to original");

        const actualJsonBytes = fs.readFileSync(tmp).slice(HEADER_SIZE);
        assert.strictEqual(patched.jsonLen, actualJsonBytes.length,
                           "header JSON-length field must match actual JSON byte count");

        for (const b of patched.patcher.patcher.boxes) {
            const vn = b.box && b.box.varname;
            if (!vn || !testMap[vn]) continue;
            assert.deepStrictEqual(
                b.box.saved_attribute_attributes.valueof.parameter_enum,
                testMap[vn],
                `${vn} parameter_enum mismatch`,
            );
        }
    } finally { try { fs.unlinkSync(tmp); } catch (_) {} }
});

test("absent keys are not modified", () => {
    const tmp = path.join(os.tmpdir(), "NAM_skip_test.amxd");
    fs.copyFileSync(AMXD_PATH, tmp);
    try {
        const orig    = readAmxd(AMXD_PATH);
        const testMap = { "nam_cat_idx": ["Only Cat"] };
        patchAmxdEnums(tmp, testMap);
        const patched = readAmxd(tmp);

        for (const b of patched.patcher.patcher.boxes) {
            const vn = b.box && b.box.varname;
            if (!vn) continue;
            if (vn === "nam_cat_idx") {
                assert.deepStrictEqual(
                    b.box.saved_attribute_attributes.valueof.parameter_enum,
                    ["Only Cat"]);
            } else if (["nam_model_idx","ir_cat_idx","ir_file_idx"].includes(vn)) {
                const origBox = orig.patcher.patcher.boxes
                    .find(ob => ob.box && ob.box.varname === vn);
                assert.deepStrictEqual(
                    b.box.saved_attribute_attributes.valueof.parameter_enum,
                    origBox.box.saved_attribute_attributes.valueof.parameter_enum,
                    `${vn} should be unchanged`);
            }
        }
    } finally { try { fs.unlinkSync(tmp); } catch (_) {} }
});

test("result re-parses as valid JSON after patch", () => {
    const tmp = path.join(os.tmpdir(), "NAM_json_test.amxd");
    fs.copyFileSync(AMXD_PATH, tmp);
    try {
        patchAmxdEnums(tmp, { "nam_cat_idx": ["X", "Y"] });
        const data    = fs.readFileSync(tmp);
        const jsonStr = data.slice(HEADER_SIZE).toString("utf-8");
        assert.doesNotThrow(() => JSON.parse(jsonStr), "patched JSON must be valid");
    } finally { try { fs.unlinkSync(tmp); } catch (_) {} }
});

// ─── summary ─────────────────────────────────────────────────────────────────
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
