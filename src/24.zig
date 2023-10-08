const std = @import("std");
const data = @embedFile("24.txt");

const Allocator = std.mem.Allocator;

const Vec2 = struct {
    x: i32,
    y: i32,

    fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

const directions = [_]Vec2{
    Vec2{ .x = 1, .y = 0 }, // East
    Vec2{ .x = -1, .y = 0 }, // West
    Vec2{ .x = 0, .y = -1 }, // SouthEast
    Vec2{ .x = -1, .y = -1 }, // SouthWest
    Vec2{ .x = 1, .y = 1 }, // NorthEast
    Vec2{ .x = 0, .y = 1 }, // NorthWest
};

fn parsePos(line: []const u8) Vec2 {
    var pos = Vec2{ .x = 0, .y = 0 };
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        switch (line[i]) {
            'e' => pos.x += 1,
            'w' => pos.x -= 1,
            's' => {
                pos.y -= 1;
                i += 1;
                switch (line[i]) {
                    'e' => {},
                    'w' => pos.x -= 1,
                    else => unreachable,
                }
            },
            'n' => {
                pos.y += 1;
                i += 1;
                switch (line[i]) {
                    'e' => pos.x += 1,
                    'w' => {},
                    else => unreachable,
                }
            },
            else => unreachable,
        }
    }
    return pos;
}

fn parseInput(allocator: Allocator) !std.AutoHashMap(Vec2, void) {
    var black = std.AutoHashMap(Vec2, void).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const pos = parsePos(line);
        if (!black.remove(pos)) {
            try black.put(pos, {});
        }
    }
    return black;
}

fn countNeighbours(black: *const std.AutoHashMap(Vec2, void), pos: Vec2) u8 {
    var count: u8 = 0;
    for (directions) |d| {
        if (black.contains(pos.add(d))) {
            count += 1;
        }
    }
    return count;
}

fn updateTiles(black: *std.AutoHashMap(Vec2, void)) !void {
    var new_black = std.AutoHashMap(Vec2, void).init(black.allocator);

    var tiles = black.keyIterator();
    while (tiles.next()) |tile| {
        const t = tile.*;
        // Update black
        const neighbours = countNeighbours(black, t);
        if (neighbours == 1 or neighbours == 2) {
            try new_black.put(t, {});
        }

        // Update surrounding white
        for (directions) |d| {
            const pos = t.add(d);
            if (black.contains(pos)) {
                continue;
            }
            if (countNeighbours(black, pos) == 2) {
                try new_black.put(pos, {});
            }
        }
    }

    black.deinit();
    black.* = new_black;
}

pub fn part1() !usize {
    const allocator = std.heap.c_allocator;

    var black = try parseInput(allocator);
    defer black.deinit();

    return black.count();
}

pub fn part2() !usize {
    const allocator = std.heap.c_allocator;

    var black = try parseInput(allocator);
    defer black.deinit();

    for (0..100) |_| {
        try updateTiles(&black);
    }

    return black.count();
}
