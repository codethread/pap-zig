const std = @import("std");
const print = @import("std").debug.print;
const mem = @import("std").mem;
const expectEqualStrings = @import("std").testing.expectEqualStrings;

/// Take in an asm file and strip all extra newlines + comments
/// this then creates a final string to diff against
pub fn clean_input_file(comptime input: []const u8) []const u8 {
    @setEvalBranchQuota(input.len * 3);
    const ln = "\n";
    const comment = ";";
    const output = comptime brk: {
        var buf: [input.len + ln.len]u8 = undefined;
        var iter = mem.splitAny(u8, input, ln);
        var i: usize = 0;
        var end: usize = 0;

        while (iter.next()) |entry| : (i = end) {
            if (entry.len == 0) continue;
            if (mem.startsWith(u8, entry, comment)) continue;

            end = i + entry.len + ln.len;
            @memcpy(buf[i..end], entry ++ ln);
        }

        // remove final trailing break;
        // const final = end - ln.len;
        const final = end;
        var out: [final]u8 = undefined;
        @memcpy(&out, buf[0..final]);

        break :brk out;
    };
    return &output;
}

const test_allocator = std.testing.allocator;

test clean_input_file {
    comptime {
        try expectEqualStrings("hey\n", clean_input_file("hey"));
        try expectEqualStrings("hey\n", clean_input_file("hey\n"));
        try expectEqualStrings("hey\n", clean_input_file("\nhey\n"));
        try expectEqualStrings("hey\nyou\n", clean_input_file("hey\n\nyou"));
        try expectEqualStrings("hey\nyou\n", clean_input_file("hey\n\n\n\nyou"));
        try expectEqualStrings("hey\nyou\n", clean_input_file("hey\n\n\n\nyou"));

        try expectEqualStrings("hey\n", clean_input_file("hey\n; this is a comment"));
        try expectEqualStrings("hey\n", clean_input_file("hey\n; this is a comment\n"));
        try expectEqualStrings("hey\nyou\n", clean_input_file("hey\n; this is a comment\nyou\n"));
    }
}
