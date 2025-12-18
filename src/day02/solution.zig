const std = @import("std");

pub fn solve(input: []const u8) !u32 {
    // TODO: Implement your solution here
    _ = input;
    return 0;
}

test "day02 example" {
    const input = "example input";
    const result = try solve(input);
    try std.testing.expectEqual(@as(u32, 0), result);
}
