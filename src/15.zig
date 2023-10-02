const std = @import("std");
const data = @embedFile("15.txt");

fn parseInput() ![]const u64 {
    var lines = std.mem.tokenizeScalar(u8, data, ',');

    var numbers = std.ArrayList(u64).init(std.heap.c_allocator);
    defer numbers.deinit();

    while (lines.next()) |line| {
        const number = try std.fmt.parseInt(u64, line, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

fn getSpokenNumber(numbers: []const u64, n: usize) !u64 {
    var last_spoken = std.AutoHashMap(u64, usize).init(std.heap.c_allocator);
    defer last_spoken.deinit();

    var turn: usize = 1;
    var last = numbers[0];
    while (turn < numbers.len) : (turn += 1) {
        try last_spoken.put(last, turn);
        last = numbers[turn];
    }

    while (turn < n) : (turn += 1) {
        if (!last_spoken.contains(last)) {
            try last_spoken.put(last, turn);
            last = 0;
            continue;
        }

        const diff = turn - last_spoken.get(last).?;
        try last_spoken.put(last, turn);
        last = diff;
    }

    return last;
}

pub fn part1() !u64 {
    const numbers = try parseInput();
    defer std.heap.c_allocator.free(numbers);

    return getSpokenNumber(numbers, 2020);
}

pub fn part2() !u64 {
    const numbers = try parseInput();
    defer std.heap.c_allocator.free(numbers);

    return getSpokenNumber(numbers, 30_000_000);
}
