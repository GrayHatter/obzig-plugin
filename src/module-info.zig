/// Module Info used to set up a plugin
pub const ModuleInfo = @This();

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

fn empty_on_load() bool {
    return true;
}

fn empty_on_unload() void {}
