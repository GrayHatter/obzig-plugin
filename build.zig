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

    //const Translator = @import("translate_c").Translator;
    //const translate_c = b.dependency("translate_c", .{});
    //const t: Translator = .init(translate_c, .{
    //    .c_source_file = b.path("to_translate.h"),
    //    .target = target,
    //    .optimize = optimize,
    //});
    //const obs_c = b.addTranslateC(.{
    //    .root_source_file = .{ .cwd_relative = "/usr/include/obs/obs-module.h" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //obs_c.use_clang = true;
    //const obs_mod = obs_c.addModule("OBS_C");
    //b.modules.put(b.dupe("OBS_C"), obs_mod) catch @panic("OOM");
    //_ = obs_mod;

    const shim = b.addLibrary(.{
        .name = "qt_shim",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .use_llvm = true,
        .use_lld = true,
    });
    shim.root_module.addCSourceFile(.{
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
        //.link_libc = true,
        //.link_libcpp = true,
    });

    //module.addImport("obs_tr", obs_mod);

    module.linkLibrary(shim);

    const lib = b.addLibrary(.{
        .name = "obzig-plugin",
        .linkage = .dynamic,
        .root_module = module,
    });
    b.getInstallStep().dependOn(
        &b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = std.Build.InstallDir{ .custom = "" } },
            .dest_sub_path = name ++ "/bin/64bit/" ++ name ++ ".so",
        }).step,
    );

    const lib_unit_tests = b.addTest(.{ .root_module = module });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn updateQtMoc(b: *std.Build, moc_path: []const u8) void {
    const moc_run = b.addSystemCommand(&.{moc_path});
    moc_run.addFileArg(b.path("src/cpp/qtdockwidget.h"));
    moc_run.addArgs(&.{ "-p", "." });
    const stdout = moc_run.captureStdOut(.{});

    const wf = b.addUpdateSourceFiles();
    wf.addCopyFileToSource(stdout, "src/cpp/qtdockwidget.moc");

    const update_protocol_step = b.step("regen-moc", "update src/protocol.zig to latest");
    update_protocol_step.dependOn(&wf.step);
}
