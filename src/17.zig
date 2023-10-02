const std = @import("std");
const data = @embedFile("17.txt");

const BoolArray3D = struct {
    len_x: usize,
    len_y: usize,
    len_z: usize,
    data: std.DynamicBitSet,

    fn initEmpty(x: usize, y: usize, z: usize) !BoolArray3D {
        return BoolArray3D{
            .len_x = x,
            .len_y = y,
            .len_z = z,
            .data = try std.DynamicBitSet.initEmpty(std.heap.c_allocator, x * y * z),
        };
    }

    fn parse(buffer: []const u8) !BoolArray3D {
        // Start with 2 extra spaces on each side to skip (literal) edge cases
        // when counting neighbours
        var result = BoolArray3D{
            .len_x = 5,
            .len_y = undefined,
            .len_z = undefined,
            .data = try std.DynamicBitSet.initEmpty(std.heap.c_allocator, 0),
        };

        var lines = std.mem.tokenizeScalar(u8, buffer, '\n');
        result.len_z = lines.peek().?.len + 4;
        result.len_y = @divExact(buffer.len + 1, result.len_z - 3) + 4;
        try result.data.resize(result.len_x * result.len_y * result.len_z, false);

        var y: usize = 2;
        while (lines.next()) |line| {
            for (line, 2..) |c, z| {
                if (c == '#') {
                    result.set(2, y, z);
                }
            }
            y += 1;
        }

        return result;
    }

    fn getIndex(self: *BoolArray3D, x: usize, y: usize, z: usize) usize {
        return (x * self.len_y + y) * self.len_z + z;
    }

    fn get(self: *BoolArray3D, x: usize, y: usize, z: usize) bool {
        const idx = self.getIndex(x, y, z);
        return self.data.isSet(idx);
    }

    fn set(self: *BoolArray3D, x: usize, y: usize, z: usize) void {
        const idx = self.getIndex(x, y, z);
        self.data.set(idx);
    }

    fn unset(self: *BoolArray3D, x: usize, y: usize, z: usize) void {
        const idx = self.getIndex(x, y, z);
        self.data.unset(idx);
    }

    fn countNeighbours(self: *BoolArray3D, x: usize, y: usize, z: usize) i8 {
        var count: i8 = if (self.get(x, y, z)) -1 else 0;
        for (0..3) |dx| {
            for (0..3) |dy| {
                for (0..3) |dz| {
                    if (!self.get(x + dx - 1, y + dy - 1, z + dz - 1)) {
                        continue;
                    }

                    count += 1;
                    // Anything more than 4 doesn't affect the result
                    if (count > 3) {
                        return count;
                    }
                }
            }
        }
        return count;
    }

    fn nextCycle(self: *BoolArray3D) !BoolArray3D {
        defer self.data.deinit();

        var next = try BoolArray3D.initEmpty(self.len_x + 2, self.len_y + 2, self.len_z + 2);
        for (1..self.len_x - 1) |x| {
            for (1..self.len_y - 1) |y| {
                for (1..self.len_z - 1) |z| {
                    const active = self.get(x, y, z);
                    const count = self.countNeighbours(x, y, z);
                    if (count == 3 or (active and count == 2)) {
                        next.set(x + 1, y + 1, z + 1);
                    }
                }
            }
        }
        return next;
    }
};

const BoolArray4D = struct {
    len_w: usize,
    len_x: usize,
    len_y: usize,
    len_z: usize,
    data: std.DynamicBitSet,

    fn initEmpty(w: usize, x: usize, y: usize, z: usize) !BoolArray4D {
        return BoolArray4D{
            .len_w = w,
            .len_x = x,
            .len_y = y,
            .len_z = z,
            .data = try std.DynamicBitSet.initEmpty(std.heap.c_allocator, w * x * y * z),
        };
    }

    fn parse(buffer: []const u8) !BoolArray4D {
        // Start with 2 extra spaces on each side to skip (literal) edge cases
        // when counting neighbours
        var result = BoolArray4D{
            .len_w = 5,
            .len_x = 5,
            .len_y = undefined,
            .len_z = undefined,
            .data = try std.DynamicBitSet.initEmpty(std.heap.c_allocator, 0),
        };

        var lines = std.mem.tokenizeScalar(u8, buffer, '\n');
        result.len_z = lines.peek().?.len + 4;
        result.len_y = @divExact(buffer.len + 1, result.len_z - 3) + 4;
        try result.data.resize(result.len_w * result.len_x * result.len_y * result.len_z, false);

        var y: usize = 2;
        while (lines.next()) |line| {
            for (line, 2..) |c, z| {
                if (c == '#') {
                    result.set(2, 2, y, z);
                }
            }
            y += 1;
        }

        return result;
    }

    fn getIndex(self: *BoolArray4D, w: usize, x: usize, y: usize, z: usize) usize {
        return ((w * self.len_x + x) * self.len_y + y) * self.len_z + z;
    }

    fn get(self: *BoolArray4D, w: usize, x: usize, y: usize, z: usize) bool {
        const idx = self.getIndex(w, x, y, z);
        return self.data.isSet(idx);
    }

    fn set(self: *BoolArray4D, w: usize, x: usize, y: usize, z: usize) void {
        const idx = self.getIndex(w, x, y, z);
        self.data.set(idx);
    }

    fn unset(self: *BoolArray4D, w: usize, x: usize, y: usize, z: usize) void {
        const idx = self.getIndex(w, x, y, z);
        self.data.unset(idx);
    }

    fn countNeighbours(self: *BoolArray4D, w: usize, x: usize, y: usize, z: usize) i8 {
        var count: i8 = if (self.get(w, x, y, z)) -1 else 0;
        for (0..3) |dw| {
            for (0..3) |dx| {
                for (0..3) |dy| {
                    for (0..3) |dz| {
                        if (!self.get(w + dw - 1, x + dx - 1, y + dy - 1, z + dz - 1)) {
                            continue;
                        }

                        count += 1;
                        // Anything more than 4 doesn't affect the result
                        if (count > 3) {
                            return count;
                        }
                    }
                }
            }
        }
        return count;
    }

    fn nextCycle(self: *BoolArray4D) !BoolArray4D {
        defer self.data.deinit();

        var next = try BoolArray4D.initEmpty(self.len_w + 2, self.len_x + 2, self.len_y + 2, self.len_z + 2);
        for (1..self.len_w - 1) |w| {
            for (1..self.len_x - 1) |x| {
                for (1..self.len_y - 1) |y| {
                    for (1..self.len_z - 1) |z| {
                        const active = self.get(w, x, y, z);
                        const count = self.countNeighbours(w, x, y, z);
                        if (count == 3 or (active and count == 2)) {
                            next.set(w + 1, x + 1, y + 1, z + 1);
                        }
                    }
                }
            }
        }
        return next;
    }
};

pub fn part1() !usize {
    var cubes = try BoolArray3D.parse(data);
    for (0..6) |_| {
        cubes = try cubes.nextCycle();
    }
    return cubes.data.count();
}

pub fn part2() !usize {
    var cubes = try BoolArray4D.parse(data);
    for (0..6) |_| {
        cubes = try cubes.nextCycle();
    }
    return cubes.data.count();
}
