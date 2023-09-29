const std = @import("std");
const data = @embedFile("08.txt");

const Operation = enum(u2) {
    Nop,
    Acc,
    Jmp,
};
const Instruction = union(Operation) {
    Nop: i62,
    Acc: i62,
    Jmp: i62,
};

fn parseInput() ![]Instruction {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var instructions = std.ArrayList(Instruction).init(gpa.allocator());
    defer instructions.deinit();

    while (lines.next()) |line| {
        const op = line[0..3];
        const arg = line[4..];

        if (std.mem.eql(u8, op, "nop")) {
            try instructions.append(Instruction{ .Nop = try std.fmt.parseInt(i62, arg, 10) });
        } else if (std.mem.eql(u8, op, "acc")) {
            try instructions.append(Instruction{ .Acc = try std.fmt.parseInt(i62, arg, 10) });
        } else if (std.mem.eql(u8, op, "jmp")) {
            try instructions.append(Instruction{ .Jmp = try std.fmt.parseInt(i62, arg, 10) });
        } else {
            unreachable;
        }
    }

    return instructions.toOwnedSlice();
}

pub fn part1() !i64 {
    const instructions = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var ran = try std.bit_set.DynamicBitSet.initEmpty(gpa.allocator(), instructions.len);
    defer ran.deinit();

    var i: usize = 0;
    var acc: i64 = 0;
    while (i < instructions.len) : (i += 1) {
        if (ran.isSet(i)) {
            break;
        }
        ran.set(i);

        switch (instructions[i]) {
            .Nop => continue,
            .Acc => acc += @as(i64, instructions[i].Acc),
            .Jmp => i +%= @as(usize, @bitCast(@as(isize, @intCast(instructions[i].Jmp)))) - 1,
        }
    }

    return acc;
}

pub fn part2() !i64 {
    const instructions = try parseInput();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var ran = try std.bit_set.DynamicBitSet.initEmpty(gpa.allocator(), instructions.len);
    defer ran.deinit();
    var empty = try std.bit_set.DynamicBitSet.initEmpty(gpa.allocator(), instructions.len);
    defer empty.deinit();

    var i: usize = 0;
    while (i < instructions.len) : (i += 1) {
        switch (instructions[i]) {
            .Nop => |v| instructions[i] = Instruction{ .Jmp = v },
            .Jmp => |v| instructions[i] = Instruction{ .Nop = v },
            .Acc => continue,
        }

        var pc: usize = 0;
        var acc: i64 = 0;
        ran.setIntersection(empty);
        while (pc < instructions.len) : (pc += 1) {
            if (ran.isSet(pc)) {
                break;
            }
            ran.set(pc);

            switch (instructions[pc]) {
                .Nop => continue,
                .Acc => acc += @as(i64, instructions[pc].Acc),
                .Jmp => pc +%= @as(usize, @bitCast(@as(isize, @intCast(instructions[pc].Jmp)))) - 1,
            }
        }

        if (pc == instructions.len) {
            return acc;
        }

        switch (instructions[i]) {
            .Nop => |v| instructions[i] = Instruction{ .Jmp = v },
            .Jmp => |v| instructions[i] = Instruction{ .Nop = v },
            .Acc => unreachable,
        }
    }

    unreachable;
}
