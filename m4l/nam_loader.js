// nam_loader.js — Max-JS file (js object). Folder enumeration and dropdown
// plumbing for NAM model files and cabinet IRs.
//
// Outlets:
//   0 — NAM category umenu      (clear / append <name> / set <idx>)
//   1 — NAM model umenu         (clear / append <name> / set <idx>)
//   2 — IR category umenu       (clear / append <name> / set <idx>)
//   3 — IR umenu                (clear / append <name> / set <idx>)
//   4 — nam~ load message       (load <abspath>)
//   5 — buffer~ ir_buf message  (read <abspath>)
//   6 — status text             (set <message>)
//
// The Max JS runtime is ES5-ish — avoid arrow functions and `const`/`let`
// in the file-level scope. Functions named with no underscore prefix are
// exposed as message handlers (Max convention).

inlets = 1;
outlets = 8;
autowatch = 1;

var OUT_NAM_CAT  = 0;
var OUT_NAM_MODEL = 1;
var OUT_IR_CAT   = 2;
var OUT_IR       = 3;
var OUT_NAM_LOAD = 4;
var OUT_IR_LOAD  = 5;
var OUT_STATUS   = 6;
var OUT_IR_NORM  = 7;  // 0.12589 when IR loaded, 0.0 when not

var nam_root = "";
var ir_root = "";
var nam_categories = [];      // [ { name, abspath } ]
var nam_models = [];          // [ { name, abspath, origname, relpath } ]
var ir_categories = [];
var ir_files = [];            // [ { name, abspath, origname, relpath } ]
var selected_nam_cat = -1;
var selected_nam_model = -1;
var selected_ir_cat = -1;
var selected_ir_file = -1; // track for SR-change re-read
var trim_prefix_nam = 1;
var trim_prefix_ir  = 1;
var _patcher = null;

function loadbang() {
    _patcher = this.patcher;
    outlet(OUT_IR_NORM, 1.0);  // pass-through until an IR file is loaded
}

function _coverNamDrop() {
    if (!_patcher) _patcher = this.patcher;
    var drop = _patcher && _patcher.getnamed("nam_live_drop");
    if (drop) { drop.message("legend", ""); drop.message("bordercolor", 0, 0, 0, 0); }
}
function _coverIrDrop() {
    if (!_patcher) _patcher = this.patcher;
    var drop = _patcher && _patcher.getnamed("ir_live_drop");
    if (drop) { drop.message("legend", ""); drop.message("bordercolor", 0, 0, 0, 0); }
}

// ─── Path conversion ──────────────────────────────────────────────────

// macOS opendialog returns "VolumeName:/path" — convert to /Volumes/VolumeName/path.
// Windows: "C:/path" or "C:\path" — normalize slashes only.
function maxPathToPosix(p) {
    if (!p) return p;
    if (typeof p !== "string") p = String(p);
    if (typeof _PLATFORM !== "undefined" && _PLATFORM === "win32") {
        return p.replace(/\\/g, "/").replace(/\/$/, "");
    }
    var colonIdx = p.indexOf(":");
    if (colonIdx !== -1 && p.charAt(colonIdx + 1) === "/") {
        var volumeName = p.slice(0, colonIdx);
        var rest = p.slice(colonIdx + 1).replace(/\/$/, "");
        return "/Volumes/" + volumeName + rest;
    }
    return p.replace(/\/$/, "");
}

// ─── Folder enumeration helpers ──────────────────────────────────────

// Build the category list for a root path.  If any loose files with the
// given extension sit directly in the root, a synthetic "root" entry is
// prepended so they are reachable without reorganising the library.
function _buildCategories(rootPath, ext) {
    var cats = listSubdirs(rootPath);
    if (listFilesByExt(rootPath, ext).length > 0) {
        cats = [{ name: "root", abspath: rootPath }].concat(cats);
    }
    return cats;
}

function listSubdirs(absPath) {
    var out = [];
    if (typeof Folder !== "function") return out;
    var f = new Folder(absPath);
    f.typelist = ["fold"];
    while (!f.end) {
        var name = f.filename;
        if (name && name.charAt(0) !== ".") {
            out.push({ name: name, abspath: joinPath(absPath, name) });
        }
        f.next();
    }
    f.close();
    out.sort(byName);
    return out;
}

