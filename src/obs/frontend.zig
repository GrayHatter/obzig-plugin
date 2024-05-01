const std = @import("std");
const OBS = @import("../obs.zig").OBS;

extern "obs-frontend-api" fn obs_frontend_add_tools_menu_item(
    name: [*:0]const u8,
    cb: obs_frontend_cb,
    ?*anyopaque,
) void;
extern "obs-frontend-api" fn obs_frontend_get_current_scene() ?*OBS.obs_source_t;
extern "obs-frontend-api" fn obs_frontend_set_current_scene(*OBS.obs_source_t) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_get_scene_names() callconv(.C) [*:null]?[*c]u8;
extern "obs-frontend-api" fn obs_frontend_get_scenes(?*obs_frontend_source_list) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_preview_program_trigger_transition() callconv(.C) void;
//extern "obs-frontend-api" fn obs_frontend_source_list_free(?*obs_frontend_source_list) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_add_custom_qdock([*c]const u8, ?*anyopaque) callconv(.C) bool;
extern "obs-frontend-api" fn obs_frontend_get_main_window() callconv(.C) ?*anyopaque;

const obs_frontend_cb = *const fn (?*anyopaque) callconv(.C) void;

const obs_src_array = extern struct {
    array: [*]?*OBS.obs_source_t,
    num: usize = 0,
    capacity: usize = 0,
};

const obs_frontend_source_list = extern struct {
    sources: extern union {
        da: OBS.darray,
        src: obs_src_array,
    },
};

pub const OBSScene = struct {
    pub fn findScenes() void {
        var scenes: obs_frontend_source_list = std.mem.zeroes(obs_frontend_source_list);

        obs_frontend_get_scenes(&scenes);
        // TODO write a c compat header for this
        // it's an inline and zig doesn't like C++
        // defer obs_frontend_source_list_free(&scenes);
        std.debug.print("source data {any}\n", .{scenes.sources.src});

        const array: [*]?*OBS.obs_source_t = @ptrCast(scenes.sources.src.array);
        for (array[0..scenes.sources.src.num]) |src| {
            //const scene: ?*OBS.obs_scene_t = OBS.obs_scene_from_source(src);
            const name: [*c]const u8 = OBS.obs_source_get_name(src);
            //const uuid: [*c]const u8 = OBS.obs_source_get_uuid(@ptrCast(scene));
            std.debug.print("scene {s} \n", .{name});
        }
    }

    pub fn swapPreview() void {
        //std.debug.print("swaping\n", .{});
        obs_frontend_preview_program_trigger_transition();
    }

    pub fn currentScene() ?[:0]const u8 {
        _ = obs_frontend_get_current_scene() orelse return null;

        //const t = @as(?*OBS.obs_source_info, @ptrCast(scene));

        //if (t.?.get_name) |_gn| {
        //    const name: ?[*c]const u8 = _gn(scene);
        //    if (name) |n| return std.mem.span(n);
        //}
        return null;
    }

    pub fn setCurrentScene(scene: ?*OBS.obs_source_t) void {
        obs_frontend_set_current_scene(scene);
    }

    pub fn getSceneNames() [:null]?[*c]const u8 {
        return std.mem.span(obs_frontend_get_scene_names());
    }
};

extern "qt_shim" fn createDock(?*anyopaque) callconv(.C) ?*anyopaque;

pub const QtShim = struct {
    pub fn newDock(name: [:0]const u8) bool {
        const qtwin = obs_frontend_get_main_window();
        const dock = createDock(qtwin);
        return obs_frontend_add_custom_qdock(name.ptr, dock);
    }
};
