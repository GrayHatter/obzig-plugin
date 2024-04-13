const std = @import("std");
const sway_ipc = @import("sway-ipc.zig");
const gui = @import("gui.zig");

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

export fn obs_module_load() bool {
    obs.blog(obs.LOG_INFO, "plugin loaded successfully (version %s)", PLUGIN_VERSION);
    //gui.init();

    enumScene();
    return true;
}

fn enumScene() void {
    obs.obs_enum_scenes(enumSceneCb, null);
}

fn enumSceneCb(_: ?*anyopaque, _: ?*obs.obs_source_t) callconv(.C) bool {
    //const char: [*:0]u8 = scene.?.get_name(data);

    //obs.blog(obs.LOG_INFO, "plugin data (found scene %s)", char);
    return true;
}

fn enumSceneItemCb(_: ?*obs.obs_scene_t, _: ?*obs.obs_sceneitem_t, _: ?*void) callconv(.C) void {}

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
