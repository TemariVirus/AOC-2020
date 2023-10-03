const std = @import("std");
const assert = std.debug.assert;
const data = @embedFile("19.txt"); // Longest message is 88 bits long

const Allocator = std.mem.Allocator;
fn HashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const RuleArray = std.BoundedArray(u8, 2); // Make larger as needed
const RuleType = enum {
    Letter,
    Single,
    Double,
};
const Rule = union(RuleType) {
    Letter: u1,
    Single: RuleArray,
    Double: struct { RuleArray, RuleArray },

    // fn match(self: *Rule, rules: []Rule, msg: Message) u8 {
    //     return switch (self) {
    //         .Letter => if (@as(u1, @truncate(msg)) == self.Letter) 1 else 0,
    //         .Single => self.matchSingle(rules, msg),
    //         .Double => {
    //             const rule1 = Rule{ .Single = self.Double[0] };
    //             const rule2 = Rule{ .Single = self.Double[1] };

    //             const shift = rule1.matchSingle(rules, msg);
    //             if (shift != 0) {
    //                 return shift;
    //             }
    //             return rule2.matchSingle(rules, msg);
    //         },
    //     };
    // }

    // fn matchSingle(self: Rule, rules: []Rule, msg: Message) u8 {
    //     _ = msg;
    //     _ = rules;
    //     assert(self == .Single);

    //     for (self.Single.buffer) |idx| {
    //         _ = idx;
    //     }

    //     return false;
    // }

    fn possibleMatches(self: Rule, rules: []Rule, allocator: Allocator) anyerror![]Message {
        var matches = std.ArrayList(Message).init(allocator);
        try self.addMatches(rules, allocator, &matches);
        return matches.toOwnedSlice();
    }

    fn addMatches(self: Rule, rules: []Rule, allocator: Allocator, matches: *std.ArrayList(Message)) !void {
        if (self == .Letter) {
            const msg = Message{ .value = self.Letter, .len = 1 };
            try matches.append(msg);
            return;
        }
        if (self == .Double) {
            const rule1 = Rule{ .Single = self.Double[0] };
            const rule2 = Rule{ .Single = self.Double[1] };
            try rule1.addMatches(rules, allocator, matches);
            try rule2.addMatches(rules, allocator, matches);
            return;
        }

        const single = self.Single;
        const start = matches.items.len;

        try rules[single.buffer[0]].addMatches(rules, allocator, matches);
        for (self.Single.slice()[1..]) |i| {
            const rule = rules[i];
            var matches2 = try rule.possibleMatches(rules, allocator);
            defer allocator.free(matches2);

            try matches.ensureTotalCapacity(start + (matches.items.len - start) * matches2.len);
            const matches1 = matches.items[start..];

            // Update in-place
            for (matches1) |m1| {
                for (matches2[1..]) |m2| {
                    try matches.append(m1.append(m2));
                }
            }
            // Update matches1
            const m2 = matches2[0];
            for (matches1, 0..) |m1, j| {
                matches1[j] = m1.append(m2);
            }
        }
    }
};

const Message = packed struct {
    value: u96,
    len: u7,

    fn append(self: Message, other: Message) Message {
        return .{ .value = self.value << other.len | other.value, .len = self.len + other.len };
    }
};

fn parseInput(allocator: Allocator) !struct { []Rule, []Message } {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var parts = std.mem.tokenizeSequence(u8, line, ": ");

        const index = try std.fmt.parseInt(u8, parts.next().?, 10);

        var letter: u1 = undefined;
        var rules1 = try RuleArray.init(0);
        var rules2 = try RuleArray.init(0);

        var subrules = &rules1;
        parts = std.mem.tokenizeSequence(u8, parts.next().?, " ");
        while (parts.next()) |p| {
            if (p[0] == '"') {
                letter = if (p[1] == 'a') 0 else 1;
                continue;
            }

            if (p[0] == '|') {
                subrules = &rules2;
                continue;
            }

            try subrules.append(try std.fmt.parseInt(u8, p, 10));
        }

        try rules.resize(@max(index + 1, rules.items.len));
        rules.items[index] = if (rules1.len == 0)
            Rule{ .Letter = letter }
        else if (rules2.len == 0)
            Rule{ .Single = rules1 }
        else
            Rule{ .Double = .{ rules1, rules2 } };
    }

    var msgs = std.ArrayList(Message).init(allocator);
    defer msgs.deinit();
    while (lines.next()) |line| {
        var msg = Message{ .value = 0, .len = @as(u7, @truncate(line.len)) };
        for (line) |c| {
            msg.value <<= 1;
            if (c == 'b') {
                msg.value |= 1;
            }
        }
        try msgs.append(msg);
    }

    return .{ try rules.toOwnedSlice(), try msgs.toOwnedSlice() };
}

pub fn part1() !u64 {
    const allocator = std.heap.c_allocator;

    var input = try parseInput(allocator);
    const rules = input[0];
    defer allocator.free(rules);
    const msgs = input[1];
    defer allocator.free(msgs);

    const values = try rules[0].possibleMatches(rules, allocator);
    defer allocator.free(values);

    var value_set = HashSet(Message).init(allocator);
    for (values) |v| {
        try value_set.put(v, {});
    }
    defer value_set.deinit();

    var valid: u64 = 0;
    for (msgs) |m| {
        if (value_set.contains(m)) {
            valid += 1;
        }
    }
    return valid;
}

// Rule 31 and 42 are always the same in length, and rule 0 is any number
// of 42s (min 2) followed by a smaller number of 31s (min 1)
pub fn part2() !u64 {
    const allocator = std.heap.c_allocator;

    var input = try parseInput(allocator);
    const rules = input[0];
    defer allocator.free(rules);
    const msgs = input[1];
    defer allocator.free(msgs);

    const values_31 = try rules[31].possibleMatches(rules, allocator);
    const bit_len = @as(u6, @truncate(values_31[0].len));
    var set_31 = try std.DynamicBitSet.initEmpty(allocator, @as(usize, 1) << bit_len);
    for (values_31) |v| {
        set_31.set(@as(usize, @truncate(v.value)));
    }
    allocator.free(values_31);
    defer set_31.deinit();

    const values_42 = try rules[42].possibleMatches(rules, allocator);
    var set_42 = try std.DynamicBitSet.initEmpty(allocator, @as(usize, 1) << bit_len);
    for (values_42) |v| {
        set_42.set(@as(usize, @truncate(v.value)));
    }
    allocator.free(values_42);
    defer set_42.deinit();

    var valid: u64 = 0;
    const bit_mask = (@as(u96, 1) << bit_len) - 1;
    for (msgs) |m| {
        if (m.len % bit_len != 0) {
            continue;
        }

        var value = m.value;
        var len = m.len;

        var count_31: i32 = 0;
        while (len > 0) : (len -= bit_len) {
            if (!set_31.isSet(@as(usize, @truncate(value & bit_mask)))) {
                break;
            }
            count_31 += 1;
            value >>= bit_len;
        }

        const count_42 = len / bit_len;
        if (count_31 < 1 or count_42 < 2 or count_31 >= count_42) {
            continue;
        }

        while (len > 0) : (len -= bit_len) {
            if (!set_42.isSet(@as(usize, @truncate(value & bit_mask)))) {
                break;
            }
            value >>= bit_len;
        }

        if (len == 0) {
            valid += 1;
        }
    }
    return valid;
}
