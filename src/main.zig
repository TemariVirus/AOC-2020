const std = @import("std");
const day = @import("11.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const start_t = std.time.nanoTimestamp();

    try stdout.print("Answer: {}\n", .{try day.part2()});

    const time = std.time.nanoTimestamp() - start_t;
    if (time >= 1_000_000) {
        try stdout.print("Time taken: {}ms\n", .{@divFloor(time, 1_000_000)});
    } else {
        try stdout.print("Time taken: {}us\n", .{@divFloor(time, 1_000)});
    }

    try bw.flush();
}
