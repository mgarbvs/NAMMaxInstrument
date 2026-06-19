// nam_state.js — Node-for-Max (node.script). Owns state.json persistence
// for NAM and IR root folder paths plus last-selection relpaths.
//
// Outlets:
//   0 — rehydrate <json>     (emitted on startup if state.json exists)
//   1 — status <message>
//
// Handlers (received via direct patch wire using prepend — messnamed is
// unavailable in the M4L runtime):
//   set_nam_root      <abspath>
//   set_ir_root       <abspath>
//   set_nam_relpath   <relpath>
//   set_ir_relpath    <relpath>
//   get_all                            -> outlet 0 rehydrate <json>

const maxApi = require("max-api");
const fs     = require("fs");
const path   = require("path");

const STATE_FILE = path.join(__dirname, "state.json");

let state = {
    nam_root: "",
    ir_root: "",
    nam_relpath: "",
    ir_relpath: "",
};


function load() {
    try {
        if (fs.existsSync(STATE_FILE)) {
            const raw = fs.readFileSync(STATE_FILE, "utf-8");
            const parsed = JSON.parse(raw);
            if (parsed && typeof parsed === "object") {
                state.nam_root = parsed.nam_root || "";
                state.ir_root = parsed.ir_root || "";
                state.nam_relpath = parsed.nam_relpath || "";
                state.ir_relpath = parsed.ir_relpath || "";
            }
        }
    } catch (e) {
        maxApi.post("nam_state: load error: " + e.message);
    }
}

function save() {
    const tmp = STATE_FILE + ".tmp";
    try {
        fs.writeFileSync(tmp, JSON.stringify(state, null, 2), "utf-8");
        fs.renameSync(tmp, STATE_FILE);
    } catch (e) {
        maxApi.post("nam_state: save error: " + e.message);
    }
}

// Emit JSON only — the patch's `prepend rehydrate` adds the selector.
// Sending ("rehydrate", json) here would double-prepend and break parsing.
// Node-for-Max's maxApi.outlet takes message atoms only (no outlet index);
// passing 0 as the first arg leaks it as a literal `0` atom prefixed to the
// JSON, which then fails JSON.parse in the loader's rehydrate handler.
function emitRehydrate() {
    maxApi.outlet(JSON.stringify(state));
}

maxApi.addHandler("set_nam_root", (...args) => {
    state.nam_root = args.join(" ");
    save();
});

maxApi.addHandler("set_ir_root", (...args) => {
    state.ir_root = args.join(" ");
    save();
});

maxApi.addHandler("set_nam_relpath", (...args) => {
    state.nam_relpath = args.join(" ");
    save();
});

maxApi.addHandler("set_ir_relpath", (...args) => {
    state.ir_relpath = args.join(" ");
    save();
});

maxApi.addHandler("get_all", () => {
    maxApi.outlet(JSON.stringify(state));
});

load();
maxApi.post("nam_state.js loaded");
