"use strict";
// Tests that protect against the Push 3 all-columns regression.
//
// Root cause: calling live.banks 'new' after loadbang fires on_banks_changed,
// which causes Push to re-call create_device_bank. If get_bank_count()
// transiently returns 0 during the 'new' call, Push falls back to
// DeviceParameterBank (all-columns view). Only _createBankStructure (called
// at loadbang) may send 'new' to live.banks. Everything after that must use
// only 'edit'.

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

// ─── Static: 'new' confined to _createBankStructure ──────────────────────────

test("live.banks 'new' only sent from _createBankStructure (static source check)", () => {
    const src = fs.readFileSync(LOADER_PATH, "utf-8");

    const fnStart = src.indexOf("function _createBankStructure(");
    assert.ok(fnStart !== -1, "_createBankStructure must exist in nam_loader.js");

    // Walk braces to find the end of the function body.
    let depth = 0, i = src.indexOf("{", fnStart);
    while (i < src.length) {
        if (src[i] === "{") depth++;
        else if (src[i] === "}") { if (--depth === 0) break; }
        i++;
    }
    const fnEnd = i;

    // Find every .message("new" or .message('new' in the file.
    const re = /\.message\(\s*["']new["']/g;
    let m;
    const outside = [];
    while ((m = re.exec(src)) !== null) {
        if (m.index < fnStart || m.index > fnEnd) {
            outside.push(src.slice(0, m.index).split("\n").length);
        }
    }

    assert.strictEqual(outside.length, 0,
        `live.banks 'new' found outside _createBankStructure at line(s) ${outside}. ` +
        "This causes Push all-columns on load — only use 'edit' after loadbang.");
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
