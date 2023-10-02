const std = @import("std");
const data = @embedFile("16.txt");

const OrRange = struct {
    min1: u64,
    max1: u64,
    min2: u64,
    max2: u64,

    fn contains(self: OrRange, n: u64) bool {
        return (n >= self.min1 and n <= self.max1) or (n >= self.min2 and n <= self.max2);
    }
};

const Field = struct {
    name: []const u8,
    range: OrRange,
};

const Ticket = []const u64;

fn parseOrRange(range: []const u8) !OrRange {
    var ranges = std.mem.tokenizeSequence(u8, range, " or ");
    var range1 = std.mem.tokenizeSequence(u8, ranges.next().?, "-");
    var range2 = std.mem.tokenizeSequence(u8, ranges.next().?, "-");
    return OrRange{
        .min1 = try std.fmt.parseInt(u64, range1.next().?, 10),
        .max1 = try std.fmt.parseInt(u64, range1.next().?, 10),
        .min2 = try std.fmt.parseInt(u64, range2.next().?, 10),
        .max2 = try std.fmt.parseInt(u64, range2.next().?, 10),
    };
}

fn parseField(field: []const u8) !Field {
    var parts = std.mem.tokenizeSequence(u8, field, ": ");
    return Field{
        .name = parts.next().?,
        .range = try parseOrRange(parts.next().?),
    };
}

fn parseTicket(ticket_str: []const u8) !Ticket {
    var ticket = std.ArrayList(u64).init(std.heap.c_allocator);
    defer ticket.deinit();

    var fields = std.mem.tokenizeScalar(u8, ticket_str, ',');
    while (fields.next()) |field| {
        try ticket.append(try std.fmt.parseInt(u64, field, 10));
    }

    return ticket.toOwnedSlice();
}

fn parseInput() !struct { fields: std.ArrayList(Field), ticket: Ticket, nearby: std.ArrayList(Ticket) } {
    var parts = std.mem.tokenizeSequence(u8, data, "\n\n");

    var fields = std.ArrayList(Field).init(std.heap.c_allocator);
    var fields_lines = std.mem.tokenizeScalar(u8, parts.next().?, '\n');
    while (fields_lines.next()) |line| {
        try fields.append(try parseField(line));
    }

    const ticket = try parseTicket(parts.next().?[13..]);

    var nearby = std.ArrayList([]const u64).init(std.heap.c_allocator);
    var nearby_lines = std.mem.tokenizeScalar(u8, parts.next().?[16..], '\n');
    while (nearby_lines.next()) |line| {
        try nearby.append(try parseTicket(line));
    }

    return .{
        .fields = fields,
        .ticket = ticket,
        .nearby = nearby,
    };
}

pub fn part1() !u64 {
    const input = try parseInput();
    const fields = input.fields.items;
    const nearby = input.nearby.items;
    defer {
        input.fields.deinit();
        std.heap.c_allocator.free(input.ticket);
        for (nearby) |t| {
            std.heap.c_allocator.free(t);
        }
        input.nearby.deinit();
    }

    var error_rate: u64 = 0;
    for (nearby) |ticket| {
        for (ticket) |value| {
            var valid = false;
            for (fields) |f| {
                if (f.range.contains(value)) {
                    valid = true;
                    break;
                }
            }
            if (!valid) {
                error_rate += value;
            }
        }
    }
    return error_rate;
}

pub fn part2() !u64 {
    const input = try parseInput();
    const fields = input.fields;
    const ticket = input.ticket;
    var nearby = input.nearby;
    defer {
        input.fields.deinit();
        std.heap.c_allocator.free(input.ticket);
        for (nearby.items) |t| {
            std.heap.c_allocator.free(t);
        }
        input.nearby.deinit();
    }

    // Remove invalid tickets
    var i: usize = 0;
    while (i < nearby.items.len) {
        const t = nearby.items[i];
        for (t) |value| {
            var valid = false;
            for (fields.items) |f| {
                if (f.range.contains(value)) {
                    valid = true;
                    break;
                }
            }

            if (!valid) {
                _ = nearby.swapRemove(i);
                break;
            }
        } else {
            i += 1;
        }
    }
    try nearby.append(ticket);

    // Order fields
    i = 0;
    var field_order = try std.heap.c_allocator.alloc(struct { std.ArrayList(Field), usize }, ticket.len);
    while (i < ticket.len) : (i += 1) {
        var valid_fields = std.ArrayList(Field).init(std.heap.c_allocator);
        try valid_fields.resize(fields.items.len);
        @memcpy(valid_fields.items, fields.items);
        defer valid_fields.deinit();

        // Remove fields that don't match
        for (nearby.items) |t| {
            const value = t[i];
            var j: usize = 0;
            while (j < valid_fields.items.len) {
                const f = valid_fields.items[j];
                if (f.range.contains(value)) {
                    j += 1;
                } else {
                    _ = valid_fields.swapRemove(j);
                }
            }

            // No need to continue if only one field left
            if (valid_fields.items.len == 1) {
                break;
            }
        }

        const idx = valid_fields.items.len - 1;
        field_order[idx] = .{ try valid_fields.clone(), i };
    }

    // Multiply departure fields together
    i = 0;
    var product: u64 = 1;
    for (field_order) |f| {
        const field = f[0].items[0];
        const idx = f[1];

        if (std.mem.eql(u8, field.name[0..3], "dep")) {
            product *= ticket[idx];
        }

        // Remove field
        var j = i + 1;
        while (j < field_order.len) : (j += 1) {
            const set = field_order[j][0].items;
            var field_idx: usize = for (0..set.len) |k| {
                if (std.mem.eql(u8, set[k].name, field.name)) {
                    break k;
                }
            } else unreachable;
            _ = field_order[j][0].swapRemove(field_idx);
        }

        i += 1;
    }

    return product;
}
