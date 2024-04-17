const std = @import("std");
const root = @import("root");
const bufPrintZ = std.fmt.bufPrintZ;

pub const OBS = @cImport({
    @cInclude("obs/util/base.h");
    @cInclude("obs/obs-module.h");
    @cInclude("obs/obs-config.h");
    @cInclude("obs/obs-data.h");
    @cInclude("obs/obs-properties.h");
    @cInclude("obs/obs-service.h");
});

pub const Scene = @import("obs/frontend.zig").OBSScene;
pub const QtShim = @import("obs/frontend.zig").QtShim;

/// Define a module_defaults in you root project file
const module_defaults: ModuleDefaults = if (@hasDecl(root, "module_defaults")) root.module_defaults else .{};

pub const ModuleDefaults = struct {
    /// Name of the OBS plugin
    name: [:0]const u8 = "Unnamed Module",
    /// Current version of this plugin
    version: [:0]const u8 = "0.0.0",
    /// Author of the this plugin
    author: [:0]const u8 = "Anonymous Authors",
    /// Description for this plugin
    description: [:0]const u8 = "Default Description for an unnamed module.",

    /// Optional function that will be called when the plugin is loaded by OBS
    /// this function does not require callconv(.C) but other call backs
    /// provided may require it.
    on_load_fn: *const fn () bool = empty_on_load,
    /// Optional function that will be called when the plugin is unloaded by OBS
    /// usually at program exit, but there are other events that could unload a
    /// plugin.
    on_unload_fn: *const fn () void = empty_on_unload,
};

/// call exportOBS in comptime to ensure Zig is able to see the required
/// funtions obs needs to export.
pub inline fn exportOBS() void {
    inline for (comptime std.meta.declarations(@This())) |decl| {
        _ = &@field(@This(), decl.name);
    }
}

var obs_module_pointer: ?*OBS.obs_module_t = null;

export fn obs_module_set_pointer(module: ?*OBS.obs_module_t) void {
    obs_module_pointer = module;
}

export fn obs_current_module() ?*OBS.obs_module_t {
    return obs_module_pointer;
}

export fn obs_module_name() [*:0]const u8 {
    return module_defaults.name;
}

export fn obs_module_ver() u32 {
    return OBS.LIBOBS_API_VER;
}

export fn obs_module_author() [*:0]const u8 {
    return module_defaults.author;
}

export fn obs_module_description() [*:0]const u8 {
    return module_defaults.description;
}

export fn obs_module_load() bool {
    if (module_defaults.on_load_fn()) {
        logFmt(
            "{s} plugin loaded successfully (version: {s})",
            .{ module_defaults.name, module_defaults.version },
        );
        return true;
    }

    logFmt(
        "{s} plugin failed to load (version: {s})",
        .{ module_defaults.name, module_defaults.version },
    );
    return false;
}

export fn obs_module_unload() void {
    logFmt("{s} plugin shutdown", .{module_defaults.name});
    return module_defaults.on_unload_fn();
}

fn empty_on_load() bool {
    return true;
}

fn empty_on_unload() void {}

pub fn logFmt(comptime text: []const u8, vars: anytype) void {
    var buf: [0xffff:0]u8 = undefined;
    const txt = bufPrintZ(&buf, text, vars) catch unreachable;
    log(txt);
}

pub fn log(text: [*:0]const u8) void {
    OBS.blog(OBS.LOG_INFO, text);
}
