const std = @import("std");

pub const obs = @cImport({
    @cInclude("obs/util/base.h");
    @cInclude("obs/obs-module.h");
    @cInclude("obs/obs-config.h");
    @cInclude("obs/obs-data.h");
    @cInclude("obs/obs-properties.h");
    @cInclude("obs/obs-service.h");
});

const PLUGIN_VERSION = "0.0.0";
var obs_module_pointer: ?*obs.obs_module_t = null;
export fn obs_module_set_pointer(module: ?*obs.obs_module_t) void {
    obs_module_pointer = module;
}

export fn obs_current_module() ?*obs.obs_module_t {
    return obs_module_pointer;
}

export fn obs_module_ver() u32 {
    return obs.LIBOBS_API_VER;
}

export fn obs_module_author() [*:0]const u8 {
    return "grayhatter";
}

export fn obs_module_name() [*:0]const u8 {
    return "obs-sway-focus";
}

export fn obs_module_description() [*:0]const u8 {
    return "it does stuff";
}
// TODO
// thread
// socket
// send message
// get messages
// get windows
// poll socket
// trigger scene on event
// stall on remove for min seconds

test "basic add functionality" {}
