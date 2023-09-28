const std = @import("std");
const data = @embedFile("1.txt");

fn parseInput() ![]i32 {
    var lines = std.mem.tokenizeAny(u8, data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var nums = std.ArrayList(i32).init(gpa.allocator());
    defer nums.deinit();

    while (lines.next()) |line| {
        var x = try std.fmt.parseInt(i32, line, 10);
        try nums.append(x);
    }

    return nums.toOwnedSlice();
}

pub fn part1() !i32 {
    const nums = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var diffs = std.AutoHashMap(i32, void).init(gpa.allocator());
    defer diffs.deinit();

    const sum = 2020;
    for (nums) |x| {
        var diff = sum - x;
        if (diffs.contains(diff)) {
            return x * diff;
        }
        try diffs.put(x, {});
    }

    return error.Error;
}

pub fn part2() !i32 {
    const nums = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var diffs = std.AutoHashMap(i32, void).init(gpa.allocator());
    defer diffs.deinit();

    const sum = 2020;
    for (nums) |x| {
        for (nums) |y| {
            var diff = sum - x - y;
            if (diffs.contains(diff)) {
                return x * y * diff;
            }
            try diffs.put(y, {});
        }
        diffs.clearRetainingCapacity();
    }

    return error.Error;
}
