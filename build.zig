const std = @import("std");

pub fn build(b: *std.Build) void {
    // flags
    const test_filters =
        b.option([][]const u8, "test-filter", "Test filters") orelse &.{};
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // units
    const root_mod, const exe, const unit_tests = bk: {
        const root_mod = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });
        const exe = b.addExecutable(.{
            .name = "pap_zig",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{.{ .name = "pap", .module = root_mod }},
            }),
        });
        const unit_tests = b.addTest(.{
            .root_module = root_mod,
            .filters = test_filters,
        });
        break :bk .{ root_mod, exe, unit_tests };
    };

    { // build assets
        inline for (&.{ "0037_single", "0038_multiple", "0039_more_moves", "0040_challenge_moves" }) |p| {
            const tool_run = b.addSystemCommand(&.{"nasm"});
            tool_run.addFileArg(b.path(b.fmt("src/assets/{s}.asm", .{p})));
            tool_run.addArg("-o");
            const o_path = tool_run.addOutputFileArg(p);

            root_mod.addAnonymousImport(p, .{ .root_source_file = o_path });
        }
    }

    // steps

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    const check = b.step("check", "Check if pap compiles");
    check.dependOn(&unit_tests.step);

    const test_step = b.step("test", "Run all task tests");
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    b.installArtifact(exe);
}
