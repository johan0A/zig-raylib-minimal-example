const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const name = b.option([]const u8, "name", "set the name of the emitted binary"); // this is mostly for making debugging with vscode simpler

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // here we get the dependency
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    // here we import the raylib module
    root_module.addImport("raylib", raylib_dep.module("raylib"));

    // here we link against the raylib library artifact,
    // it is needed here but this is not very usual for zig packages.
    // I guess it is usefull if we want to use our own version of raylib.
    root_module.linkLibrary(raylib_dep.artifact("raylib"));

    { // this is for compiling the executable
        const exe = b.addExecutable(.{ .name = name orelse "zig-exe-template", .root_module = root_module });
        b.installArtifact(exe);

        // and then maybe run it
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| run_cmd.addArgs(args);

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    { // this is for running the tests
        const tests = b.addTest(.{ .name = name orelse "test", .root_module = root_module });

        const run_tests = b.addRunArtifact(tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_tests.step);

        const debug_tests_artifact = b.addInstallArtifact(tests, .{});
        const debug_tests_step = b.step("build-test", "Create a test artifact that runs the tests");
        debug_tests_step.dependOn(&debug_tests_artifact.step);
    }

    { // this is for letting zls run static checks
        // more info: https://kristoff.it/blog/improving-your-zls-experience/ (the code in the blog post is outdated)
        const exe_check = b.addExecutable(.{ .name = "check", .root_module = root_module });
        const tests_check = b.addTest(.{ .name = "check", .root_module = root_module });

        const check = b.step("check", "Check if exe and tests compile");
        check.dependOn(&exe_check.step);
        check.dependOn(&tests_check.step);
    }
}
