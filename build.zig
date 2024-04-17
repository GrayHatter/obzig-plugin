const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
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
        .name = "obs-sway-focus",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibrary(shim);
    lib.linkLibC();
    // b.installArtifact(lib);
    b.getInstallStep().dependOn(
        &b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = std.Build.InstallDir{ .custom = "" } },
            .dest_sub_path = "obs-sway-focus/bin/64bit/obs-sway-focus.so",
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
