const std = @import("std");

pub fn greet() void {
    std.debug.print("Run `zig build test` to execute all task tests.\n", .{});
}

test {
    _ = @import("day01.zig");
    _ = @import("day02.zig");
}