function listFilesByExt(absPath, ext) {
    var out = [];
    if (typeof Folder !== "function") return out;
    var f = new Folder(absPath);
    while (!f.end) {
        var name = f.filename;
        if (name && name.charAt(0) !== "." && endsWith(name.toLowerCase(), ext)) {
            out.push({ name: name, abspath: joinPath(absPath, name) });
        }
        f.next();
    }
    f.close();
    out.sort(byName);
    return out;
}

function joinPath(a, b) {
    if (!a) return b;
    if (a.charAt(a.length - 1) === "/") return a + b;
    return a + "/" + b;
}

function endsWith(s, suffix) {
    return s.length >= suffix.length && s.slice(s.length - suffix.length) === suffix;
}

function byName(a, b) {
    if (a.name < b.name) return -1;
    if (a.name > b.name) return 1;
    return 0;
}

// ─── Display-name helpers ─────────────────────────────────────────────
// Strip extension and trim shared prefix so "IR Collection - C414 - Cap.wav"
// becomes "C414 - Cap" when all files in a folder share "IR Collection - ".

function _commonPrefix(strs) {
    if (strs.length === 0) return "";
    var p = strs[0];
    for (var i = 1; i < strs.length; i++) {
        var j = 0;
        while (j < p.length && j < strs[i].length && p[j] === strs[i][j]) j++;
        p = p.slice(0, j);
        if (!p) return "";
    }
    return p;
}

function _trimToWordBound(s) {
    var i = s.length;
    while (i > 0 && s[i - 1] !== " ") i--;
    return s.slice(0, i);
}

// rawFiles: [{ name, abspath }] from listFilesByExt
// Returns  [{ name (display), abspath, origname (raw filename) }]
function _makeDisplayFiles(rawFiles, stripExtRe, trimFlag) {
    var noext = [];
    for (var i = 0; i < rawFiles.length; i++) {
        noext.push(rawFiles[i].name.replace(stripExtRe, ""));
    }
    var prefix = (trimFlag && rawFiles.length > 1)
        ? _trimToWordBound(_commonPrefix(noext))
        : "";
    var out = [];
    for (var i = 0; i < rawFiles.length; i++) {
        var display = prefix.length > 0
            ? noext[i].slice(prefix.length).replace(/^[\s\-_]+/, "")
            : noext[i];
        out.push({ name: display || noext[i], abspath: rawFiles[i].abspath, origname: rawFiles[i].name });
    }
    return out;
}

// ─── Umenu population ─────────────────────────────────────────────────

function fillMenu(outIdx, items, selectIdx) {
    outlet(outIdx, "clear");
    for (var i = 0; i < items.length; i++) {
        outlet(outIdx, "append", items[i].name);
    }
    if (items.length > 0) {
        var idx = (selectIdx >= 0 && selectIdx < items.length) ? selectIdx : 0;
        outlet(outIdx, "set", idx);
    }
}

function setStatus(msg) {
    outlet(OUT_STATUS, "set", msg);
}

// ─── Handlers: NAM root + selection ───────────────────────────────────

// _populate_nam_models / _populate_ir_files fill the model/IR arrays and
// menus without triggering a load. select_nam_category / select_ir_category
// call them then auto-load index 0. rehydrate calls them directly so it can
// load the exact saved index without a redundant index-0 load first.

function _populate_nam_models(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= nam_categories.length) return;
    selected_nam_cat = idx;
    var cat = nam_categories[idx];
    var raw = listFilesByExt(cat.abspath, ".nam");
    nam_models = _makeDisplayFiles(raw, /\.nam$/i, trim_prefix_nam);
    for (var i = 0; i < nam_models.length; i++) {
        nam_models[i].relpath = cat.name + "/" + nam_models[i].origname;
    }
    if (nam_models.length === 0) {
        outlet(OUT_NAM_MODEL, "clear");
        setStatus("No .nam files in " + cat.name);
        return;
    }
    fillMenu(OUT_NAM_MODEL, nam_models, 0);
}

