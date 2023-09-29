const std = @import("std");
const data = @embedFile("11.txt");

const Cell = enum {
    Floor,
    Empty,
    Occupied,
};

fn parseInput() ![][]Cell {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var area = std.ArrayList([]Cell).init(std.heap.c_allocator);
    defer area.deinit();

    while (lines.next()) |line| {
        var row = try std.ArrayList(Cell).initCapacity(std.heap.c_allocator, line.len);
        defer row.deinit();

        for (line) |c| {
            switch (c) {
                '.' => try row.append(.Floor),
                'L' => try row.append(.Empty),
                else => unreachable,
            }
        }
        try area.append(try row.toOwnedSlice());
    }

    return area.toOwnedSlice();
}

fn countOccupiedAdjacent(area: []const []Cell, row: usize, col: usize) u8 {
    const row_start = if (row == 0) 0 else row - 1;
    const row_end = if (row == area.len - 1) area.len else row + 2;
    const col_start = if (col == 0) 0 else col - 1;
    const col_end = if (col == area[0].len - 1) area[0].len else col + 2;

    var count: u8 = 0;
    for (area[row_start..row_end]) |r| {
        for (r[col_start..col_end]) |c| {
            if (c == .Occupied) {
                count += 1;
            }
        }
    }

    if (area[row][col] == .Occupied) {
        count -= 1;
    }

    return count;
}

pub fn part1() !u64 {
    var curr = try parseInput();
    defer {
        for (curr) |row| {
            std.heap.c_allocator.free(row);
        }
        std.heap.c_allocator.free(curr);
    }

    var next = try std.heap.c_allocator.alloc([]Cell, curr.len);
    defer {
        for (next) |row| {
            std.heap.c_allocator.free(row);
        }
        std.heap.c_allocator.free(next);
    }

    for (curr, 0..) |row, i| {
        next[i] = try std.heap.c_allocator.alloc(Cell, row.len);
        @memcpy(next[i], row);
    }

    var changed = true;
    while (changed) {
        changed = false;
        for (0..curr.len) |i| {
            for (0..curr[0].len) |j| {
                switch (curr[i][j]) {
                    .Floor => {},
                    .Empty => {
                        if (countOccupiedAdjacent(curr, i, j) == 0) {
                            next[i][j] = .Occupied;
                            changed = true;
                        } else {
                            next[i][j] = .Empty;
                        }
                    },
                    .Occupied => {
                        if (countOccupiedAdjacent(curr, i, j) >= 4) {
                            next[i][j] = .Empty;
                            changed = true;
                        } else {
                            next[i][j] = .Occupied;
                        }
                    },
                }
            }
        }

        const tmp = curr;
        curr = next;
        next = tmp;
    }

    var count: u64 = 0;
    for (curr) |row| {
        for (row) |cell| {
            if (cell == .Occupied) {
                count += 1;
            }
        }
    }

    return count;
}

fn opccupiedRaycast(area: []const []Cell, row: usize, col: usize, dx: usize, dy: usize) bool {
    const height = area.len;
    const width = area[0].len;

    var x = col +% dx;
    var y = row +% dy;
    while (x < width and y < height) {
        switch (area[y][x]) {
            .Floor => {
                x +%= dx;
                y +%= dy;
            },
            .Empty => return false,
            .Occupied => return true,
        }
    }

    return false;
}

fn countOpccupiedRays(area: []const []Cell, row: usize, col: usize) u8 {
    var count: u8 = 0;

    for (0..3) |dx| {
        for (0..3) |dy| {
            if (dx == 1 and dy == 1) {
                continue;
            }
            if (opccupiedRaycast(area, row, col, dx -% 1, dy -% 1)) {
                count += 1;
            }
        }
    }

    return count;
}

pub fn part2() !u64 {
    var curr = try parseInput();
    defer {
        for (curr) |row| {
            std.heap.c_allocator.free(row);
        }
        std.heap.c_allocator.free(curr);
    }

    var next = try std.heap.c_allocator.alloc([]Cell, curr.len);
    defer {
        for (next) |row| {
            std.heap.c_allocator.free(row);
        }
        std.heap.c_allocator.free(next);
    }

    for (curr, 0..) |row, i| {
        next[i] = try std.heap.c_allocator.alloc(Cell, row.len);
        @memcpy(next[i], row);
    }

    var changed = true;
    while (changed) {
        changed = false;
        for (0..curr.len) |i| {
            for (0..curr[0].len) |j| {
                switch (curr[i][j]) {
                    .Floor => {},
                    .Empty => {
                        if (countOpccupiedRays(curr, i, j) == 0) {
                            next[i][j] = .Occupied;
                            changed = true;
                        } else {
                            next[i][j] = .Empty;
                        }
                    },
                    .Occupied => {
                        if (countOpccupiedRays(curr, i, j) >= 5) {
                            next[i][j] = .Empty;
                            changed = true;
                        } else {
                            next[i][j] = .Occupied;
                        }
                    },
                }
            }
        }

        const tmp = curr;
        curr = next;
        next = tmp;
    }

    var count: u64 = 0;
    for (curr) |row| {
        for (row) |cell| {
            if (cell == .Occupied) {
                count += 1;
            }
        }
    }

    return count;
}
