const std = @import("std");
const Allocator = std.mem.Allocator;

const sway_ipc = @import("sway-ipc.zig");
const obs = @import("obs.zig");

pub const module_defaults: obs.ModuleDefaults = .{
    .name = "obs-sway-focus",
    .version = "0.0.1",
    .author = "grayhatter",
    .description = "tracks focus of sway windows",

    .on_load_fn = on_load,
    .on_unload_fn = on_unload,
};

comptime {
    obs.exportOBS();
}

var arena: std.heap.ArenaAllocator = undefined;
var alloc: Allocator = undefined;
var running = true;
var threads: [1]std.Thread = undefined;

var last: i64 = 0;
var on_build = false;

fn requestBuild() void {
    //std.debug.print("request build\n", .{});
    if (!on_build) obs.Scene.swapPreview();
    on_build = true;
    last = std.time.milliTimestamp();
}

fn requestCode() void {
    //std.debug.print("request code\n", .{});
    if (last < std.time.milliTimestamp() - 1500 and on_build) {
        obs.Scene.swapPreview();
    }
    on_build = false;
    last = std.time.milliTimestamp();
}

fn watchSway(_: ?*anyopaque) void {
    obs.log("sway thread running");
    var sway = sway_ipc.Connection.init(alloc) catch |err| {
        obs.logFmt("connection error {}", .{err});
        return;
    };
    sway.subscribe() catch {
        obs.log("crash trying to subscribe");
        unreachable;
    };
    std.time.sleep(10_000_000_000);
    obs.Scene.findScenes();
    while (running) {
        const msg = sway.loop() catch {
            obs.log("unexpected read error");
            unreachable;
        };

        std.time.sleep(100_000_000);
        switch (msg.toStruct(alloc) catch {
            obs.log("unable to build struct");
            continue;
        }) {
            .window => |w| {
                for (w.container.marks) |mark| {
                    if (std.mem.eql(u8, mark, "build")) {
                        //std.debug.print("found {}\n", .{w.container});
                        requestBuild();
                        break;
                    }
                } else {
                    requestCode();
                }
            },
        }
    }
    obs.log("sway-focus thread exit");
}

fn on_load() bool {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    alloc = arena.allocator();
    threads[0] = std.Thread.spawn(.{}, watchSway, .{null}) catch unreachable;

    return true;
}

fn on_unload() void {
    running = false;
    std.Thread.join(threads[0]);
    arena.deinit();
}

test "basic add functionality" {}
