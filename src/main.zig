const std = @import("std");
const day = @import("20.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const start_t = std.time.nanoTimestamp();

    try stdout.print("Answer: {}\n", .{try day.part2()});

    const time: f32 = @floatFromInt(std.time.nanoTimestamp() - start_t);
    if (time >= 1_000_000) {
        try stdout.print("Time taken: {d:.3}ms\n", .{time / 1_000_000});
    } else {
        try stdout.print("Time taken: {d:.3}μs\n", .{time / 1_000});
    }

    try bw.flush();
}
