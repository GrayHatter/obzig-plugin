/// Example root.zig file used to compile the Zig OBS plugin
const std = @import("std");
const Allocator = std.mem.Allocator;
const obs = @import("obs.zig");
//pub usingnamespace obs;
pub const ModuleInfo = @import("module-info.zig");

pub const logFmt = obs.logFmt;
pub const log = obs.log;
pub const Scene = @import("obs/frontend.zig").OBSScene;
pub const QtShim = @import("obs/frontend.zig").QtShim;
pub fn includeExports() void {
    return obs.exportOBS();
}

pub const module_defaults: ModuleInfo = .{
    .name = "Really-Cool-Zig-Plugin",
    .version = "0.0.0",
    .author = "grayhatter",
    .description = "This is the description of your new dope plugin",

    .on_load_fn = on_load,
    .on_unload_fn = on_unload,
};

// exportOBS must be called at comptime otherwise zig will prune the minimal
// set of functions required when the plugin is loaded by OBS.
comptime {
    if (@This() == @import("root")) {
        obs.exportOBS();
    }
}

var arena: std.heap.ArenaAllocator = undefined;
var alloc: Allocator = undefined;

/// This function will be called by OBS when the plugin is loaded
/// Use it to set up the state you need.
fn on_load() bool {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    alloc = arena.allocator();
    // Because plugins are normally not in direct control of the timing
    // the exepected defer arena.deinit() is moved into on_unload()
    return true;
}

/// This function is called by OBS when it closes, or when something causes this
/// module to be unloaded.
fn on_unload() void {
    // This is the arena allocator created in on_load().
    // calling arena.deinit() if arena is the comptime `undefined` would invoke
    // undefined behavior. If this isn't acceptable, changing the arena to a
    // nullable type would resolve UB here.
    arena.deinit();
}
