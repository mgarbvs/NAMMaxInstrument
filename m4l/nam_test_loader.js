// nam_test_loader.js — Minimal test device loader.
// Category + model picker only. Root hardcoded to ~/Documents/NAM/Models.
// Tests whether live.banks per-category swapping updates Push 3 mid-session.
//
// Outlets:
//   0 — category umenu  (clear / append <name> / set <idx>)
//   1 — model umenu     (clear / append <name> / set <idx>)
//   2 — status message  (set <text>)

inlets  = 1;
outlets = 3;
autowatch = 1;

var OUT_CAT    = 0;
var OUT_MODEL  = 1;
var OUT_STATUS = 2;

var NAM_ROOT = "/Users/michael/Documents/NAM/Models";

var _patcher      = null;
var _banks_ready  = false;
var categories    = [];   // [{name, abspath}]
var models        = [];   // [{name, abspath}]
var sel_cat       = -1;
var sel_model     = -1;

// ─── Filesystem helpers ───────────────────────────────────────────────────────

function _joinPath(a, b) {
    return a.replace(/\/$/, "") + "/" + b;
}

function _listSubdirs(absPath) {
    var out = [];
    if (typeof Folder !== "function") return out;
    var f = new Folder(absPath);
    f.typelist = ["fold"];
    while (!f.end) {
        var name = f.filename;
        if (name && name.charAt(0) !== ".") {
            out.push({name: name, abspath: _joinPath(absPath, name)});
        }
        f.next();
    }
    f.close();
    out.sort(function(a, b) { return a.name < b.name ? -1 : a.name > b.name ? 1 : 0; });
    return out;
}

function _listNamFiles(absPath) {
    var out = [];
    if (typeof Folder !== "function") return out;
    var f = new Folder(absPath);
    while (!f.end) {
        var name = f.filename;
        if (name && name.charAt(0) !== "." && name.toLowerCase().slice(-4) === ".nam") {
            // Display name: strip .nam extension
            out.push({name: name.slice(0, -4), abspath: _joinPath(absPath, name)});
        }
        f.next();
    }
    f.close();
    out.sort(function(a, b) { return a.name < b.name ? -1 : a.name > b.name ? 1 : 0; });
    return out;
}

function _fillMenu(outIdx, items, selectIdx) {
    outlet(outIdx, "clear");
    for (var i = 0; i < items.length; i++) {
        outlet(outIdx, "append", items[i].name);
    }
    if (items.length > 0) {
        outlet(outIdx, "set", selectIdx >= 0 && selectIdx < items.length ? selectIdx : 0);
    }
}

// ─── live.banks helpers ───────────────────────────────────────────────────────

function _sendBanksEdit(bankId, slotIdx, paramName) {
    if (!_patcher) _patcher = this.patcher;
    var b = _patcher && _patcher.getnamed("live_banks");
    if (!b) { post("live_banks not found\n"); return; }
    b.message("edit", bankId, "-", slotIdx, paramName);
    post("banks edit " + bankId + " slot " + slotIdx + " → " + paramName + "\n");
}

function _setPushMenuValue(varname, idx) {
    if (!_patcher) _patcher = this.patcher;
    var b = _patcher && _patcher.getnamed(varname);
    if (b) b.message("set", idx);
}

// _initBanks creates bank 0 "NAM" (cat + active model) and bank 1 "Models"
// (all per-category menus) so no parameter_enable=1 param is orphaned and
// Push shows exactly those 2 banks with no main bank.
// _createBankStructure: called at loadbang.
// live.banks accepts 'new' at loadbang but params aren't registered yet, so slots
// are empty. However, bank_count > 0 forces Push into MaxDeviceParameterBank mode
// (not DeviceParameterBank / all-columns). _populateBanks() fills real params later.
function _createBankStructure() {
    if (!_patcher) _patcher = this.patcher;
    var b = _patcher && _patcher.getnamed("live_banks");
    if (!b) return;
    // Create bank 0 with 2 slots (cat + model), bank 1 with 14 model slots.
    // Param names won't resolve yet — slots remain empty until _populateBanks().
    b.message("new", 0, "NAM", "NAM Cat", "NAM Model 0");
    b.message("new", 1, "Models",
        "NAM Model 0",  "NAM Model 1",  "NAM Model 2",  "NAM Model 3",
        "NAM Model 4",  "NAM Model 5",  "NAM Model 6",  "NAM Model 7",
        "NAM Model 8",  "NAM Model 9",  "NAM Model 10", "NAM Model 11",
        "NAM Model 12", "NAM Model 13");
    post("live_banks structure created (params pending)\n");
}

