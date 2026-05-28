// test_nam_loader.js — Node-runnable tests for m4l/nam_loader.js.
//
// Strategy: stub Max globals (Folder, outlet, arrayfromargs, messnamed) into
// `global`, then require the real loader. Per KB §12: never duplicate the
// function under test in the test file.

var path = require("path");

var outletCalls = [];
var messnamedCalls = [];

// Controllable in-memory file tree for the Folder stub.
// Shape: { "/abs/path": { dirs: ["sub1", ...], files: ["a.nam", "b.txt"] } }
var FILES = {};

function _Folder(abspath) {
    var entry = FILES[abspath] || { dirs: [], files: [] };
    this._items = [];
    this.typelist = null;
    var i;
    for (i = 0; i < (entry.dirs || []).length; i++) {
        this._items.push({ name: entry.dirs[i], isDir: true });
    }
    for (i = 0; i < (entry.files || []).length; i++) {
        this._items.push({ name: entry.files[i], isDir: false });
    }
    this._idx = 0;
    var self = this;
    Object.defineProperty(this, "end", {
        get: function() { return self._pos() >= self._items.length; }
    });
    Object.defineProperty(this, "filename", {
        get: function() {
            var it = self._items[self._pos()];
            return it ? it.name : "";
        }
    });
}
_Folder.prototype._pos = function() {
    while (this._idx < this._items.length) {
        var it = this._items[this._idx];
        if (this.typelist && this.typelist.indexOf("fold") !== -1 && !it.isDir) {
            this._idx++;
            continue;
        }
        return this._idx;
    }
    return this._items.length;
};
_Folder.prototype.next = function() { this._idx++; };
_Folder.prototype.close = function() {};

global.Folder = _Folder;
global.outlet = function() {
    var args = Array.prototype.slice.call(arguments);
    outletCalls.push(args);
};
global.arrayfromargs = function() {
    var out = [];
    for (var i = 0; i < arguments.length; i++) {
        var a = arguments[i];
        if (a != null && typeof a === "object" && typeof a.length === "number") {
            for (var j = 0; j < a.length; j++) out.push(a[j]);
        } else {
            out.push(a);
        }
    }
    return out;
};
global.messnamed = function() {
    messnamedCalls.push(Array.prototype.slice.call(arguments));
};
global.post = function() {};
// Loader sets inlets/outlets/autowatch at top scope.
global.inlets = 0;
global.outlets = 0;
global.autowatch = 0;

var loader = require("../m4l/nam_loader.js");

// ─── test helpers ────────────────────────────────────────────────────

var failures = 0;
var passes = 0;

function assertEq(actual, expected, label) {
    var a = JSON.stringify(actual);
    var b = JSON.stringify(expected);
    if (a === b) {
        passes++;
        console.log("PASS  " + label);
    } else {
        failures++;
        console.log("FAIL  " + label + " — expected " + b + " got " + a);
    }
}

function assertContains(haystack, needle, label) {
    var found = (typeof haystack === "string" && typeof needle === "string")
        ? haystack.indexOf(needle) !== -1
        : JSON.stringify(haystack).indexOf(JSON.stringify(needle)) !== -1;
    if (found) {
        passes++;
        console.log("PASS  " + label);
    } else {
        failures++;
        console.log("FAIL  " + label + " — " + JSON.stringify(needle) + " not in " + JSON.stringify(haystack));
    }
}

function reset() {
    outletCalls = [];
    messnamedCalls = [];
    FILES = {};
}

// ─── tests ───────────────────────────────────────────────────────────

// 1. maxPathToPosix Mac path round-trip
(function() {
    reset();
    var r = loader.maxPathToPosix("MyVolume:/Users/foo/Models");
    assertEq(r, "/Volumes/MyVolume/Users/foo/Models", "maxPathToPosix mac");
    var r2 = loader.maxPathToPosix("Macintosh HD:/Users/me/x/");
    assertEq(r2, "/Volumes/Macintosh HD/Users/me/x", "maxPathToPosix strips trailing slash");
})();

