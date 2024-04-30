const std = @import("std");
const plugin_config = @import("src/root.zig").module_defaults;
const name = plugin_config.name;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shim = b.addStaticLibrary(.{
        .name = "qt_shim",
        .target = target,
        .optimize = optimize,
    });
    shim.linkLibCpp();
    shim.addCSourceFile(.{
        .file = .{ .path = "src/cpp/qtdockwidget.cpp" },
        .flags = &.{
            "-I",
            "/usr/include/qt6/",
            "-I",
            "/usr/include/qt6/QtWidgets/",
        },
    });

    const lib = b.addSharedLibrary(.{
        .name = name,
        .root_source_file = .{
            .path = "src/root.zig",
        },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibrary(shim);
    lib.linkLibC();
    b.getInstallStep().dependOn(
        &b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = std.Build.InstallDir{ .custom = "" } },
            .dest_sub_path = name ++ "/bin/64bit/" ++ name ++ ".so",
        }).step,
    );

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
