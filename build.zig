const std = @import("std");
const B = std.Build;

pub fn build(b: *B) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    {
        // this is for compiling the executable

        const exe = b.addExecutable(.{
            .name = "zig-exe-template",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        addDependencies(exe, b, target, optimize);

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        // and then maybe run it
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        // this is for running the tests

        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        addDependencies(exe_unit_tests, b, target, optimize);

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    {
        // this is for running static checks for zls
        // more info: https://kristoff.it/blog/improving-your-zls-experience/
        const exe_check = b.addExecutable(.{
            .name = "check",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        addDependencies(exe_check, b, target, optimize);

        const tests_check = b.addTest(.{
            .name = "check",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        addDependencies(tests_check, b, target, optimize);

        const check = b.step("check", "Check if exe and tests compile");
        check.dependOn(&exe_check.step);
        check.dependOn(&tests_check.step);
    }
}

fn addDependencies(
    compile_step: *B.Step.Compile,
    b: *B,
    target: B.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    // we are going to setup our dependencies here

    // here we get the dependency
    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    // here we import the raylib module
    const raylib = raylib_dep.module("raylib");
    compile_step.root_module.addImport("raylib", raylib);

    // here we link against the raylib c artifact,
    // this is not so usual for zig packages.
    // I guess it is usefull if we want to use our own version of raylib.
    const raylib_artifact = raylib_dep.artifact("raylib");
    compile_step.linkLibrary(raylib_artifact);
}
