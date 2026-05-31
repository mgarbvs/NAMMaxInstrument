"use strict";
// Tests that protect against the Push 3 bank regressions.
//
// Bank 0 (NAM) is baked into the saved device as parameterbanks (built by
// build_nam_maxpat.py), so it exists with bank_count > 0 before this JS runs —
// fixing the original all-columns-on-first-load bug. Because the bank already
// exists at index 0, sending live.banks 'new 0' would INSERT a duplicate and
// push the baked bank to index 1 (spurious second page). So nam_loader.js must
// never send 'new' to live.banks at all — only 'edit', which mutates the
// existing baked bank in place.

const assert = require("assert");
const fs     = require("fs");
const path   = require("path");

const LOADER_PATH = path.join(__dirname, "../m4l/nam_loader.js");

// Stub Max globals so nam_loader.js can be required in Node.
if (typeof global.post      === "undefined") global.post      = () => {};
if (typeof global.outlet    === "undefined") global.outlet    = () => {};
if (typeof global.messnamed === "undefined") global.messnamed = () => {};
if (typeof global.Folder    === "undefined") global.Folder    = function() {
    this.end = true; this.next = () => {}; this.close = () => {};
};

const loader = require(LOADER_PATH);

let passed = 0, failed = 0;
function test(name, fn) {
    try   { fn(); console.log("  PASS", name); passed++; }
    catch (e) { console.error("  FAIL", name, "\n      ", e.message); failed++; }
}

// ─── Static: no 'new' sent to live.banks anywhere ────────────────────────────

test("nam_loader.js never sends live.banks 'new' (bank is baked)", () => {
    const src = fs.readFileSync(LOADER_PATH, "utf-8");

    // Find every .message("new" or .message('new' in the file.
    const re = /\.message\(\s*["']new["']/g;
    let m;
    const hits = [];
    while ((m = re.exec(src)) !== null) {
        hits.push(src.slice(0, m.index).split("\n").length);
    }

    assert.strictEqual(hits.length, 0,
        `live.banks 'new' found at line(s) ${hits}. The NAM bank is baked into ` +
        "the device (parameterbanks); sending 'new' inserts a duplicate bank. " +
        "Use 'edit' to mutate the existing bank in place.");
});

// ─── Behavioral: _populateBanks sends only 'edit' ────────────────────────────

test("_populateBanks sends only edit (no new) to live.banks", () => {
    const messages = [];
    const mockBanks   = { message: (...args) => messages.push([...args]) };
    const mockPatcher = { getnamed: n => n === "live_banks" ? mockBanks : null };

    loader._internals.setPatcherForTest(mockPatcher);
    loader._internals.resetBanksForTest();
    loader._internals.populateBanks();

    const newMsgs  = messages.filter(m => m[0] === "new");
    const editMsgs = messages.filter(m => m[0] === "edit");

    assert.strictEqual(newMsgs.length, 0,
        `_populateBanks must not call live.banks 'new'. Got: ${JSON.stringify(newMsgs)}`);
    assert.ok(editMsgs.length > 0,
        "_populateBanks must send at least one 'edit' to live.banks");
});

// ─── Summary ─────────────────────────────────────────────────────────────────
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
