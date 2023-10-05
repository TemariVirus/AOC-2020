const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const data = @embedFile("20.txt");

const assert = std.debug.assert;

const TileType = enum {
    Corner,
    Edge,
    Center,
};

const TileMap = std.AutoHashMap(u10, std.BoundedArray(Tile, 2));
const Tile = struct {
    id: u16,
    edges: [4]u10,
    center: [8]u8,

    fn tileType(self: Tile, tiles: TileMap) TileType {
        var match_count: u8 = 0;
        for (self.edges) |edge| {
            match_count += tiles.get(edge).?.len;
        }
        return switch (match_count) {
            6 => .Corner,
            7 => .Edge,
            8 => .Center,
            else => unreachable,
        };
    }

    fn flipVertical(self: Tile) Tile {
        return Tile{
            .id = self.id,
            .edges = [_]u10{
                @bitReverse(self.edges[2]),
                @bitReverse(self.edges[1]),
                @bitReverse(self.edges[0]),
                @bitReverse(self.edges[3]),
            },
            .center = [_]u8{
                self.center[7],
                self.center[6],
                self.center[5],
                self.center[4],
                self.center[3],
                self.center[2],
                self.center[1],
                self.center[0],
            },
        };
    }

    fn flipHorizontal(self: Tile) Tile {
        return Tile{
            .id = self.id,
            .edges = [_]u10{
                @bitReverse(self.edges[0]),
                @bitReverse(self.edges[3]),
                @bitReverse(self.edges[2]),
                @bitReverse(self.edges[1]),
            },
            .center = [_]u8{
                @bitReverse(self.center[0]),
                @bitReverse(self.center[1]),
                @bitReverse(self.center[2]),
                @bitReverse(self.center[3]),
                @bitReverse(self.center[4]),
                @bitReverse(self.center[5]),
                @bitReverse(self.center[6]),
                @bitReverse(self.center[7]),
            },
        };
    }

    fn rotateRight(self: Tile) Tile {
        var center = [_]u8{0} ** 8;
        for (0..8) |i| {
            for (0..8) |j| {
                center[i] <<= 1;
                center[i] |= (self.center[j] >> @as(u3, @truncate(i))) & 1;
            }
        }
        return Tile{
            .id = self.id,
            .edges = [_]u10{ self.edges[3], self.edges[0], self.edges[1], self.edges[2] },
            .center = center,
        };
    }

    fn getOtherTile(self: Tile, tiles: TileMap, edge: u10) Tile {
        const tile_pair = tiles.get(edge).?;
        return if (tile_pair.buffer[0].id == self.id)
            tile_pair.buffer[1]
        else
            tile_pair.buffer[0];
    }

    fn orientOther(self: Tile, other: Tile, rotation: u2) Tile {
        const edge = self.edges[rotation];
        var tile = other;

        for (0..4) |_| {
            const flipped = if (rotation % 2 == 0) tile.flipHorizontal() else tile.flipVertical();
            if (tile.edges[rotation +% 2] == edge) {
                return flipped;
            }
            if (flipped.edges[rotation +% 2] == edge) {
                return tile;
            }

            tile = tile.rotateRight();
        }

        unreachable;
    }

    fn nextPieceRight(self: Tile, tiles: TileMap) Tile {
        const tile = self.getOtherTile(tiles, self.edges[1]);
        return self.orientOther(tile, 1);
    }

    fn nextPieceDown(self: Tile, tiles: TileMap) Tile {
        var tile = self.getOtherTile(tiles, self.edges[2]);
        return self.orientOther(tile, 2);
    }

    pub fn format(self: Tile, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        const inner = std.mem.eql(u8, fmt, "inner");

        if (!inner) {
            try printEdge(u10, self.edges[0], writer);
            try writer.print("\n", .{});
        }
        for (self.center, 1..) |row, i| {
            if (!inner) {
                if (((self.edges[3] >> @as(u4, @truncate(9 - i))) & 1) == 1) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try printEdge(u8, row, writer);
            if (!inner) {
                if (((self.edges[1] >> @as(u4, @truncate(i))) & 1) == 1) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
        if (!inner) {
            try printEdge(u10, @bitReverse(self.edges[2]), writer);
            try writer.print("\n", .{});
        }
    }
};

const Image = struct {
    rows: []std.DynamicBitSet,

    fn count(self: Image) usize {
        var sum: usize = 0;
        for (self.rows) |row| {
            sum += row.count();
        }
        return sum;
    }

    fn flipVertical(self: *Image) void {
        const rows = self.rows;
        for (0..rows.len / 2) |i| {
            std.mem.swap(std.DynamicBitSet, &rows[i], &rows[rows.len - i - 1]);
        }
    }

    fn rotateRight(self: *Image) void {
        var rows = self.rows;
        assert(rows.len == rows[0].capacity());

        const len_minus_one = rows.len - 1;
        for (0..rows.len / 2) |i| {
            for (i..len_minus_one - i) |j| {
                const temp1 = rows[len_minus_one - i].isSet(len_minus_one - j);
                const temp2 = rows[len_minus_one - j].isSet(i);
                const temp3 = rows[i].isSet(j);
                const temp4 = rows[j].isSet(len_minus_one - i);

                rows[i].setValue(j, temp2);
                rows[j].setValue(len_minus_one - i, temp3);
                rows[len_minus_one - i].setValue(len_minus_one - j, temp4);
                rows[len_minus_one - j].setValue(i, temp1);
            }
        }
    }

    fn getMonsters(self: Image, monster: Image, allocator: Allocator) !Image {
        var monsters = Image{ .rows = try allocator.alloc(std.DynamicBitSet, self.rows.len) };
        for (0..monsters.rows.len) |i| {
            monsters.rows[i] = try std.DynamicBitSet.initEmpty(allocator, self.rows[i].capacity());
        }

        for (0..self.rows.len - monster.rows.len) |y| {
            for (0..self.rows[0].capacity() - monster.rows[0].capacity()) |x| {
                const found = for (0..monster.rows.len) |i| {
                    var row = try self.rows[y + i].clone(allocator);
                    bitSetShr(&row, x);
                    try row.resize(monster.rows[i].capacity(), false);

                    row.setIntersection(monster.rows[i]);
                    if (!row.eql(monster.rows[i])) {
                        break false;
                    }
                } else true;
                if (!found) {
                    continue;
                }

                // Monsters may overlap (?), so do a bitwise OR to prevent double counting
                for (0..monster.rows.len) |i| {
                    var row = try monster.rows[i].clone(allocator);
                    try row.resize(self.rows[y + i].capacity(), false);
                    bitSetShl(&row, x);

                    monsters.rows[y + i].setUnion(row);
                }
            }
        }

        return monsters;
    }

    pub fn format(self: Image, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        const spaced = std.mem.eql(u8, fmt, "space");

        for (self.rows, 0..) |row, i| {
            for (0..row.capacity()) |j| {
                if (row.isSet(j)) {
                    try writer.print("#", .{});
                } else {
                    try writer.print(".", .{});
                }

                if (spaced and j % 8 == 7) {
                    try writer.print(" ", .{});
                }
            }
            try writer.print("\n", .{});

            if (spaced and i % 8 == 7) {
                try writer.print("\n", .{});
            }
        }
    }
};

fn parseEdge(comptime T: type, row: []const u8) T {
    assert(row.len == @bitSizeOf(T));

    var result: T = 0;
    for (row) |c| {
        result <<= 1;
        if (c == '#') {
            result |= 1;
        }
    }
    // return result;
    return @bitReverse(result);
}

fn printEdge(comptime T: type, edge: T, writer: anytype) !void {
    for (0..@bitSizeOf(T)) |i| {
        if (((edge >> @as(math.Log2Int(T), @truncate(i))) & 1) == 1) {
            try writer.print("#", .{});
        } else {
            try writer.print(".", .{});
        }
    }
}

fn parseInput(allocator: Allocator) ![]Tile {
    var tiles = std.ArrayList(Tile).init(allocator);
    defer tiles.deinit();

    var parts = std.mem.tokenizeSequence(u8, data, "\n\n");
    while (parts.next()) |part| {
        var lines = std.mem.tokenizeScalar(u8, part, '\n');

        const id_str = lines.next().?;
        const id = try std.fmt.parseInt(u16, id_str[5 .. id_str.len - 1], 10);

        var edges = [_]u10{parseEdge(u10, lines.peek().?)} ++ [_]u10{undefined} ** 3;
        var center = [_]u8{undefined} ** 8;
        var i: usize = 0;
        while (lines.next()) |line| {
            // Handle last line
            if (lines.peek() == null) {
                edges[2] = parseEdge(u10, line);
            } else if (i > 0) { // Skip first line
                center[i - 1] = parseEdge(u8, line[1 .. line.len - 1]);
            }

            edges[1] <<= 1;
            if (line[line.len - 1] == '#') {
                edges[1] |= 1;
            }
            edges[3] <<= 1;
            if (line[0] == '#') {
                edges[3] |= 1;
            }

            i += 1;
        }

        edges[1] = @bitReverse(edges[1]);
        edges[2] = @bitReverse(edges[2]);
        try tiles.append(Tile{ .id = id, .edges = edges, .center = center });
    }

    return tiles.toOwnedSlice();
}

fn mapEdgesToTiles(tiles: []const Tile, allocator: Allocator) !TileMap {
    var tile_map = TileMap.init(allocator);
    for (tiles) |tile| {
        for (tile.edges) |edge| {
            var tiles1 = tile_map.get(edge) orelse try std.BoundedArray(Tile, 2).init(0);
            try tiles1.append(tile);
            try tile_map.put(edge, tiles1);

            const reversed = @bitReverse(edge);
            var tiles2 = tile_map.get(reversed) orelse try std.BoundedArray(Tile, 2).init(0);
            try tiles2.append(tile);
            try tile_map.put(reversed, tiles2);
        }
    }
    return tile_map;
}

fn addTileBottomRight(rows: *std.ArrayList(std.DynamicBitSet), tile: Tile) !void {
    const top = rows.items[rows.items.len - 8 ..];
    const mask_idx = @divFloor(top[0].capacity(), @bitSizeOf(std.DynamicBitSet.MaskInt));
    const shift = @as(std.DynamicBitSet.ShiftInt, @truncate(top[0].capacity() % @bitSizeOf(std.DynamicBitSet.MaskInt)));

    for (0..8) |i| {
        try top[i].resize(top[i].capacity() + 8, false);
        top[i].unmanaged.masks[mask_idx] |= @as(std.DynamicBitSet.MaskInt, tile.center[i]) << shift;
    }
}

fn reconstructRows(left: Tile, tiles: TileMap, rows: *std.ArrayList(std.DynamicBitSet), allocator: Allocator) !void {
    for (0..8) |_| {
        try rows.append(try std.DynamicBitSet.initEmpty(allocator, 0));
    }

    try addTileBottomRight(rows, left);
    var current = left.nextPieceRight(tiles);
    const middle_type = current.tileType(tiles);
    while (current.tileType(tiles) == middle_type) : (current = current.nextPieceRight(tiles)) {
        try addTileBottomRight(rows, current);
    }
    try addTileBottomRight(rows, current);
}

fn reconstructImage(top_left: Tile, tiles: TileMap, allocator: Allocator) !Image {
    var rows = std.ArrayList(std.DynamicBitSet).init(allocator);
    defer rows.deinit();

    var prev_left: Tile = top_left;
    try reconstructRows(prev_left, tiles, &rows, allocator);
    prev_left = prev_left.nextPieceDown(tiles);
    while (prev_left.tileType(tiles) == .Edge) : (prev_left = prev_left.nextPieceDown(tiles)) {
        try reconstructRows(prev_left, tiles, &rows, allocator);
    }
    try reconstructRows(prev_left, tiles, &rows, allocator);

    return Image{ .rows = try rows.toOwnedSlice() };
}

fn bitSetShr(set: *std.DynamicBitSet, shift: usize) void {
    const unmanaged = set.unmanaged;
    const mask_size = @bitSizeOf(std.DynamicBitSet.MaskInt);
    const len = @divFloor(unmanaged.capacity() - 1, mask_size) + 1;
    const mask_shift = @divFloor(shift, mask_size);
    const bits_shift = @as(std.DynamicBitSet.ShiftInt, @truncate(shift % mask_size));

    for (0..len - mask_shift - 1) |i| {
        unmanaged.masks[i] = unmanaged.masks[i + mask_shift] >> bits_shift;
        unmanaged.masks[i] |= unmanaged.masks[i + mask_shift + 1] << (0 -% bits_shift);
    }
    unmanaged.masks[len - mask_shift - 1] = unmanaged.masks[len - 1] >> bits_shift;
    for (len - mask_shift..len) |i| {
        unmanaged.masks[i] = 0;
    }
}

fn bitSetShl(set: *std.DynamicBitSet, shift: usize) void {
    const unmanaged = set.unmanaged;
    const mask_size = @bitSizeOf(std.DynamicBitSet.MaskInt);
    const len = @divFloor(unmanaged.capacity() - 1, mask_size) + 1;
    const mask_shift = @divFloor(shift, mask_size);
    const bits_shift = @as(std.DynamicBitSet.ShiftInt, @truncate(shift % mask_size));

    var i: usize = len - 1;
    while (i > mask_shift) : (i -= 1) {
        unmanaged.masks[i] = unmanaged.masks[i - mask_shift] << bits_shift;
        unmanaged.masks[i] |= unmanaged.masks[i - mask_shift - 1] >> (0 -% bits_shift);
    }
    unmanaged.masks[mask_shift] = unmanaged.masks[0] << bits_shift;
    while (i > 0) {
        i -= 1;
        unmanaged.masks[i] = 0;
    }
}

pub fn part1() !u64 {
    const allocator = std.heap.c_allocator;

    const tiles = try parseInput(allocator);
    defer allocator.free(tiles);

    var tile_map = try mapEdgesToTiles(tiles, allocator);
    defer tile_map.deinit();

    var product: u64 = 1;
    for (tiles) |tile| {
        if (tile.tileType(tile_map) == .Corner) {
            product *= tile.id;
        }
    }
    return product;
}

pub fn part2() !usize {
    const allocator = std.heap.c_allocator;

    const tiles = try parseInput(allocator);
    defer allocator.free(tiles);

    var tile_map = try mapEdgesToTiles(tiles, allocator);
    defer tile_map.deinit();

    // Find corners
    var corners = try std.BoundedArray(Tile, 4).init(0);
    for (tiles) |tile| {
        switch (tile.tileType(tile_map)) {
            .Corner => try corners.append(tile),
            else => {},
        }
    }

    // Reconstruct image
    var top_left: Tile = corners.buffer[0];
    while (tile_map.get(top_left.edges[0]).?.len != 1 or tile_map.get(top_left.edges[3]).?.len != 1) {
        top_left = top_left.rotateRight();
    }
    var image = try reconstructImage(top_left, tile_map, allocator);
    defer {
        for (0..image.rows.len) |i| {
            image.rows[i].deinit();
        }
        allocator.free(image.rows);
    }

    // Rawr
    var monster_rows = [_]std.DynamicBitSet{
        try std.DynamicBitSet.initEmpty(allocator, 20),
        try std.DynamicBitSet.initEmpty(allocator, 20),
        try std.DynamicBitSet.initEmpty(allocator, 20),
    };
    const monster = Image{ .rows = &monster_rows };
    monster.rows[0].unmanaged.masks[0] = 0b01000000000000000000;
    monster.rows[1].unmanaged.masks[0] = 0b11100001100001100001;
    monster.rows[2].unmanaged.masks[0] = 0b00010010010010010010;

    // Find rawries
    for (0..4) |_| {
        for (0..2) |_| {
            var monsters = try image.getMonsters(monster, allocator);
            if (monsters.count() > 0) {
                return image.count() - monsters.count();
            }
            image.flipVertical();
        }
        image.rotateRight();
    }
    unreachable;
}
