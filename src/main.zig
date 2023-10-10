const std = @import("std");
const fmt = std.fmt;
const day = @import("25.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const start_time = std.time.nanoTimestamp();

    try stdout.print("Answer: {}\n", .{try day.part1()});

    const nanoseconds = @as(i64, @truncate(std.time.nanoTimestamp() - start_time));
    try stdout.print("Time taken: {}\n", .{fmt.fmtDurationSigned(nanoseconds)});

    try bw.flush();
}