// 2. set_nam_root outlet sequence: clear -> N appends -> set 0 (umenu protocol)
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean", "HighGain"], files: [] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam", "vox.nam"] };
    loader.set_nam_root("V:/Models");

    var catCalls = outletCalls.filter(function(c) { return c[0] === 0; });
    assertEq(catCalls[0], [0, "clear"], "cat clear");
    assertEq(catCalls[1], [0, "append", "Clean"], "cat append Clean");
    assertEq(catCalls[2], [0, "append", "HighGain"], "cat append HighGain");
    assertEq(catCalls[3], [0, "set", 0], "cat set 0");

    var modelCalls = outletCalls.filter(function(c) { return c[0] === 1; });
    assertEq(modelCalls[0], [1, "clear"], "model clear");
    assertEq(modelCalls[1], [1, "append", "fender"], "model append fender.nam");
    assertEq(modelCalls[2], [1, "append", "vox"], "model append vox.nam");
    assertEq(modelCalls[3], [1, "set", 0], "model set 0");
})();

// 3. select_nam_category enumerates only .nam files
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: [] };
    FILES["/Volumes/V/Models/Clean"] = {
        dirs: [], files: ["fender.nam", "readme.txt", "FENDER.NAM", "vox.nam"]
    };
    loader.set_nam_root("V:/Models");

    var modelCalls = outletCalls.filter(function(c) { return c[0] === 1; });
    var appends = modelCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    // Both .nam and .NAM (lowercased compare) should be picked up; extensions stripped.
    assertEq(appends.sort(), ["FENDER", "fender", "vox"], "only .nam files");
})();

// 4. select_nam_model emits load message with abspath and notifies nam_state
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: [] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam"] };
    loader.set_nam_root("V:/Models");

    outletCalls = [];
    messnamedCalls = [];
    loader.select_nam_model(0);

    var loadCalls = outletCalls.filter(function(c) { return c[0] === 4; });
    assertEq(loadCalls[0], [4, "load", "/Volumes/V/Models/Clean/fender.nam"], "load message");

    var relpathMsg = messnamedCalls.filter(function(c) { return c[0] === "nam_state_set_nam_relpath"; });
    assertEq(relpathMsg[0], ["nam_state_set_nam_relpath", "Clean/fender.nam"], "relpath persisted");
})();

// 5. rehydrate with a missing file emits "Missing: <name>" on status outlet
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: [] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["other.nam"] };
    var state = JSON.stringify({
        nam_root: "/Volumes/V/Models",
        nam_relpath: "Clean/missing.nam",
    });
    loader.rehydrate(state);

    var statusCalls = outletCalls.filter(function(c) { return c[0] === 6; });
    var msgs = statusCalls.map(function(c) { return c[2]; }).join("|");
    assertContains(msgs, "Missing: Clean/missing.nam", "rehydrate missing surfaces status");
})();

// 6. rehydrate with a valid relpath selects the file
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: [] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam", "vox.nam"] };
    var state = JSON.stringify({
        nam_root: "/Volumes/V/Models",
        nam_relpath: "Clean/vox.nam",
    });
    loader.rehydrate(state);

    var loadCalls = outletCalls.filter(function(c) { return c[0] === 4; });
    assertEq(loadCalls[0], [4, "load", "/Volumes/V/Models/Clean/vox.nam"], "rehydrate triggers load");
})();

// 7. IR flow: set_ir_root + select_ir filters .wav
(function() {
    reset();
    FILES["/Volumes/V/IRs"] = { dirs: ["Cabs"], files: [] };
    FILES["/Volumes/V/IRs/Cabs"] = { dirs: [], files: ["4x12.wav", "notes.txt", "1x12.WAV"] };
    loader.set_ir_root("V:/IRs");

    var irCalls = outletCalls.filter(function(c) { return c[0] === 3; });
    var appends = irCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    // Extensions stripped; no common prefix between "1x12" and "4x12".
    assertEq(appends.sort(), ["1x12", "4x12"], "only .wav IRs");

    outletCalls = [];
    loader.select_ir(0);
    var loadCalls = outletCalls.filter(function(c) { return c[0] === 5; });
    assertEq(loadCalls[0][1], "read", "IR uses read message");
})();

