const std = @import("std");
const mem = std.mem;
const data = @embedFile("22.txt");

const Allocator = std.mem.Allocator;
const Queue = std.RingBuffer;

fn parseInput(allocator: Allocator) ![2]Queue {
    var players = mem.tokenizeSequence(u8, data, "\n\n");

    var player1_cards = std.ArrayList(u8).init(allocator);
    defer player1_cards.deinit();
    var lines = mem.tokenizeScalar(u8, players.next().?, '\n');
    _ = lines.next(); // skip first line
    while (lines.next()) |line| {
        const number = try std.fmt.parseInt(u8, line, 10);
        try player1_cards.append(number);
    }
    var player1 = try Queue.init(allocator, player1_cards.items.len * 2);
    for (player1_cards.items) |card| {
        try player1.write(card);
    }

    var player2_cards = std.ArrayList(u8).init(allocator);
    defer player2_cards.deinit();
    lines = mem.tokenizeScalar(u8, players.next().?, '\n');
    _ = lines.next(); // skip first line
    while (lines.next()) |line| {
        const number = try std.fmt.parseInt(u8, line, 10);
        try player2_cards.append(number);
    }
    var player2 = try Queue.init(allocator, player2_cards.items.len * 2);
    for (player2_cards.items) |card| {
        try player2.write(card);
    }

    return [2]Queue{ player1, player2 };
}

fn combatRecurse(allocator: Allocator, players: *[2]Queue) !usize {
    var seen = std.ArrayList([2][]u8).init(allocator);
    defer {
        for (seen.items) |item| {
            allocator.free(item[0]);
            allocator.free(item[1]);
        }
        seen.deinit();
    }

    while (!players[0].isEmpty() and !players[1].isEmpty()) {
        const player1_cards = try allocator.alloc(u8, players[0].len());
        const player1_slices = players[0].sliceAt(players[0].read_index, player1_cards.len);
        @memcpy(player1_cards[0..player1_slices.first.len], player1_slices.first);
        @memcpy(player1_cards[player1_slices.first.len..], player1_slices.second);

        const player2_cards = try allocator.alloc(u8, players[1].len());
        const player2_slices = players[1].sliceAt(players[1].read_index, player2_cards.len);
        @memcpy(player2_cards[0..player2_slices.first.len], player2_slices.first);
        @memcpy(player2_cards[player2_slices.first.len..], player2_slices.second);

        for (seen.items) |round| {
            if (mem.eql(u8, round[0], player1_cards) and mem.eql(u8, round[1], player2_cards)) {
                return 0;
            }
        }
        try seen.append([2][]u8{ player1_cards, player2_cards });

        const cards = [2]u8{ players[0].read().?, players[1].read().? };
        var winner: usize = if (cards[0] > cards[1]) 0 else 1;

        if (players[0].len() >= cards[0] and players[1].len() >= cards[1]) {
            const new_capacity = cards[0] + cards[1];
            var subgame = [2]Queue{
                try Queue.init(allocator, new_capacity),
                try Queue.init(allocator, new_capacity),
            };
            defer {
                subgame[0].deinit(allocator);
                subgame[1].deinit(allocator);
            }

            for (0..2) |i| {
                const player = players[i];
                const bytes = player.sliceAt(player.read_index, cards[i]);
                try subgame[i].writeSlice(bytes.first);
                try subgame[i].writeSlice(bytes.second);
            }
            winner = try combatRecurse(allocator, &subgame);
        }

        try players[winner].write(cards[winner]);
        try players[winner].write(cards[1 - winner]);
    }

    return if (players[0].isEmpty()) 1 else 0;
}

pub fn part1() !usize {
    const allocator = std.heap.c_allocator;

    var players = try parseInput(allocator);
    defer {
        players[0].deinit(allocator);
        players[1].deinit(allocator);
    }

    while (!players[0].isEmpty() and !players[1].isEmpty()) {
        const cards = [2]u8{ players[0].read().?, players[1].read().? };
        const winner: usize = if (cards[0] > cards[1]) 0 else 1;
        try players[winner].write(cards[winner]);
        try players[winner].write(cards[1 - winner]);
    }

    var winner = if (players[0].isEmpty()) players[1] else players[0];
    var score: usize = 0;
    while (winner.read()) |card| {
        score += card * (winner.len() + 1);
    }
    return score;
}

pub fn part2() !usize {
    const allocator = std.heap.c_allocator;

    var players = try parseInput(allocator);
    defer {
        players[0].deinit(allocator);
        players[1].deinit(allocator);
    }

    const winner_idx = try combatRecurse(allocator, &players);
    var winner = players[winner_idx];
    var score: usize = 0;
    while (winner.read()) |card| {
        score += card * (winner.len() + 1);
    }
    return score;
}
