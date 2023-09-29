const std = @import("std");
const data = @embedFile("09.txt");

const PREAMBLE_SIZE: usize = 25;

fn parseInput() ![]const i64 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var numbers = std.ArrayList(i64).init(std.heap.c_allocator);
    defer numbers.deinit();

    while (lines.next()) |line| {
        var number = try std.fmt.parseInt(i64, line, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

pub fn part1() !i64 {
    const numbers = try parseInput();

    var i: usize = PREAMBLE_SIZE;
    while (i < numbers.len) : (i += 1) {
        var diffs = std.AutoArrayHashMap(i64, void).init(std.heap.c_allocator);
        defer diffs.deinit();

        var j = i - PREAMBLE_SIZE;
        while (j < i) : (j += 1) {
            if (diffs.contains(numbers[j])) {
                break;
            }

            var diff = numbers[i] - numbers[j];
            try diffs.put(diff, {});
        } else {
            return numbers[i];
        }
    }

    unreachable;
}

pub fn part2() !i64 {
    const numbers = try parseInput();
    const target = try part1();

    var start: usize = 0;
    var end: usize = 2;
    var sum: i64 = numbers[0] + numbers[1];
    while (end < numbers.len) : (end += 1) {
        if (sum == target) {
            break;
        }

        sum += numbers[end];
        if (sum < target) {
            continue;
        }

        while (sum > target and end - start >= 2) : (start += 1) {
            sum -= numbers[start];
        }
    } else {
        unreachable;
    }

    var min = numbers[start];
    var max = numbers[start];
    var i: usize = start;
    while (i < end) : (i += 1) {
        min = @min(min, numbers[i]);
        max = @max(max, numbers[i]);
    }

    return min + max;
}
