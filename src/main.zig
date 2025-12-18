const std = @import("std");

pub fn main() !void {
    std.debug.print("Run `zig build test` to execute all task tests.\n", .{});
    std.debug.print("Each task is located in src/dayXX/ with its own solution.zig file.\n", .{});
}
