const std = @import("std");
const data = @embedFile("23.txt");

const Allocator = std.mem.Allocator;

const FixedLinkedList = struct {
    next: []usize,
    data: []u32,
};

fn parseInput(allocator: Allocator) !FixedLinkedList {
    var values = try allocator.alloc(u32, data.len);
    var next = try allocator.alloc(usize, data.len);
    for (0..data.len) |i| {
        values[i] = data[i] - '1';
        next[i] = (i + 1) % next.len;
    }
    return FixedLinkedList{ .next = next, .data = values };
}

fn mixCups(list: FixedLinkedList, current_idx: usize) void {
    const cup1_idx = list.next[current_idx];
    const cup2_idx = list.next[cup1_idx];
    const cup3_idx = list.next[cup2_idx];

    const current = list.data[current_idx];
    const cup1 = list.data[cup1_idx];
    const cup2 = list.data[cup2_idx];
    const cup3 = list.data[cup3_idx];

    const dest = for (1..5) |i| {
        const dest = (current + list.data.len - i) % list.data.len;
        if (dest != cup1 and dest != cup2 and dest != cup3) {
            break dest;
        }
    } else unreachable;
    const dest_idx = for (0..9) |i| {
        if (list.data[i] == dest) {
            break i;
        }
    } else dest;

    list.next[current_idx] = list.next[cup3_idx];
    list.next[cup3_idx] = list.next[dest_idx];
    list.next[dest_idx] = cup1_idx;
}

fn collectCups(cups: FixedLinkedList) [8]u8 {
    var idx = for (0..cups.data.len) |i| {
        if (cups.data[i] == 0) {
            break i;
        }
    } else unreachable;

    var arranged = [_]u8{undefined} ** 8;
    for (0..arranged.len) |i| {
        idx = cups.next[idx];
        arranged[i] = @as(u8, @truncate(cups.data[idx])) + '1';
    }
    return arranged;
}

pub fn part1() ![8]u8 {
    const allocator = std.heap.c_allocator;

    const cups = try parseInput(allocator);
    defer allocator.free(cups.next);
    defer allocator.free(cups.data);

    var current_idx: usize = 0;
    for (0..100) |_| {
        mixCups(cups, current_idx);
        current_idx = cups.next[current_idx];
    }
    return collectCups(cups);
}

pub fn part2() !u64 {
    const allocator = std.heap.c_allocator;

    var cups = try parseInput(allocator);
    defer allocator.free(cups.next);
    defer allocator.free(cups.data);

    allocator.free(cups.next);
    cups.next = try allocator.alloc(usize, 1_000_000);
    for (0..cups.next.len) |i| {
        cups.next[i] = (i + 1) % cups.next.len;
    }

    var million = try allocator.alloc(u32, 1_000_000);
    for (0..cups.data.len) |i| {
        million[i] = cups.data[i];
    }
    for (cups.data.len..1_000_000) |i| {
        million[i] = @as(u32, @truncate(i));
    }
    allocator.free(cups.data);
    cups.data = million;

    var current_idx: usize = 0;
    for (0..10_000_000) |_| {
        mixCups(cups, current_idx);
        current_idx = cups.next[current_idx];
    }

    const one_idx = for (0..cups.data.len) |i| {
        if (cups.data[i] == 0) {
            break i;
        }
    } else unreachable;
    const first_idx = cups.next[one_idx];
    const second_idx = cups.next[first_idx];

    const first: u64 = cups.data[first_idx] + 1;
    const second: u64 = cups.data[second_idx] + 1;
    return first * second;
}