function set_nam_root() {
    var raw = arrayfromargs(arguments).join(" ");
    var p = maxPathToPosix(raw);
    if (!p) { setStatus("error: empty NAM root"); return; }
    nam_root = p;
    nam_categories = _buildCategories(p, ".nam");
    if (nam_categories.length === 0) {
        setStatus("No category subfolders in NAM root");
        outlet(OUT_NAM_CAT, "clear");
        outlet(OUT_NAM_MODEL, "clear");
        return;
    }
    fillMenu(OUT_NAM_CAT, nam_categories, 0);
    selected_nam_cat = 0;
    select_nam_category(0);
    messnamed("nam_state_set_nam_root", p);
}

function select_nam_category(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= nam_categories.length) return;
    _populate_nam_models(idx);
    if (nam_models.length > 0) select_nam_model(0);
}

function select_nam_model(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= nam_models.length) return;
    selected_nam_model = idx;
    var m = nam_models[idx];
    outlet(OUT_NAM_LOAD, "load", m.abspath);
    setStatus("Loading model: " + m.name);
    messnamed("nam_state_set_nam_relpath", m.relpath);
    _coverNamDrop();
}

// ─── Handlers: IR root + selection ────────────────────────────────────

function _populate_ir_files(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= ir_categories.length) return;
    selected_ir_cat = idx;
    var cat = ir_categories[idx];
    var raw = listFilesByExt(cat.abspath, ".wav");
    ir_files = _makeDisplayFiles(raw, /\.(aiff?|wav)$/i, trim_prefix_ir);
    for (var i = 0; i < ir_files.length; i++) {
        ir_files[i].relpath = cat.name + "/" + ir_files[i].origname;
    }
    if (ir_files.length === 0) {
        outlet(OUT_IR, "clear");
        setStatus("No .wav files in " + cat.name);
        return;
    }
    fillMenu(OUT_IR, ir_files, 0);
}

function set_ir_root() {
    var raw = arrayfromargs(arguments).join(" ");
    var p = maxPathToPosix(raw);
    if (!p) { setStatus("error: empty IR root"); return; }
    ir_root = p;
    ir_categories = _buildCategories(p, ".wav");
    if (ir_categories.length === 0) {
        setStatus("No category subfolders in IR root");
        outlet(OUT_IR_CAT, "clear");
        outlet(OUT_IR, "clear");
        return;
    }
    fillMenu(OUT_IR_CAT, ir_categories, 0);
    selected_ir_cat = 0;
    select_ir_category(0);
    messnamed("nam_state_set_ir_root", p);
}

function select_ir_category(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= ir_categories.length) return;
    _populate_ir_files(idx);
    if (ir_files.length > 0) select_ir(0);
}

function select_ir(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= ir_files.length) return;
    selected_ir_file = idx;
    var f = ir_files[idx];
    outlet(OUT_IR_LOAD, "read", f.abspath);
    outlet(OUT_IR_NORM, 0.12589);
    setStatus("Loading IR: " + f.name);
    messnamed("nam_state_set_ir_relpath", f.relpath);
    _coverIrDrop();
}

// ─── NAM navigation ───────────────────────────────────────────────────────

function prev_cat() {
    if (nam_categories.length === 0) return;
    var idx = (selected_nam_cat <= 0) ? nam_categories.length - 1 : selected_nam_cat - 1;
    outlet(OUT_NAM_CAT, "set", idx);
    select_nam_category(idx);
}
function next_cat() {
    if (nam_categories.length === 0) return;
    var idx = (selected_nam_cat < 0) ? 0 : (selected_nam_cat + 1) % nam_categories.length;
    outlet(OUT_NAM_CAT, "set", idx);
    select_nam_category(idx);
}
function prev_model() {
    if (nam_models.length === 0) return;
    var idx = (selected_nam_model <= 0) ? nam_models.length - 1 : selected_nam_model - 1;
    outlet(OUT_NAM_MODEL, "set", idx);
    select_nam_model(idx);
}
function next_model() {
    if (nam_models.length === 0) return;
    var idx = (selected_nam_model < 0) ? 0 : (selected_nam_model + 1) % nam_models.length;
    outlet(OUT_NAM_MODEL, "set", idx);
    select_nam_model(idx);
}

// ─── IR navigation ────────────────────────────────────────────────────────
// Uses distinct names (prev_ir_cat etc.) to avoid collision with NAM nav in
// the combined device where both sets route to the same jsloader inlet.

