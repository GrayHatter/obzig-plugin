pub const OBS_C = @cImport({
    //@cInclude("obs/obs.h");
    //@cInclude("obs/util/base.h");
    //@cInclude("obs/obs-module.h");
    //@cInclude("obs/obs-config.h");
    //@cInclude("obs/obs-data.h");
    //@cInclude("obs/obs-properties.h");
    //@cInclude("obs/obs-service.h");
});
//pub const OBS = @import("OBS_C");

pub const OBS = OBS_Z;

pub const OBS_Z = struct {
    pub const darray = extern struct {
        array: *anyopaque,
        num: usize,
        capacity: usize,
    };

    pub const obs_object_t = anyopaque;
    pub const obs_display_t = anyopaque;
    pub const obs_view_t = anyopaque;
    pub const obs_source_t = anyopaque;
    pub const obs_scene_t = anyopaque;
    pub const obs_sceneitem_t = anyopaque;
    pub const obs_output_t = anyopaque;
    pub const obs_encoder_t = anyopaque;
    pub const obs_encoder_group_t = anyopaque;
    pub const obs_service_t = anyopaque;
    pub const obs_module_t = anyopaque;
    pub const obs_fader_t = anyopaque;
    pub const obs_volmeter_t = anyopaque;
    pub const obs_canvas_t = anyopaque;

    pub const LIBOBS_API_VER: u32 = 0;

    pub const LOG_LEVEL = enum(c_int) {
        /// Use if there's a problem that can potentially affect the program,
        /// but isn't enough to require termination of the program.
        ///
        /// Use in creation functions and core subsystem functions.  Places that
        /// should definitely not fail.
        LOG_ERROR = 100,

        /// Use if a problem occurs that doesn't affect the program and is
        /// recoverable.
        ///
        /// Use in places where failure isn't entirely unexpected, and can
        /// be handled safely.
        LOG_WARNING = 200,

        /// Informative message to be displayed in the log.
        LOG_INFO = 300,

        /// Debug message to be used mostly by developers.
        LOG_DEBUG = 400,
    };

    pub fn blog(level: LOG_LEVEL, text: [*:0]const u8) void {
        _ = level;
        _ = text;
    }
};

pub const Scene = @import("obs/frontend.zig").OBSScene;
pub const QtShim = @import("obs/frontend.zig").QtShim;

/// Define a module_defaults in you root project file
const module_defaults: ModuleInfo = if (@hasDecl(root, "module_defaults")) root.module_defaults else .{};

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

pub fn logFmt(comptime text: []const u8, vars: anytype) void {
    var buf: [0xffff:0]u8 = undefined;
    const txt = bufPrintZ(&buf, text, vars) catch unreachable;
    log(txt);
}

pub fn log(text: [*:0]const u8) void {
    OBS.blog(.LOG_INFO, text);
}

const std = @import("std");
const root = @import("root");
const ModuleInfo = @import("module-info.zig");
const bufPrintZ = std.fmt.bufPrintZ;
