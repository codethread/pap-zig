const std = @import("std");
const utils = @import("utils.zig");

const BYTE_REG_FIELD = [_][]const u8{
    "al", // 000
    "cl", // 001
    "dl", // 010
    "bl", // 011
    "ah", // 100
    "ch", // 101
    "dh", // 110
    "bh", // 111
};

const WORD_REG_FIELD = [_][]const u8{
    "ax", // 000
    "cx", // 001
    "dx", // 010
    "bx", // 011
    "sp", // 100
    "bp", // 101
    "si", // 110
    "di", // 111
};

inline fn getWBit(byte: u8) bool {
    return (byte & 0b1) == 1;
}
inline fn getModField(byte: u8) u8 {
    return byte >> 6;
}
inline fn rmField(byte: u8) u8 {
    return byte & 0b111;
}
inline fn regField2(byte: u8) u8 {
    return byte >> 3 & 0b111;
}

const errs = error{Unimplimented};

pub fn solve(writer: *std.Io.Writer, input: []const u8) !void {
    try writer.print("bits 16\n", .{});

    var i: u32 = 0;

    while (i < input.len) {
        const byte = input[i];

        switch (byte) {
            // mov
            // register to/from register
            0b10001000...0b10001011 => {
                // const d = byte >> 1 & 0b1 == 1;
                const w = getWBit(byte);

                // get next byte
                i += 1;
                const byte_2 = input[i];
                const mod_byte = getModField(byte_2);
                const reg_byte = regField2(byte_2);
                const rm_byte = rmField(byte_2);

                if (mod_byte != 0b11) {
                    @panic("noop");
                }
                const reg_from = if (w) WORD_REG_FIELD[reg_byte] else BYTE_REG_FIELD[reg_byte];
                const reg_to = if (w) WORD_REG_FIELD[rm_byte] else BYTE_REG_FIELD[rm_byte];

                try writer.print("mov {s}, {s}\n", .{ reg_to, reg_from });
            },
            // immidiate to register/memory
            0b1100001, 0b11000111 => {
                return errs.Unimplimented;
            },
            // immidiate to register
            0b1011000, 0b1011111 => {
                return errs.Unimplimented;
            },
            else => return errs.Unimplimented,
        }

        i += 1;
    }
}

const test_allocator = std.testing.allocator;

const tests = .{
    "assets/0037_single",
    "assets/0038_multiple",
    "assets/0039_more_moves",
};

test solve {
    comptime { // we can even define cases using comptime metaprogramming
        for (.{
            "assets/0037_single",
            "assets/0038_multiple",
            "assets/0039_more_moves",
        }) |case| {
            _ = TestDissasembler(case);
        }
    }
}

fn TestDissasembler(comptime case: []const u8) type {
    return struct {
        test {
            const input = @embedFile(case);
            const expected = utils.clean_input_file(@embedFile(case ++ ".asm"));

            var list = try std.Io.Writer.Allocating.initCapacity(test_allocator, expected.len * 4);
            defer list.deinit();

            try solve(&list.writer, input);
            try std.testing.expectEqualStrings(expected, list.writer.buffer[0..list.writer.end]);
        }
    };
}
