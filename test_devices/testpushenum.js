// testpushenum.js — Push 3 enum display test: parameter_visibility theories
inlets = 1;
outlets = 1;
autowatch = 1;

var _p = null;
var TARGET = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"];

function loadbang() {
    _p = this.patcher;
    post("testpushenum.js ready — on Push 3 you should see params: F_Vis, G_VNS, H_PE0\n");
}

function _sendRange(varname, label) {
    if (!_p) _p = this.patcher;
    var b = _p.getnamed(varname);
    if (!b) { post(label + ": box '" + varname + "' not found\n"); return; }
    Function.prototype.apply.call(b.message, b, ["_parameter_range"].concat(TARGET));
    post(label + ": _parameter_range sent — does Push show Alpha/Beta/Gamma?\n");
}

// Theory F: parameter_enable=1, parameter_visibility="Visible"
// Hypothesis: "Visible" is a different code path in Live 12.4 that may not cache enum at load.
function test_f() { _sendRange("testmenu_f", "F(Visible)"); }

// Theory G: parameter_enable=1, parameter_visibility="Visible (Not Stored)"
// Hypothesis: "not stored" may mean Push reads lazily rather than caching at load.
function test_g() { _sendRange("testmenu_g", "G(Visible-NS)"); }

// Theory H: parameter_enable=0, parameter_visibility="Visible"
// Hypothesis: Live 12.4 allows Push-only params without parameter_enable; different init path.
// Note: if H param doesn't even appear on Push, "box not found" may appear.
function test_h() { _sendRange("testmenu_h", "H(PE0+Vis)"); }

// Send _parameter_range to all three at once
function test_all() {
    test_f();
    test_g();
    test_h();
}