function prev_ir_cat() {
    if (ir_categories.length === 0) return;
    var idx = (selected_ir_cat <= 0) ? ir_categories.length - 1 : selected_ir_cat - 1;
    outlet(OUT_IR_CAT, "set", idx);
    select_ir_category(idx);
}
function next_ir_cat() {
    if (ir_categories.length === 0) return;
    var idx = (selected_ir_cat < 0) ? 0 : (selected_ir_cat + 1) % ir_categories.length;
    outlet(OUT_IR_CAT, "set", idx);
    select_ir_category(idx);
}
function prev_ir() {
    if (ir_files.length === 0) return;
    var idx = (selected_ir_file <= 0) ? ir_files.length - 1 : selected_ir_file - 1;
    outlet(OUT_IR, "set", idx);
    select_ir(idx);
}
function next_ir() {
    if (ir_files.length === 0) return;
    var idx = (selected_ir_file < 0) ? 0 : (selected_ir_file + 1) % ir_files.length;
    outlet(OUT_IR, "set", idx);
    select_ir(idx);
}

// ─── Drag-drop ────────────────────────────────────────────────────────────

function load_dropped_nam() {
    var p = maxPathToPosix(arrayfromargs(arguments).join(" "));
    if (!p || !endsWith(p.toLowerCase(), ".nam")) return;
    outlet(OUT_NAM_LOAD, "load", p);
    var name = p.slice(p.lastIndexOf("/") + 1).replace(/\.nam$/i, "");
    setStatus("Loaded: " + name);
    outlet(OUT_NAM_MODEL, "clear");
    outlet(OUT_NAM_MODEL, "append", name);
    outlet(OUT_NAM_MODEL, "set", 0);
    _coverNamDrop();
}
function load_dropped_ir() {
    var p = maxPathToPosix(arrayfromargs(arguments).join(" "));
    if (!p) return;
    var pl = p.toLowerCase();
    if (!endsWith(pl, ".wav") && !endsWith(pl, ".aif") && !endsWith(pl, ".aiff")) return;
    outlet(OUT_IR_LOAD, "read", p);
    outlet(OUT_IR_NORM, 0.12589);
    setStatus("Loading IR: " + p.slice(p.lastIndexOf("/") + 1));
    _coverIrDrop();
}

function set_trim_prefix_nam(val) {
    trim_prefix_nam = val ? 1 : 0;
    if (selected_nam_cat >= 0 && selected_nam_cat < nam_categories.length) {
        var prevIdx = selected_nam_model;
        _populate_nam_models(selected_nam_cat);
        if (nam_models.length > 0 && prevIdx >= 0 && prevIdx < nam_models.length) {
            outlet(OUT_NAM_MODEL, "set", prevIdx);
            selected_nam_model = prevIdx;
        }
    }
}

function set_trim_prefix_ir(val) {
    trim_prefix_ir = val ? 1 : 0;
    if (selected_ir_cat >= 0 && selected_ir_cat < ir_categories.length) {
        var prevIdx = selected_ir_file;
        _populate_ir_files(selected_ir_cat);
        if (ir_files.length > 0 && prevIdx >= 0 && prevIdx < ir_files.length) {
            outlet(OUT_IR, "set", prevIdx);
            selected_ir_file = prevIdx;
        }
    }
}

// Called when live.thisdevice outlet 1 fires (host sample rate changed).
// ResamplingNAM adapts the model side automatically; we only need to re-read
// ir_buf so buffer~ resamples the WAV to the new host SR, which re-arms
// irconv~ and re-reports PDC via the existing read-complete chain.
function sr_changed() {
    if (selected_ir_file >= 0 && selected_ir_file < ir_files.length) {
        outlet(OUT_IR_LOAD, "read", ir_files[selected_ir_file].abspath);
    }
}

// ─── Rehydration ──────────────────────────────────────────────────────

