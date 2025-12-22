# PAP Zig

Advent of Code style coding challenges in Zig.

## Structure

Each task is organized in its own folder under `src/`:

```
src/
├── day01/
│   ├── solution.zig    # Solution code and tests
│   └── input.txt       # Input data (optional)
├── day02/
│   ├── solution.zig
│   └── input.txt
└── ...
```

## Usage

### Running tests

Run all tests for all tasks:

```bash
zig build test
```

### Running the main executable

```bash
zig build run
```

This simply prints a message directing you to run tests.

## Debugging Tips

### VSCode LLDB Format Specifiers

When watching variables in the VSCode debugger, you can change the display format by adding a format specifier after the variable name:

```
variable,b       # binary (useful for bit patterns)
variable,x       # hexadecimal
variable,d       # decimal
variable,o       # octal
variable,c       # character
```

**Example:** To view a `u8` byte as binary instead of hex, add `byte,b` to the Watch window.

This is particularly useful when debugging instruction encoding where you need to see individual bits.

### Zig Print Debugging

Add debug output in your tests or solution code:

```zig
const std = @import("std");

// Print to stderr (won't interfere with test output)
std.debug.print("byte value: 0b{b:0>8}\n", .{byte});  // binary with leading zeros
std.debug.print("byte value: 0x{x:0>2}\n", .{byte});  // hex with leading zeros
std.debug.print("byte value: {d}\n", .{byte});         // decimal
```

### Running Individual Tests

Run tests for a specific task:

```bash
zig build test --summary all
```

Filter tests by name:

```bash
zig test src/part1.zig --test-filter "specific test name"
```

## Adding a new task

1. Create a new folder: `src/dayXX/`
2. Add a `solution.zig` file with this template:

```zig
const std = @import("std");

pub fn solve(input: []const u8) !u32 {
    // Your solution here
    _ = input;
    return 0;
}

test "dayXX example" {
    const input = "example input";
    const result = try solve(input);
    try std.testing.expectEqual(@as(u32, 0), result);
}
```

3. (Optional) Add an `input.txt` file and load it with `@embedFile("input.txt")`
4. Add your task name to the `tasks` array in [build.zig](build.zig):

```zig
const tasks = [_][]const u8{
    "day01",
    "day02",
    "dayXX", // Add your new task here
};
```

5. Run `zig build test` to verify your solution
