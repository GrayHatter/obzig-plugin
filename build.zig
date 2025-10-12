const std = @import("std");
const project_name = @import("src/root.zig").module_defaults.name;
const name = project_name;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const moc_path = b.option(
        []const u8,
        "moc_path",
        "system path of the meta object compiler for Qt",
    ) orelse "/usr/lib/qt6/moc";

    updateQtMoc(b, moc_path);

    const shim = b.addLibrary(.{
        .name = "qt_shim",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    shim.linkLibCpp();
    shim.addCSourceFile(.{
        .file = b.path("src/cpp/qtdockwidget.cpp"),
        .flags = &.{
            "-I", "/usr/include/qt6/",
            "-I", "/usr/include/qt6/QtWidgets/",
        },
    });

    const module = b.addModule("OBS", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.linkLibrary(shim);
    //module.linkLibC();

    const lib = b.addLibrary(.{
        .name = "obzig-plugin",
        .linkage = .dynamic,
        .root_module = module,
    });
    lib.linkLibrary(shim);
    lib.linkLibC();
    b.getInstallStep().dependOn(
        &b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = std.Build.InstallDir{ .custom = "" } },
            .dest_sub_path = name ++ "/bin/64bit/" ++ name ++ ".so",
        }).step,
    );

    const lib_unit_tests = b.addTest(.{ .root_module = module });
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn updateQtMoc(b: *std.Build, moc_path: []const u8) void {
    const moc_run = b.addSystemCommand(&.{moc_path});
    moc_run.addFileArg(b.path("src/cpp/qtdockwidget.h"));
    moc_run.addArgs(&.{ "-p", "." });
    const stdout = moc_run.captureStdOut();

    const wf = b.addUpdateSourceFiles();
    wf.addCopyFileToSource(stdout, "src/cpp/qtdockwidget.moc");

    const update_protocol_step = b.step("regen-moc", "update src/protocol.zig to latest");
    update_protocol_step.dependOn(&wf.step);
}
