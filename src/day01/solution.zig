const std = @import("std");

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

inline fn wBit(byte: u8) bool {
    return (byte & 0b1) == 1;
}
inline fn modField(byte: u8) u8 {
    return byte >> 6;
}
inline fn rmField(byte: u8) u8 {
    return byte & 0b111;
}
inline fn regField2(byte: u8) u8 {
    return byte >> 3 & 0b111;
}

pub fn solve(writer: *std.Io.Writer, input: []const u8) !void {
    var i: u32 = 0;

    while (i < input.len) {
        const byte = input[i];

        switch (byte) {
            // mov
            // register to/from register
            0b10001000...0b10001011 => {
                // const d = byte >> 1 & 0b1 == 1;
                const w = wBit(byte);

                // get next byte
                i += 1;
                const byte_2 = input[i];
                const mod_byte = modField(byte_2);
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
                @panic("noop");
            },
            // immidiate to register
            0b1011000, 0b1011111 => {
                @panic("noop");
            },
            else => @panic("noop"),
        }

        i += 1;
    }
}

const test_allocator = std.testing.allocator;

test "day01 single" {
    const input = @embedFile("0037_single");
    const expected = clean_asm(@embedFile("0037_single.asm"));

    var list = try std.Io.Writer.Allocating.initCapacity(test_allocator, 1048);
    defer list.deinit();

    try solve(&list.writer, input);

    try std.testing.expectEqualStrings(expected, list.writer.buffer[0..list.writer.end]);
}

test "day01 multi" {
    const input = @embedFile("0038_multiple");
    const expected = clean_asm(@embedFile("0038_multiple.asm"));

    var list = try std.Io.Writer.Allocating.initCapacity(test_allocator, 1048);
    defer list.deinit();

    try solve(&list.writer, input);

    try std.testing.expectEqualStrings(expected, list.writer.buffer[0..list.writer.end]);
}

pub fn clean_asm(comptime input: []const u8) []const u8 {
    @setEvalBranchQuota(10000);
    const marker = "bits 16\n\n";
    const data = comptime blk: {
        const idx = std.mem.indexOf(u8, input, marker) orelse @compileError("missing marker");
        const ex = input[(idx + marker.len)..];
        const sz = std.mem.replacementSize(u8, ex, "\n\n", "\n");
        var buff: [sz]u8 = undefined;
        _ = std.mem.replace(u8, ex, "\n\n", "\n", buff[0..]);
        break :blk buff;
    };
    return &data;
}