// Called by nam_state.js on device load with a JSON string of saved state.
function rehydrate() {
    var raw = arrayfromargs(arguments).join(" ");
    if (!raw || !/\S/.test(raw)) return;
    var state;
    try { state = JSON.parse(raw); } catch (e) {
        // Max 8 auto-parses {..} atoms as dict objects; arrayfromargs then
        // returns the dict identifier, not the JSON. Try the raw argument.
        var arg0 = arguments[0];
        if (arg0 && typeof arg0 === "object" && typeof arg0.nam_root !== "undefined") {
            state = arg0;
        } else {
            post("nam_loader: ignoring unparseable state (" + raw.slice(0, 40) + ")\n");
            return;
        }
    }
    if (state.nam_root) {
        nam_root = maxPathToPosix(state.nam_root);
        nam_categories = _buildCategories(nam_root, ".nam");
        if (nam_categories.length > 0) {
            var nrel = state.nam_relpath || "";
            var nresolved = resolveRelpath(nam_categories, nrel, ".nam");
            var nCatIdx = nresolved.catIdx >= 0 ? nresolved.catIdx : 0;
            var nFileIdx = nresolved.fileIdx >= 0 ? nresolved.fileIdx : 0;
            fillMenu(OUT_NAM_CAT, nam_categories, nCatIdx);
            outlet(OUT_NAM_CAT, "set", nCatIdx);
            _populate_nam_models(nCatIdx);
            if (nam_models.length > 0) {
                outlet(OUT_NAM_MODEL, "set", nFileIdx);
                select_nam_model(nFileIdx);
            }
            if (nrel && (nresolved.catIdx < 0 || nresolved.fileIdx < 0)) {
                setStatus("Missing: " + nrel);
            }
        } else {
            fillMenu(OUT_NAM_CAT, nam_categories, 0);
        }
    }
    if (state.ir_root) {
        ir_root = maxPathToPosix(state.ir_root);
        ir_categories = _buildCategories(ir_root, ".wav");
        if (ir_categories.length > 0) {
            var irel = state.ir_relpath || "";
            var iresolved = resolveRelpath(ir_categories, irel, ".wav");
            var iCatIdx = iresolved.catIdx >= 0 ? iresolved.catIdx : 0;
            var iFileIdx = iresolved.fileIdx >= 0 ? iresolved.fileIdx : 0;
            fillMenu(OUT_IR_CAT, ir_categories, iCatIdx);
            outlet(OUT_IR_CAT, "set", iCatIdx);
            _populate_ir_files(iCatIdx);
            if (ir_files.length > 0) {
                outlet(OUT_IR, "set", iFileIdx);
                select_ir(iFileIdx);
            }
            if (irel && (iresolved.catIdx < 0 || iresolved.fileIdx < 0)) {
                setStatus("Missing: " + irel);
            }
        } else {
            fillMenu(OUT_IR_CAT, ir_categories, 0);
        }
    }
}

function resolveRelpath(cats, relpath, ext) {
    var res = { catIdx: -1, fileIdx: -1 };
    if (!relpath) return res;
    var slash = relpath.indexOf("/");
    if (slash <= 0) return res;
    var catName = relpath.slice(0, slash);
    var fileName = relpath.slice(slash + 1);
    for (var i = 0; i < cats.length; i++) {
        if (cats[i].name === catName) {
            res.catIdx = i;
            var files = listFilesByExt(cats[i].abspath, ext);
            for (var j = 0; j < files.length; j++) {
                if (files[j].name === fileName) { res.fileIdx = j; break; }
            }
            break;
        }
    }
    return res;
}

// ─── Node testability ─────────────────────────────────────────────────
// Exporting under typeof guard lets tests `require()` this file and then
// inject Max globals (outlet, Folder, messnamed, arrayfromargs) before
// invoking the handlers. Per KB §12: tests must not duplicate the SUT.
if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        maxPathToPosix: maxPathToPosix,
        set_nam_root: set_nam_root,
        select_nam_category: select_nam_category,
        select_nam_model: select_nam_model,
        set_ir_root: set_ir_root,
        select_ir_category: select_ir_category,
        select_ir: select_ir,
        set_trim_prefix_nam: set_trim_prefix_nam,
        set_trim_prefix_ir: set_trim_prefix_ir,
        rehydrate: rehydrate,
        _internals: {
            getNamModels: function() { return nam_models; },
            getIrFiles: function() { return ir_files; },
            populateNamModels: _populate_nam_models,
            populateIrFiles: _populate_ir_files,
            getTrimPrefixNam: function() { return trim_prefix_nam; },
            getTrimPrefixIr: function() { return trim_prefix_ir; },
        }
    };
}
