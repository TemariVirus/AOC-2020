const std = @import("std");
const data = @embedFile("03.txt");

fn parseInput() ![][]const u8 {
    var lines = std.mem.tokenizeAny(u8, data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var rows = std.ArrayList([]const u8).init(gpa.allocator());
    defer rows.deinit();

    while (lines.next()) |line| {
        try rows.append(line);
    }

    return rows.toOwnedSlice();
}

fn countCrashes(rows: [][]const u8, right: usize, down: usize) i32 {
    const width = rows[0].len;
    const height = rows.len;
    var x: usize = 0;
    var y: usize = 0;

    var count: i32 = 0;
    while (y < height) {
        if (rows[y][x] == '#') {
            count += 1;
        }

        x = (x + right) % width;
        y += down;
    }
    return count;
}

pub fn part1() !i32 {
    return countCrashes(try parseInput(), 3, 1);
}

pub fn part2() !i64 {
    const rows = try parseInput();

    var ret: i64 = 1;
    ret *= countCrashes(rows, 1, 1);
    ret *= countCrashes(rows, 3, 1);
    ret *= countCrashes(rows, 5, 1);
    ret *= countCrashes(rows, 7, 1);
    ret *= countCrashes(rows, 1, 2);

    return ret;
}
