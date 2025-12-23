const std = @import("std");

pub fn greet() void {
    _ = @import("utils.zig");
    std.debug.print("Run `zig build test` to execute all task tests.\n", .{});
}

test {
    _ = @import("part1.zig");
    _ = @import("part2.zig");
}
