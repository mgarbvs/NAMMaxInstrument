"use strict";
// push_name_patch.js — Pure Node.js module. Scans NAM/IR library roots and
// rewrites NAM.amxd's parameter_enum for the four Push 3 shadow live.menus.
// Imported by nam_state.js (handler) and tests/test_push_name_patch.js.

const fs   = require("fs");
const path = require("path");

const AMXD_HEADER_SIZE = 32;  // ampf(4)+len(4)+aaaameta(8)+len(4)+val(4)+ptch(4)+jsonlen(4)
const IR_EXTS = [".wav", ".aif", ".aiff"];

// Convert Max path "VolumeName:/path" → POSIX "/Volumes/VolumeName/path".
// Passes through paths already in POSIX form (no "VolName:/" pattern).
function toPosixPath(p) {
    if (!p) return "";
    const ci = p.indexOf(":");
    if (ci > 0 && p[ci + 1] === "/") {
        return "/Volumes/" + p.slice(0, ci) + p.slice(ci + 1).replace(/\/$/, "");
    }
    return p.replace(/\/$/, "");
}

function listSubdirs(absPath) {
    try {
        return fs.readdirSync(absPath)
            .filter(n => !n.startsWith(".") && fs.statSync(path.join(absPath, n)).isDirectory())
            .sort();
    } catch (_) { return []; }
}

function listNamFiles(absPath) {
    try {
        return fs.readdirSync(absPath)
            .filter(n => !n.startsWith(".") && n.toLowerCase().endsWith(".nam"))
            .sort();
    } catch (_) { return []; }
}

function listIrFiles(absPath) {
    try {
        return fs.readdirSync(absPath)
            .filter(n => !n.startsWith(".") && IR_EXTS.some(e => n.toLowerCase().endsWith(e)))
            .sort();
    } catch (_) { return []; }
}

// Mirrors _commonPrefix / _trimToWordBound / _makeDisplayFiles in nam_loader.js.
// MUST stay in sync — Push names are built from these, screen names from the JS.
function commonPrefix(strs) {
    if (!strs.length) return "";
    let p = strs[0];
    for (let i = 1; i < strs.length; i++) {
        let j = 0;
        while (j < p.length && j < strs[i].length && p[j] === strs[i][j]) j++;
        p = p.slice(0, j);
        if (!p) return "";
    }
    return p;
}

function trimToWordBound(s) {
    let i = s.length;
    while (i > 0 && s[i - 1] !== " ") i--;
    return s.slice(0, i);
}

// filenames: plain string array (e.g. from readdirSync).
// stripExtRe: regex to remove extension before comparing.
// Always trims common prefix (mirrors trim_prefix_nam/ir default=1 in UI).
function makeDisplayNames(filenames, stripExtRe) {
    const noext  = filenames.map(n => n.replace(stripExtRe, ""));
    const prefix = filenames.length > 1 ? trimToWordBound(commonPrefix(noext)) : "";
    return noext.map(n => {
        const d = prefix.length ? n.slice(prefix.length).replace(/^[\s\-_]+/, "") : n;
        return d || n;
    });
}

// Build the enum map for all four Push shadow live.menus.
// Only includes keys for which scanning succeeds with >= 1 item, so callers
// that pass the map to patchAmxdEnums never clobber a working enum with blanks.
function buildEnumMap(namRoot, irRoot) {
    const map = {};

    const namPosix = toPosixPath(namRoot);
    if (namPosix && fs.existsSync(namPosix)) {
        const cats = listSubdirs(namPosix);
        if (cats.length > 0) {
            map["nam_cat_idx"] = cats;
            const files = listNamFiles(path.join(namPosix, cats[0]));
            if (files.length > 0) {
                map["nam_model_idx"] = makeDisplayNames(files, /\.nam$/i);
            }
        }
    }

    const irPosix = toPosixPath(irRoot);
    if (irPosix && fs.existsSync(irPosix)) {
        const cats = listSubdirs(irPosix);
        if (cats.length > 0) {
            map["ir_cat_idx"] = cats;
            const files = listIrFiles(path.join(irPosix, cats[0]));
            if (files.length > 0) {
                map["ir_file_idx"] = makeDisplayNames(files, /\.(wav|aif|aiff)$/i);
            }
        }
    }

    return map;
}

// Rewrite parameter_enum for boxes whose varname is in enumMap.
// Absent keys are left untouched — scan failures never wipe working enums.
// Writes atomically via .tmp rename.
function patchAmxdEnums(amxdPath, enumMap) {
    const data    = fs.readFileSync(amxdPath);
    const header  = Buffer.from(data.slice(0, AMXD_HEADER_SIZE));  // copy, will mutate length field
    const patcher = JSON.parse(data.slice(AMXD_HEADER_SIZE).toString("utf-8"));

    for (const b of patcher.patcher.boxes) {
        const varname = b.box && b.box.varname;
        if (!varname || !Object.prototype.hasOwnProperty.call(enumMap, varname)) continue;
        const saa = b.box.saved_attribute_attributes;
        if (saa && saa.valueof) {
            saa.valueof.parameter_enum = enumMap[varname];
        }
    }

    const newJson = Buffer.from(JSON.stringify(patcher), "utf-8");
    header.writeUInt32LE(newJson.length, 28);  // only the JSON-length field changes

    const tmp = amxdPath + ".tmp";
    fs.writeFileSync(tmp, Buffer.concat([header, newJson]));
    fs.renameSync(tmp, amxdPath);
}

module.exports = {
    toPosixPath,
    buildEnumMap,
    patchAmxdEnums,
    _helpers: { commonPrefix, trimToWordBound, makeDisplayNames,
                listSubdirs, listNamFiles, listIrFiles },
};
