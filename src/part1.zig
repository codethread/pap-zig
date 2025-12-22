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
inline fn regField1(byte: u8) u8 {
    return byte & 0b111;
}
inline fn regField2(byte: u8) u8 {
    return byte >> 3 & 0b111;
}

const errs = error{Unimplimented};

/// dissasemble 16 bit 8086 instruction set to a writer
pub fn dissasemble(writer: *std.Io.Writer, binary_bytes: []const u8) !void {
    try writer.print("bits 16\n", .{});

    var i: u32 = 0;
    var ln: u8 = 0;

    while (i < binary_bytes.len) : ({
        i += 1;
        ln += 1;
    }) {
        const byte = binary_bytes[i];

        switch (byte) {
            // mov
            // register to/from register
            0b10001000...0b10001011 => {
                // const d = byte >> 1 & 0b1 == 1;
                const w = getWBit(byte);

                // get next byte
                i += 1;
                const byte_2 = binary_bytes[i];
                var mod_byte = getModField(byte_2);
                const reg_byte = regField2(byte_2);
                const rm_byte = rmField(byte_2);

                const reg_from = if (w) WORD_REG_FIELD[reg_byte] else BYTE_REG_FIELD[reg_byte];
                const reg_to = if (w) WORD_REG_FIELD[rm_byte] else BYTE_REG_FIELD[rm_byte];

                if (mod_byte == 0b11) {
                    try writer.print("mov {s}, {s}\n", .{ reg_to, reg_from });
                    continue;
                }

                // effective address

                // cheeky
                if (rm_byte == 0b110 and mod_byte == 0) {
                    mod_byte = 0b10;
                    @panic("ah");
                }

                const disp_data: ?u16 = bk: switch (mod_byte) {
                    0b01 => {
                        i += 1;
                        break :bk binary_bytes[i];
                    },
                    0b10 => {
                        i += 1;
                        defer i += 1;
                        break :bk std.mem.readInt(u16, binary_bytes[i .. i + 2][0..2], .little);
                    },
                    else => null,
                };
                const fmt = " + {d}";
                var buf: [16 + fmt.len]u8 = undefined;
                var list = std.ArrayList(u8).initBuffer(&buf);

                if (disp_data) |d| {
                    if (d != 0) try list.printBounded(" + {d}", .{d});
                } else try list.printBounded("", .{});

                const disp = list.items;

                try switch (rm_byte) {
                    0b000 => writer.print("mov {s}, [bx + si{s}] \n", .{ reg_to, disp }),
                    0b001 => writer.print("mov {s}, [bx + di{s}] \n", .{ reg_to, disp }),
                    0b010 => writer.print("mov {s}, [bp + si{s}] \n", .{ reg_to, disp }),
                    0b011 => writer.print("mov {s}, [bp + di{s}] \n", .{ reg_to, disp }),
                    0b100 => writer.print("mov {s}, [si{s}] \n", .{ reg_to, disp }),
                    0b101 => writer.print("mov {s}, [di{s}] \n", .{ reg_to, disp }),
                    // direct access
                    0b110 => writer.print("mov {s}, [bp{s}] \n", .{ reg_to, disp }),
                    0b111 => writer.print("mov {s}, [{s}{s}] \n", .{ reg_to, reg_from, disp }),
                    else => {
                        std.debug.print("no byte {x}", .{rm_byte});
                        return error.Unimplimented;
                    },
                };
            },
            // immidiate to register/memory
            0b1100001, 0b11000111 => {
                std.debug.print("unexpected byte {b}", .{byte});
                return errs.Unimplimented;
            },
            // immidiate to register
            0b10110000...0b10111111 => {
                const w = byte >> 3 & 0b1 == 1;
                const reg_byte = regField1(byte);
                i += 1;
                const byte_2: u16 = if (!w) binary_bytes[i] else bk: {
                    defer i += 1;
                    break :bk std.mem.readInt(u16, binary_bytes[i .. i + 2][0..2], .little);
                };
                const reg_to = if (w) WORD_REG_FIELD[reg_byte] else BYTE_REG_FIELD[reg_byte];
                try writer.print("mov {s}, {d}\n", .{ reg_to, byte_2 });
            },
            else => {
                std.debug.print("unexpected byte {b}", .{byte});
                return errs.Unimplimented;
            },
        }
    }
}

const test_allocator = std.testing.allocator;

test dissasemble {
    comptime {
        for (.{
            // "assets/0037_single",
            // "assets/0038_multiple",
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
            errdefer {
                std.debug.print("\nDecoded:\n{s}", .{list.writer.buffer[0..list.writer.end]});
            }

            try dissasemble(&list.writer, input);
            try std.testing.expectEqualStrings(expected, list.writer.buffer[0..list.writer.end]);
        }
    };
}
