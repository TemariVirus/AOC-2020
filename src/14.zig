const std = @import("std");
const regex = @import("regex").Regex;
const data = @embedFile("14.txt");

const InstructionType = enum {
    Mask,
    Mem,
};
const Instruction = union(InstructionType) {
    Mask: struct { set: u36, unset: u36 },
    Mem: struct { address: u36, value: u36 },
};

fn parseInput() ![]Instruction {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var instructions = std.ArrayList(Instruction).init(std.heap.c_allocator);
    defer instructions.deinit();

    var mask_expr = try regex.compile(std.heap.c_allocator, "mask = ([X10]+)");
    defer mask_expr.deinit();
    var mem_expr = try regex.compile(std.heap.c_allocator, "mem\\[(\\d+)\\] = (\\d+)");
    defer mem_expr.deinit();

    while (lines.next()) |line| {
        if (std.mem.eql(u8, line[0..3], "mem")) {
            const slots = (try regex.captures(&mem_expr, line)).?.slots[2..];
            const address = try std.fmt.parseInt(u36, line[slots[0].?..slots[1].?], 10);
            const value = try std.fmt.parseInt(u36, line[slots[2].?..slots[3].?], 10);
            try instructions.append(Instruction{ .Mem = .{ .address = address, .value = value } });
        } else {
            const slots = (try regex.captures(&mask_expr, line)).?.slots[2..];
            const mask = line[slots[0].?..slots[1].?];

            var set: u36 = 0;
            var unset: u36 = 0;
            for (mask) |c| {
                set <<= 1;
                unset <<= 1;
                switch (c) {
                    '1' => set |= 1,
                    '0' => unset |= 1,
                    'X' => {},
                    else => unreachable,
                }
            }

            try instructions.append(Instruction{ .Mask = .{ .set = set, .unset = unset } });
        }
    }

    return instructions.toOwnedSlice();
}

pub fn part1() !u64 {
    const instructions = try parseInput();
    defer std.heap.c_allocator.free(instructions);

    var memory = std.AutoHashMap(u36, u36).init(std.heap.c_allocator);
    defer memory.deinit();

    var set: u36 = undefined;
    var unset: u36 = undefined;
    for (instructions) |instruct| {
        switch (instruct) {
            .Mask => |mask| {
                set = mask.set;
                unset = mask.unset;
            },
            .Mem => |mem| {
                const address = mem.address;
                const value = (mem.value | set) & ~unset;
                try memory.put(address, value);
            },
        }
    }

    var sum: u64 = 0;
    var values = memory.valueIterator();
    while (values.next()) |value| {
        sum += value.*;
    }
    return sum;
}

pub fn part2() !u64 {
    const instructions = try parseInput();
    defer std.heap.c_allocator.free(instructions);

    var memory_writes = std.ArrayList(struct { set: u36, float: u36, value: u36 }).init(std.heap.c_allocator);
    defer memory_writes.deinit();

    var set: u36 = undefined;
    var float: u36 = undefined;
    for (instructions) |instruct| {
        switch (instruct) {
            .Mask => |mask| {
                set = mask.set;
                float = ~(mask.set | mask.unset);
            },
            .Mem => |mem| {
                const s = (mem.address | set) & ~float; // Non-floating address bits

                var i: usize = 0;
                while (i < memory_writes.items.len) {
                    const mem2 = &memory_writes.items[i];

                    // No overlap of non-floating bits
                    if ((s ^ mem2.set) & ~(float | mem2.float) != 0) {
                        i += 1;
                        continue;
                    }

                    // New one completely covers the old one
                    if (float & mem2.float == mem2.float) {
                        _ = memory_writes.swapRemove(i);
                        continue;
                    }

                    // Partial cover
                    var overriden_set = std.bit_set.IntegerBitSet(36).initEmpty();
                    overriden_set.mask = mem2.float & ~float;
                    const bit_idx = @as(u6, @truncate(overriden_set.findFirstSet().?));
                    const mask = @as(u36, 1) << bit_idx;

                    // Set first colliding bit to opposite of new one to resolve collision
                    mem2.float ^= mask;
                    mem2.set |= ~s & mask;

                    // Add new one with the colliding bit set to the same as the old one (deal with it later)
                    try memory_writes.append(.{ .set = (mem2.set & ~mask) | (s & mask), .float = mem2.float, .value = mem2.value });
                    i += 1;
                }
                try memory_writes.append(.{ .set = s, .float = float, .value = mem.value });
            },
        }
    }

    var sum: u64 = 0;
    for (memory_writes.items) |m| {
        var f = std.bit_set.IntegerBitSet(36).initEmpty();
        f.mask = m.float;
        sum += m.value * (@as(u64, 1) << @as(u6, @truncate(f.count())));
    }
    return sum;
}
