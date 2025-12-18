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
