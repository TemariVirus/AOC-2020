const std = @import("std");
const data = @embedFile("05.txt");

const PackedIntArray = std.packed_int_array.PackedIntArray;

fn seatId(seat: []const u8) usize {
    var id: usize = 0;
    for (seat) |c| {
        id <<= 1;
        if (c == 'B' or c == 'R') {
            id |= 1;
        }
    }
    return id;
}

fn parseInput() !PackedIntArray(u1, 1024) {
    var lines = std.mem.tokenizeAny(u8, data, "\n");

    var ids = std.packed_int_array.PackedIntArray(u1, 1024).initAllTo(0);
    while (lines.next()) |line| {
        ids.set(seatId(line), 1);
    }
    return ids;
}

pub fn part1() !usize {
    var ids = try parseInput();

    var i: usize = 1023;
    return while (i >= 0) : (i -= 1) {
        if (ids.get(i) == 1) {
            return i;
        }
    };
}

pub fn part2() !usize {
    var ids = try parseInput();

    var i: usize = 1023;
    while (i >= 0) : (i -= 1) {
        if (ids.get(i) == 1) {
            break;
        }
    }

    return while (i >= 0) : (i -= 1) {
        if (ids.get(i) == 0) {
            return i;
        }
    };
}
