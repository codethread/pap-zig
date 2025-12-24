const lib = @import("pap");
const std = @import("std");

pub fn main() !void {
    std.debug.print("Run `zig build test` to execute all task tests.\n", .{});
}

test {
    _ = @import("pap");
}
