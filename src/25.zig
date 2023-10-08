const std = @import("std");
const data = @embedFile("25.txt");

const mod: u64 = 20201227;

fn findLoopSize(key: u64) u64 {
    var number: u64 = 1;
    for (0..mod) |i| {
        if (number == key) {
            return @as(u64, @truncate(i));
        }
        number = (number * 7) % mod;
    } else unreachable;
}

fn moduloPower(base: u64, power: u64) u64 {
    if (power == 0) {
        return 1;
    }
    if (power == 1) {
        return base;
    }
    if (power % 2 == 0) {
        return moduloPower((base * base) % mod, power / 2);
    }
    return (base * moduloPower(base, power - 1)) % mod;
}

pub fn part1() !u64 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    const card_key = try std.fmt.parseInt(u64, lines.next().?, 10);
    const door_key = try std.fmt.parseInt(u64, lines.next().?, 10);
    const card_loop_size = findLoopSize(card_key);

    return moduloPower(door_key, card_loop_size);
}