// 8. Trim prefix: IR files with long shared prefix are trimmed to the suffix
(function() {
    reset();
    FILES["/Volumes/V/IRs"] = { dirs: ["FenderTwin"], files: [] };
    FILES["/Volumes/V/IRs/FenderTwin"] = { dirs: [], files: [
        "1971 Fender Twin Reverb - C414 - Cap.wav",
        "1971 Fender Twin Reverb - C414 - Cone.wav",
        "1971 Fender Twin Reverb - i5 - Cap.wav",
    ]};
    loader.set_ir_root("V:/IRs");
    // trim_prefix_ir is 1 (default); common prefix stripped to word boundary
    var irCalls = outletCalls.filter(function(c) { return c[0] === 3; });
    var appends = irCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    assertEq(appends, ["C414 - Cap", "C414 - Cone", "i5 - Cap"], "trim prefix strips shared IR prefix");
})();

// 9. Trim prefix off: full name (no extension) shown
(function() {
    reset();
    FILES["/Volumes/V/IRs"] = { dirs: ["FenderTwin"], files: [] };
    FILES["/Volumes/V/IRs/FenderTwin"] = { dirs: [], files: [
        "1971 Fender Twin - C414 - Cap.wav",
        "1971 Fender Twin - i5 - Cone.wav",
    ]};
    loader.set_ir_root("V:/IRs");

    // Turn trim off — menu should refresh in place keeping current selection
    outletCalls = [];
    loader.set_trim_prefix_ir(0);
    var irCalls = outletCalls.filter(function(c) { return c[0] === 3; });
    var appends = irCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    assertEq(appends, ["1971 Fender Twin - C414 - Cap", "1971 Fender Twin - i5 - Cone"], "trim off shows full name");

    // Relpath still uses original filename
    outletCalls = [];
    loader.select_ir(1);
    var loadCalls = outletCalls.filter(function(c) { return c[0] === 5; });
    assertEq(loadCalls[0], [5, "read", "/Volumes/V/IRs/FenderTwin/1971 Fender Twin - i5 - Cone.wav"], "relpath uses original filename");
})();

// 10. Loose .nam files at root get a synthetic "root" category
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: ["loose.nam", "readme.txt"] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam"] };
    loader.set_nam_root("V:/Models");
    loader.set_trim_prefix_nam(1);  // reset trim state for clean test

    var catCalls = outletCalls.filter(function(c) { return c[0] === 0; });
    var appends = catCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    assertEq(appends, ["root", "Clean"], "(root) category prepended for loose files");
})();

// 11. "root" category loads loose files; relpath uses (root) prefix
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: ["Acoustic Sim.nam", "Dumble.nam"] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam"] };
    loader.set_nam_root("V:/Models");

    // Select "root" category (index 0)
    outletCalls = [];
    messnamedCalls = [];
    loader.select_nam_category(0);
    loader.select_nam_model(0);

    var loadCalls = outletCalls.filter(function(c) { return c[0] === 4; });
    assertEq(loadCalls[0], [4, "load", "/Volumes/V/Models/Acoustic Sim.nam"], "(root) file loaded from root path");

    var relpathMsg = messnamedCalls.filter(function(c) { return c[0] === "nam_state_set_nam_relpath"; });
    assertEq(relpathMsg[0], ["nam_state_set_nam_relpath", "root/Acoustic Sim.nam"], "root relpath stored");
})();

// 12. No loose files → no "root" entry
(function() {
    reset();
    FILES["/Volumes/V/Models"] = { dirs: ["Clean"], files: ["readme.txt"] };
    FILES["/Volumes/V/Models/Clean"] = { dirs: [], files: ["fender.nam"] };
    loader.set_nam_root("V:/Models");

    var catCalls = outletCalls.filter(function(c) { return c[0] === 0; });
    var appends = catCalls.filter(function(c) { return c[1] === "append"; }).map(function(c) { return c[2]; });
    assertEq(appends, ["Clean"], "no (root) when no loose files");
})();

// ─── done ────────────────────────────────────────────────────────────

console.log("\n" + passes + " passed, " + failures + " failed");
process.exit(failures ? 1 : 0);
