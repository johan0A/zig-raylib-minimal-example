const std = @import("std");
const B = std.Build;

pub fn build(b: *B) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    {
        const exe = b.addExecutable(.{
            .name = "zig-exe-template",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    {
        const exe_check = b.addExecutable(.{
            .name = "check",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const tests_check = b.addTest(.{
            .name = "check",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

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
    _ = compile_step;
    _ = b;
    _ = target;
    _ = optimize;
}
