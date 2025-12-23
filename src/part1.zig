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

/// dissasemble 16 bit 8086 instruction set, returns owned slice
pub fn dissasemble(allocator: std.mem.Allocator, binary_bytes: []const u8) ![]const u8 {
    var list = try std.Io.Writer.Allocating.initCapacity(allocator, binary_bytes.len * 4);
    errdefer list.deinit();
    const writer = &list.writer;

    try writer.print("bits 16\n", .{});

    var i: u32 = 0;
    // line number purely to help debug the asm line under test
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
                const direction = byte >> 1 & 0b1 == 1;
                const w = getWBit(byte);

                // get next byte
                i += 1;
                const byte_2 = binary_bytes[i];
                var mod_byte = getModField(byte_2);
                const reg_byte = regField2(byte_2);
                const rm_byte = rmField(byte_2);

                var scratch = std.heap.ArenaAllocator.init(allocator);
                defer scratch.deinit();
                const scratch_alloc = scratch.allocator();

                const reg_field = if (w) WORD_REG_FIELD[reg_byte] else BYTE_REG_FIELD[reg_byte];
                const rm_field = if (w) WORD_REG_FIELD[rm_byte] else BYTE_REG_FIELD[rm_byte];

                if (mod_byte == 0b11) {
                    try writer.print("mov {s}, {s}\n", if (direction) .{ reg_field, rm_field } else .{ rm_field, reg_field });
                    continue;
                }

                // cheeky
                if (rm_byte == 0b110 and mod_byte == 0) {
                    mod_byte = 0b10;
                    @panic("ah");
                }

                const disp = disp_bk: {
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
                    var disp_list = std.ArrayList(u8).initBuffer(&buf);

                    if (disp_data) |d| {
                        if (d != 0) try disp_list.printBounded(" + {d}", .{d});
                    } else try disp_list.printBounded("", .{});
                    break :disp_bk disp_list.items;
                };

                const rm_operand = try switch (rm_byte) {
                    0b000 => std.fmt.allocPrint(scratch_alloc, "[bx + si{s}]", .{disp}),
                    0b001 => std.fmt.allocPrint(scratch_alloc, "[bx + di{s}]", .{disp}),
                    0b010 => std.fmt.allocPrint(scratch_alloc, "[bp + si{s}]", .{disp}),
                    0b011 => std.fmt.allocPrint(scratch_alloc, "[bp + di{s}]", .{disp}),
                    0b100 => std.fmt.allocPrint(scratch_alloc, "[si{s}]", .{disp}),
                    0b101 => std.fmt.allocPrint(scratch_alloc, "[di{s}]", .{disp}),
                    0b110 => std.fmt.allocPrint(scratch_alloc, "[bp{s}]", .{disp}),
                    0b111 => std.fmt.allocPrint(scratch_alloc, "[{s}{s}]", .{ rm_field, disp }),
                    else => @panic("not u3"),
                };

                try writer.print("mov {s}, {s}\n", if (direction) .{ reg_field, rm_operand } else .{ rm_operand, reg_field });
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
                const dest = if (w) WORD_REG_FIELD[reg_byte] else BYTE_REG_FIELD[reg_byte];

                const ImmediateValue = union(enum) {
                    byte: u8,
                    word: u16,
                };

                const src = bk: {
                    const immediate = if (w) ImmediateValue{
                        .word = blk: {
                            defer i += 1;
                            break :blk std.mem.readInt(u16, binary_bytes[i .. i + 2][0..2], .little);
                        },
                    } else ImmediateValue{
                        .byte = binary_bytes[i],
                    };

                    var buf: [6]u8 = undefined;
                    const formatted = switch (immediate) {
                        .byte => |val| blk: {
                            const signed = if (val > std.math.maxInt(u8) / 2)
                                @as(i8, @bitCast(val))
                            else
                                @as(i16, val);
                            break :blk try std.fmt.bufPrint(&buf, "{d}", .{signed});
                        },
                        .word => |val| blk: {
                            const signed = if (val > std.math.maxInt(u16) / 2)
                                @as(i16, @bitCast(val))
                            else
                                @as(i16, @bitCast(val));
                            break :blk try std.fmt.bufPrint(&buf, "{d}", .{signed});
                        },
                    };
                    break :bk formatted;
                };
                try writer.print("mov {s}, {s}\n", .{ dest, src });
            },
            else => {
                std.debug.print("unexpected byte {b}", .{byte});
                return errs.Unimplimented;
            },
        }
    }

    return list.toOwnedSlice();
}

const test_allocator = std.testing.allocator;

test dissasemble {
    comptime {
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

            const result = try dissasemble(test_allocator, input);
            defer test_allocator.free(result);
            errdefer {
                std.debug.print("\nDecoded:\n{s}", .{result});
            }

            try std.testing.expectEqualStrings(expected, result);
        }
    };
}
