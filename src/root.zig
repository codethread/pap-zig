const std = @import("std");

test {
    _ = @import("part1.zig");
    _ = @import("part2.zig");
}

test "build assets" {
    try std.testing.expectEqualSlices(u8, @embedFile("0037_single"), &.{
        0x89,
        0xd9,
    });
}
