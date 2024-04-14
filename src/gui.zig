const std = @import("std");

pub const obs = @cImport({
    @cInclude("obs/util/darray.h");

    @cInclude("obs/util/base.h");
    @cInclude("obs/obs-module.h");
    @cInclude("obs/obs-config.h");
    @cInclude("obs/obs-data.h");
    @cInclude("obs/obs-properties.h");
    @cInclude("obs/obs-service.h");
});

const obs_src_array = extern struct {
    array: [*]?*obs.obs_source_t,
    num: usize = 0,
    capacity: usize = 0,
};

const obs_frontend_source_list = extern struct {
    sources: extern union {
        da: obs.darray,
        src: obs_src_array,
    },
};

const obs_frontend_cb = *const fn (?*anyopaque) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_add_tools_menu_item(name: [*:0]const u8, cb: obs_frontend_cb, ?*anyopaque) void;

extern "obs-frontend-api" fn obs_frontend_get_current_scene() ?*obs.obs_source_t;
extern "obs-frontend-api" fn obs_frontend_set_current_scene(*obs.obs_source_t) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_get_scene_names() callconv(.C) [*:null]?[*c]u8;
extern "obs-frontend-api" fn obs_frontend_get_scenes(?*obs_frontend_source_list) callconv(.C) void;

extern "obs-frontend-api" fn obs_frontend_preview_program_trigger_transition() callconv(.C) void;
//extern "obs-frontend-api" fn obs_frontend_source_list_free(?*obs_frontend_source_list) callconv(.C) void;

pub const OBSScene = struct {
    var last: i64 = 0;
    var on_build = false;

    pub fn findScenes() void {
        var scenes: obs_frontend_source_list = std.mem.zeroes(obs_frontend_source_list);

        obs_frontend_get_scenes(&scenes);
        // TODO write a c compat header for this
        //defer obs_frontend_source_list_free(&scenes);
        std.debug.print("source data {any}\n", .{scenes.sources.src});

        const array: [*]?*obs.obs_source_t = @ptrCast(scenes.sources.src.array);
        for (array[0..scenes.sources.src.num]) |src| {
            //const scene: ?*obs.obs_scene_t = obs.obs_scene_from_source(src);
            const name: [*c]const u8 = obs.obs_source_get_name(src);
            //const uuid: [*c]const u8 = obs.obs_source_get_uuid(@ptrCast(scene));
            std.debug.print("scene {s} \n", .{name});
        }
    }

    pub fn requestBuild() void {
        std.debug.print("request build\n", .{});
        if (!on_build) swapPreview();
        on_build = true;
        last = std.time.milliTimestamp();
    }

    pub fn requestCode() void {
        std.debug.print("request code\n", .{});
        if (last < std.time.milliTimestamp() - 1500 and on_build) {
            swapPreview();
        }
        on_build = false;
        last = std.time.milliTimestamp();
    }

    pub fn swapPreview() void {
        std.debug.print("swaping\n", .{});
        obs_frontend_preview_program_trigger_transition();
    }

    pub fn currentScene() ?[:0]const u8 {
        _ = obs_frontend_get_current_scene() orelse return null;

        //const t = @as(?*obs.obs_source_info, @ptrCast(scene));

        //if (t.?.get_name) |_gn| {
        //    const name: ?[*c]const u8 = _gn(scene);
        //    if (name) |n| return std.mem.span(n);
        //}
        return null;
    }

    pub fn setCurrentScene(scene: ?*obs.obs_source_t) void {
        obs_frontend_set_current_scene(scene);
    }

    pub fn getSceneNames() [:null]?[*c]const u8 {
        return std.mem.span(obs_frontend_get_scene_names());
    }
};

pub fn init() void {
    propertiesInit();
    //obs.obs_register_service(&focus_service);
}

fn propertiesInit() void {
    obs_frontend_add_tools_menu_item("click".ptr, clicked, null);

    const props: ?*obs.obs_properties_t = obs.obs_properties_create();
    _ = obs.obs_properties_add_bool(props, "blerg", "description");

    //
    //
    const data: ?*obs.obs_data_t = obs.obs_data_create();
    obs.obs_data_set_string(data, "set string", "this");
}

fn clicked(_: ?*anyopaque) callconv(.C) void {
    obs.blog(obs.LOG_INFO, "clicked");
}

//fn createService(_: ?*obs.struct_obs_data, _: ?*obs.struct_obs_service) callconv(.C) ?*anyopaque {
//    return null;
//}
//
//fn destroyService(_: ?*anyopaque) callconv(.C) void {}
//
//fn getName(_: ?*anyopaque) callconv(.C) [*:0]const u8 {
//    return "Service Name";
//}
//
//fn getProperties(_: ?*anyopaque) callconv(.C) ?*obs.obs_properties_t {
//    const ppts: ?*obs.obs_properties_t = obs.obs_properties_create();
//
//    _ = obs.obs_properties_add_bool(ppts, "my_bool", obs.obs_module_text("MyBool"));
//    return ppts;
//}

//const focus_service: obs.obs_service_info = obs.obs_service_info{
//    .id = "focus_service",
//    .create = createService,
//    .destroy = destroyService,
//    .get_name = getName,
//    .get_properties = getProperties,
//};
