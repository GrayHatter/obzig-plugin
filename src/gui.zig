const std = @import("std");

pub const obs = @cImport({
    @cInclude("obs/util/base.h");
    @cInclude("obs/obs-module.h");
    @cInclude("obs/obs-config.h");
    @cInclude("obs/obs-data.h");
    @cInclude("obs/obs-properties.h");
    @cInclude("obs/obs-service.h");
});
const obs_frontend_cb = *const fn (?*anyopaque) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_add_tools_menu_item(name: [*:0]const u8, cb: obs_frontend_cb, ?*anyopaque) void;

extern "obs-frontend-api" fn obs_frontend_get_current_scene() ?*obs.obs_source_t;
extern "obs-frontend-api" fn obs_frontend_set_current_scene(*obs.obs_source_t) callconv(.C) void;
extern "obs-frontend-api" fn obs_frontend_get_scene_names() callconv(.C) [*:null]?[*c]u8;

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

fn createService(_: ?*obs.struct_obs_data, _: ?*obs.struct_obs_service) callconv(.C) ?*anyopaque {
    return null;
}

fn destroyService(_: ?*anyopaque) callconv(.C) void {}

fn getName(_: ?*anyopaque) callconv(.C) [*:0]const u8 {
    return "Service Name";
}

fn getProperties(_: ?*anyopaque) callconv(.C) ?*obs.obs_properties_t {
    const ppts: ?*obs.obs_properties_t = obs.obs_properties_create();

    _ = obs.obs_properties_add_bool(ppts, "my_bool", obs.obs_module_text("MyBool"));
    return ppts;
}

const focus_service: obs.obs_service_info = obs.obs_service_info{
    .id = "focus_service",
    .create = createService,
    .destroy = destroyService,
    .get_name = getName,
    .get_properties = getProperties,
};
