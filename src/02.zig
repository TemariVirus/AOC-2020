const std = @import("std");
const regex = @import("regex").Regex;
const data = @embedFile("02.txt");

const Password = struct {
    left: usize,
    right: usize,
    letter: u8,
    password: []const u8,
};

fn parseInput() ![]const Password {
    var lines = std.mem.tokenizeAny(u8, data, "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var expr = try regex.compile(gpa.allocator(), "(\\d+)-(\\d+) ([a-z]): ([a-z]+)");
    defer expr.deinit();

    var passwords = std.ArrayList(Password).init(gpa.allocator());
    defer passwords.deinit();

    while (lines.next()) |line| {
        const match = (try regex.captures(&expr, line)).?;

        var slots = [8]usize{ 0, 0, 0, 0, 0, 0, 0, 0 };
        for (match.slots[2..], 0..) |s, i| {
            slots[i] = s.?;
        }

        const left = try std.fmt.parseInt(usize, line[slots[0]..slots[1]], 10);
        const right = try std.fmt.parseInt(usize, line[slots[2]..slots[3]], 10);
        const letter = @as(u8, line[slots[4]]);
        const password = @as([]const u8, line[slots[6]..slots[7]]);

        try passwords.append(Password{
            .left = left,
            .right = right,
            .letter = letter,
            .password = password,
        });
    }

    return passwords.toOwnedSlice();
}

pub fn part1() !i32 {
    var valid: i32 = 0;
    for (try parseInput()) |p| {
        var count: i32 = 0;
        for (p.password) |c| {
            if (c == p.letter) {
                count += 1;
            }
        }
        if (count >= p.left and count <= p.right) {
            valid += 1;
        }
    }

    return valid;
}

pub fn part2() !i32 {
    var valid: i32 = 0;
    for (try parseInput()) |p| {
        const left = p.left - 1;
        const right = p.right - 1;

        var matches: i32 = 0;
        if (p.password[left] == p.letter) {
            matches += 1;
        }
        if (p.password[right] == p.letter) {
            matches += 1;
        }

        if (matches == 1) {
            valid += 1;
        }
    }

    return valid;
}
