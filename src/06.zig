const std = @import("std");
const data = @embedFile("06.txt");

pub fn part1() !usize {
    var parts = std.mem.tokenizeSequence(u8, data, "\n\n");

    var sum: usize = 0;
    while (parts.next()) |p| {
        var answers = std.bit_set.IntegerBitSet(26).initEmpty();
        var lines = std.mem.tokenizeScalar(u8, p, '\n');

        while (lines.next()) |line| {
            for (line) |c| {
                answers.set(c - 'a');
            }
        }

        sum += answers.count();
    }

    return sum;
}

pub fn part2() !usize {
    var parts = std.mem.tokenizeSequence(u8, data, "\n\n");

    var sum: usize = 0;
    while (parts.next()) |p| {
        var answers = std.bit_set.IntegerBitSet(26).initFull();
        var lines = std.mem.tokenizeScalar(u8, p, '\n');

        while (lines.next()) |line| {
            var answer = std.bit_set.IntegerBitSet(26).initEmpty();
            for (line) |c| {
                answer.set(c - 'a');
            }
            answers = answers.intersectWith(answer);
        }

        sum += answers.count();
    }

    return sum;
}