// _populateBanks: called from init() after live.thisdevice (params now registered).
// Uses 'edit' to fill all slots — fires bank_parameters_changed so Push updates.
function _populateBanks() {
    if (_banks_ready) return;
    if (!_patcher) _patcher = this.patcher;
    var b = _patcher && _patcher.getnamed("live_banks");
    if (!b) { post("live_banks NOT FOUND\n"); return; }

    var cn = (sel_cat >= 0) ? sel_cat : 0;
    // Single edit call: sets name + both slots atomically (one bank_parameters_changed).
    b.message("edit", 0, "NAM", 0, "NAM Cat", 1, "NAM Model " + cn);

    var modelCount = 0;
    while (modelCount < 50 && _patcher.getnamed("Model" + modelCount)) modelCount++;
    for (var mi = 0; mi < modelCount; mi++) {
        b.message("edit", 1, "-", mi, "NAM Model " + mi);
    }

    _banks_ready = true;
    post("live_banks populated: " + modelCount + " models\n");
}

// Called from patch via "init" message 10ms after live.thisdevice.
// Params are now registered — use edit to fill the structure created at loadbang.
function init() {
    _populateBanks();
}

// Click "diag_params" in the device UI to see what Live params are registered.
// Pass: count = 2 (NamCat + active Model). Fail if count > 2 (orphaned params visible).
function diag_params() {
    try {
        var dev = new LiveAPI("this_device");
        var n = dev.getcount("parameters");
        post("=== diag_params: " + n + " params ===\n");
        for (var i = 0; i < n; i++) {
            var p = new LiveAPI("this_device parameters " + i);
            post("  [" + i + "] " + p.get("name") + "\n");
        }
    } catch(e) { post("diag error: " + e + "\n"); }
}

// ─── Category and model loading ───────────────────────────────────────────────

function _loadCategory(idx) {
    if (isNaN(idx) || idx < 0 || idx >= categories.length) return;
    sel_cat = idx;
    _setPushMenuValue("nam_cat_idx", idx);
    if (_banks_ready) _sendBanksEdit(0, 1, "NAM Model " + idx);

    var cat = categories[idx];
    models = _listNamFiles(cat.abspath);
    _fillMenu(OUT_MODEL, models, 0);
    _setPushMenuValue("Model" + idx, 0);
    sel_model = 0;

    var info = cat.name + " — " + models.length + " model" + (models.length !== 1 ? "s" : "");
    outlet(OUT_STATUS, "set", info);
    post("category: " + cat.name + " (" + models.length + " models)\n");
}

// ─── Message handlers ─────────────────────────────────────────────────────────

function loadbang() {
    _patcher = this.patcher;
    // Create empty bank structure now — params aren't registered yet so slots
    // are empty, but bank_count > 0 forces Push into MaxDeviceParameterBank mode.
    // init() (10ms after live.thisdevice) uses edit to fill real params.
    _createBankStructure();
    categories = _listSubdirs(NAM_ROOT);
    if (categories.length === 0) {
        outlet(OUT_STATUS, "set", "No folders found in " + NAM_ROOT);
        post("No categories found in " + NAM_ROOT + "\n");
        return;
    }
    _fillMenu(OUT_CAT, categories, 0);
    _loadCategory(0);
}

// From category umenu (computer UI)
function select_category(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= categories.length) return;
    outlet(OUT_CAT, "set", idx);
    _loadCategory(idx);
}

// From model umenu (computer UI)
function select_model(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || idx < 0 || idx >= models.length) return;
    sel_model = idx;
    _setPushMenuValue("Model" + sel_cat, idx);
    outlet(OUT_STATUS, "set", models[idx].name);
}

// From Push NamCat encoder
function select_cat_by_push(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || categories.length === 0) return;
    if (idx < 0) idx = 0;
    if (idx >= categories.length) idx = categories.length - 1;
    outlet(OUT_CAT, "set", idx);
    _loadCategory(idx);
}

// From Push Model encoder (whichever Model{i} is currently in bank slot 1)
function select_model_by_push(idx) {
    idx = parseInt(idx, 10);
    if (isNaN(idx) || models.length === 0) return;
    if (idx < 0) idx = 0;
    if (idx >= models.length) idx = models.length - 1;
    outlet(OUT_MODEL, "set", idx);
    select_model(idx);
}
