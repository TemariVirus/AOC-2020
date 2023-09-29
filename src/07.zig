const std = @import("std");
const regex = @import("regex").Regex;
const data = @embedFile("07.txt");

const Bag = struct {
    contains: [][]const u8,
    counts: []const i64,
};

fn parseInput() !std.StringHashMap(Bag) {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var bag_expr = try regex.compile(gpa.allocator(), "(\\d+) (\\w+ \\w+) bags?");
    defer bag_expr.deinit();

    var rules = std.StringHashMap(Bag).init(gpa.allocator());

    while (lines.next()) |line| {
        var parts = std.mem.tokenizeSequence(u8, line[0 .. line.len - 1], " contain ");

        var name = parts.next().?;
        name = name[0 .. name.len - 5];

        var contains = std.ArrayList([]const u8).init(gpa.allocator());
        defer contains.deinit();
        var counts = std.ArrayList(i64).init(gpa.allocator());
        defer counts.deinit();

        var bags = std.mem.tokenizeSequence(u8, parts.next().?, ", ");
        while (bags.next()) |bag| {
            if (std.mem.eql(u8, bag, "no other bags")) {
                break;
            }

            const slots = (try bag_expr.captures(bag)).?.slots[2..];
            try counts.append(try std.fmt.parseInt(i64, bag[slots[0].?..slots[1].?], 10));
            try contains.append(bag[slots[2].?..slots[3].?]);
        }

        try rules.put(name, Bag{ .contains = try contains.toOwnedSlice(), .counts = try counts.toOwnedSlice() });
    }

    return rules;
}

fn bagContains(parent: []const u8, child: []const u8, rules: *std.StringHashMap(Bag), cache: *std.StringHashMap(bool)) !bool {
    if (std.mem.eql(u8, parent, child)) {
        return true;
    }

    const contains = cache.get(parent);
    if (contains != null) {
        return contains.?;
    }

    try cache.put(parent, false);

    for (rules.get(parent).?.contains) |bag| {
        const contain = try bagContains(bag, child, rules, cache);
        if (contain) {
            try cache.put(parent, true);
            return true;
        }
    }

    return false;
}

pub fn part1() !i64 {
    var rules = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var cache = std.StringHashMap(bool).init(gpa.allocator());
    defer cache.deinit();

    var count: i64 = 0;
    var keys = rules.keyIterator();
    while (keys.next()) |k| {
        if (std.mem.eql(u8, k.*, "shiny gold")) {
            continue;
        }

        if (try bagContains(k.*, "shiny gold", &rules, &cache)) {
            count += 1;
        }
    }

    return count;
}

fn bagCount(bag: []const u8, rules: *std.StringHashMap(Bag), cache: *std.StringHashMap(i64)) !i64 {
    const count = cache.get(bag);
    if (count != null) {
        return count.?;
    }

    var total: i64 = 0;
    const rule = rules.get(bag).?;
    for (rule.contains, 0..) |child, i| {
        total += rule.counts[i] * (try bagCount(child, rules, cache) + 1);
    }

    try cache.put(bag, total);
    return total;
}

pub fn part2() !i64 {
    var rules = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var cache = std.StringHashMap(i64).init(gpa.allocator());
    defer cache.deinit();

    return try bagCount("shiny gold", &rules, &cache);
}
