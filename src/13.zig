const std = @import("std");
const data = @embedFile("13.txt");

fn parseInput() !struct { time: u64, buses: []?u64 } {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    const time = try std.fmt.parseInt(u64, lines.next().?, 10);

    var buses_str = std.mem.tokenizeScalar(u8, lines.next().?, ',');
    var buses = std.ArrayList(?u64).init(std.heap.c_allocator);
    defer buses.deinit();

    while (buses_str.next()) |s| {
        if (std.mem.eql(u8, s, "x")) {
            try buses.append(null);
            continue;
        }

        const bus = try std.fmt.parseInt(u64, s, 10);
        try buses.append(bus);
    }

    return .{ .time = time, .buses = try buses.toOwnedSlice() };
}

pub fn part1() !u64 {
    const input = try parseInput();
    const timestamp = input.time;
    const buses = input.buses;
    defer std.heap.c_allocator.free(buses);

    var best_bus: u64 = undefined;
    var best_time = @as(u64, (1 << 64) - 1);
    for (buses) |b| {
        if (b == null) {
            continue;
        }

        const bus = b.?;
        const time = (bus - (timestamp % bus)) % bus;
        if (time < best_time) {
            best_bus = bus;
            best_time = time;
        }
    }

    return best_bus * best_time;
}

pub fn part2() !u64 {
    const buses = (try parseInput()).buses;
    defer std.heap.c_allocator.free(buses);

    var time: u64 = 0;
    var step: u64 = 1;
    for (buses) |b| {
        if (b == null) {
            time += 1;
            continue;
        }

        const bus = b.?;
        while (time % bus != 0) {
            time += step;
        }
        time += 1;
        step *= bus;
    }

    return time - buses.len;
}
