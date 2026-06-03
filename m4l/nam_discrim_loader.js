
inlets=1; outlets=1; autowatch=1;
var _p=null;
function init() {
    _p = this.patcher;
    var b = _p && _p.getnamed("live_banks");
    if (!b) { post("live_banks NOT FOUND\n"); return; }
    post("Sending: new 0 TEST Dvis Dhid\n");
    b.message("new", 0, "TEST", "Dvis", "Dhid");
    post("Done - check above for any 'not found' errors\n");
}
