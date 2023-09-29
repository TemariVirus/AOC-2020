const std = @import("std");
const data = @embedFile("10.txt");

fn parseInput() ![]u64 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var numbers = std.ArrayList(u64).init(std.heap.c_allocator);
    defer numbers.deinit();

    while (lines.next()) |line| {
        var number = try std.fmt.parseInt(u64, line, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

pub fn part1() !u64 {
    const jolts = try parseInput();
    std.mem.sort(u64, jolts, {}, comptime std.sort.asc(u64));

    var ones: u64 = 0;
    var threes: u64 = 1; // Device adapter is always 3 jolts higher than the highest adapter

    if (jolts[0] == 1) {
        ones += 1;
    } else if (jolts[0] == 3) {
        threes += 1;
    }

    for (0..jolts.len - 1) |i| {
        var diff = jolts[i + 1] - jolts[i];
        if (diff == 1) {
            ones += 1;
        } else if (diff == 3) {
            threes += 1;
        }
    }

    return ones * threes;
}

pub fn part2() !u64 {
    const jolts = try parseInput();
    std.mem.sort(u64, jolts, {}, comptime std.sort.asc(u64));

    var count1: u64 = 1;
    var count2: u64 = 0;
    var count3: u64 = 0;

    var i = jolts.len - 1;
    while (i > 0) {
        i -= 1;

        var count: u64 = 0;
        if (i + 3 < jolts.len and jolts[i + 3] - jolts[i] <= 3) {
            count += count3;
        }
        if (i + 2 < jolts.len and jolts[i + 2] - jolts[i] <= 3) {
            count += count2;
        }
        if (i + 1 < jolts.len and jolts[i + 1] - jolts[i] <= 3) {
            count += count1;
        }

        count3 = count2;
        count2 = count1;
        count1 = count;
    }

    var count: u64 = 0;
    if (jolts[2] <= 3) {
        count += count3;
    }
    if (jolts[1] <= 3) {
        count += count2;
    }
    if (jolts[0] <= 3) {
        count += count1;
    }

    return count;
}
