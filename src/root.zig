const std = @import("std");
const Allocator = std.mem.Allocator;

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

fn logFmt(comptime text: []const u8, vars: anytype) void {
    var buf: [0xffff:0]u8 = undefined;

    const txt = std.fmt.bufPrintZ(&buf, text, vars) catch unreachable;
    log(txt);
}

fn log(text: [*:0]const u8) void {
    obs.blog(obs.LOG_INFO, text);
}

var arena: std.heap.ArenaAllocator = undefined;
var alloc: Allocator = undefined;

fn thread(_: ?*anyopaque) void {
    obs.blog(obs.LOG_INFO, "sway thread running");
    var sway = sway_ipc.Connection.init(alloc) catch |err| {
        logFmt("connection error {}", .{err});
        return;
    };
    sway.subscribe() catch {
        log("crash trying to subscribe");
        unreachable;
    };
    std.time.sleep(10_000_000_000);
    for (0..10) |_| {
        const msg = sway.loop() catch {
            log("unexpected read error");
            unreachable;
        };

        if (gui.currentScene()) |name| {
            logFmt("name {s}\n", .{name});
        }
        std.time.sleep(10_000_000);
        switch (msg.toStruct(alloc) catch {
            log("unable to build struct");
            continue;
        }) {
            .window => |w| logFmt("marks {s}", .{w.container.marks}),
        }
    }
    for (gui.getSceneNames()) |name| {
        logFmt("scene name: {s}", .{std.mem.span(name.?)});
    }
}

var threads: [1]std.Thread = undefined;

export fn obs_module_load() bool {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    alloc = arena.allocator();
    threads[0] = std.Thread.spawn(.{}, thread, .{null}) catch unreachable;

    enumScene();
    logFmt("sway-focus plugin loaded successfully {s}", .{PLUGIN_VERSION});
    return true;
}

export fn obs_module_unload() void {
    std.Thread.join(threads[0]);
    arena.deinit();
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
// get windows
// trigger scene on event
// stall on remove for min seconds

test "basic add functionality" {}
