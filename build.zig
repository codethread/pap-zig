const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable (just prints test message)
    const exe = b.addExecutable(.{
        .name = "pap_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Test discovery: automatically find all solution.zig files in src/day* directories
    const test_step = b.step("test", "Run all task tests");

    // Create utils module for sharing across tasks
    const utils_module = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add tests for each task
    const tasks = [_][]const u8{
        "day01",
        "day02",
    };

    for (tasks) |task| {
        const task_path = b.fmt("src/{s}/solution.zig", .{task});
        const task_test = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(task_path),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Make utils module available to each task
        task_test.root_module.addImport("utils", utils_module);

        const run_task_test = b.addRunArtifact(task_test);
        test_step.dependOn(&run_task_test.step);
    }
}
