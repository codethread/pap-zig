const std = @import("std");
const utils = @import("utils.zig");

/// Register lookup tables indexed by the 3-bit REG/R/M field.
const Register = struct {
    const byte = [_][]const u8{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
    const word = [_][]const u8{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

    fn get(index: u3, wide: bool) []const u8 {
        return if (wide) word[index] else byte[index];
    }
};

/// Effective address calculation base components indexed by R/M field.
const effective_address_base = [_][]const u8{
    "bx + si", // 000
    "bx + di", // 001
    "bp + si", // 010
    "bp + di", // 011
    "si", // 100
    "di", // 101
    "bp", // 110
    "bx", // 111
};

/// Decoded fields from MOD-REG-R/M byte.
const ModRegRm = struct {
    mod: u2,
    reg: u3,
    rm: u3,

    fn decode(byte: u8) ModRegRm {
        return .{
            .mod = @truncate(byte >> 6),
            .reg = @truncate(byte >> 3),
            .rm = @truncate(byte),
        };
    }
};

/// Extract the W (wide) bit from instruction byte.
fn isWide(byte: u8) bool {
    return (byte & 0b1) == 1;
}

const DisassembleError = error{Unimplemented};

/// Disassemble 16-bit 8086 instruction set, returns owned slice.
pub fn disassemble(allocator: std.mem.Allocator, binary_bytes: []const u8) ![]const u8 {
    var list = try std.Io.Writer.Allocating.initCapacity(allocator, binary_bytes.len * 4);
    errdefer list.deinit();
    const writer = &list.writer;

    try writer.print("bits 16\n", .{});

    var i: usize = 0;
    while (i < binary_bytes.len) : (i += 1) {
        const byte = binary_bytes[i];

        switch (byte) {
            // mov
            // register to/from register
            0b10001000...0b10001011 => {
                const reg_is_dest = (byte >> 1 & 0b1) == 1;
                const wide = isWide(byte);

                i += 1;
                const modrm = ModRegRm.decode(binary_bytes[i]);

                const reg_name = Register.get(modrm.reg, wide);
                const rm_name = Register.get(modrm.rm, wide);

                // Register-to-register mode (mod = 11)
                if (modrm.mod == 0b11) {
                    const operands = if (reg_is_dest) .{ reg_name, rm_name } else .{ rm_name, reg_name };
                    try writer.print("mov {s}, {s}\n", operands);
                    continue;
                }

                // Direct address special case (mod=00, rm=110)
                if (modrm.rm == 0b110 and modrm.mod == 0) {
                    @panic("direct address mode not yet implemented");
                }

                // Read displacement based on mod field
                const displacement: ?u16 = switch (modrm.mod) {
                    0b00 => null,
                    0b01 => blk: {
                        i += 1;
                        break :blk binary_bytes[i];
                    },
                    0b10 => blk: {
                        i += 1;
                        defer i += 1;
                        break :blk std.mem.readInt(u16, binary_bytes[i..][0..2], .little);
                    },
                    0b11 => unreachable, // handled above
                };

                // Format displacement suffix
                var disp_buf: [16]u8 = undefined;
                const disp_str = if (displacement) |d|
                    if (d != 0) std.fmt.bufPrint(&disp_buf, " + {d}", .{d}) catch unreachable else ""
                else
                    "";

                // Format effective address
                var addr_buf: [32]u8 = undefined;
                const rm_operand = std.fmt.bufPrint(&addr_buf, "[{s}{s}]", .{
                    effective_address_base[modrm.rm],
                    disp_str,
                }) catch unreachable;

                const operands = if (reg_is_dest) .{ reg_name, rm_operand } else .{ rm_operand, reg_name };
                try writer.print("mov {s}, {s}\n", operands);
            },
            // immediate to register/memory
            0b11000110...0b11000111 => {
                return DisassembleError.Unimplemented;
            },
            // immediate to register
            0b10110000...0b10111111 => {
                const wide = (byte >> 3 & 0b1) == 1;
                const reg: u3 = @truncate(byte);
                i += 1;

                const dest = Register.get(reg, wide);
                const immediate: i16 = if (wide) blk: {
                    defer i += 1;
                    break :blk @bitCast(std.mem.readInt(u16, binary_bytes[i..][0..2], .little));
                } else blk: {
                    // Sign-extend byte to i16 for consistent formatting
                    const val = binary_bytes[i];
                    break :blk if (val > 127) @as(i8, @bitCast(val)) else val;
                };

                try writer.print("mov {s}, {d}\n", .{ dest, immediate });
            },
            // Memory to accumulator
            0b10100000...0b10100011 => {
                const wide = isWide(byte);
                i += 1;
                const memory: i16 = if (wide) blk: {
                    defer i += 1;
                    break :blk @bitCast(std.mem.readInt(u16, binary_bytes[i..][0..2], .little));
                } else blk: {
                    // Sign-extend byte to i16 for consistent formatting
                    const val = binary_bytes[i];
                    break :blk if (val > 127) @as(i8, @bitCast(val)) else val;
                };

                const is_to: bool = brk: {
                    const s: u1 = @truncate(byte >> 1);
                    break :brk s == 1;
                };

                try if (is_to) writer.print("mov ax, [{d}]\n", .{memory}) //
                else writer.print("mov [{d}], ax\n", .{memory});
            },
            else => {
                std.debug.print("unexpected byte {b}\n", .{byte});
                return DisassembleError.Unimplemented;
            },
        }
    }

    return list.toOwnedSlice();
}

const test_allocator = std.testing.allocator;

test disassemble {
    comptime {
        for (.{
            "0037_single",
            "0038_multiple",
            "0039_more_moves",
            // "0040_challenge_moves",
        }) |case| {
            _ = TestDisassembler(case);
        }
    }
}

fn TestDisassembler(comptime case: []const u8) type {
    return struct {
        test {
            const input = @embedFile(case);
            const expected = utils.clean_input_file(@embedFile("assets/" ++ case ++ ".asm"));

            const result = try disassemble(test_allocator, input);
            defer test_allocator.free(result);
            errdefer {
                std.debug.print("\nDecoded:\n{s}", .{result});
            }

            try std.testing.expectEqualStrings(expected, result);
        }
    };
}
