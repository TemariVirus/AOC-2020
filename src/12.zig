const std = @import("std");
const data = @embedFile("12.txt");

const ActionType = enum(u8) {
    North = 0,
    East = 1,
    South = 2,
    West = 3,
    Left,
    Right,
    Forward,
};
const Action = struct {
    type: ActionType,
    value: u32,
};

const Vector2 = struct {
    x: i32,
    y: i32,

    fn add(self: Vector2, other: Vector2) Vector2 {
        return Vector2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    fn mul(self: Vector2, scalar: u32) Vector2 {
        return Vector2{ .x = self.x * @as(i32, @bitCast(scalar)), .y = self.y * @as(i32, @bitCast(scalar)) };
    }

    fn matMul(self: Vector2, mat: Matrix2x2) Vector2 {
        return Vector2{
            .x = self.x * mat[0].x + self.y * mat[1].x,
            .y = self.x * mat[0].y + self.y * mat[1].y,
        };
    }

    fn manhattanDistance(self: Vector2, other: Vector2) u64 {
        return @abs(self.x - other.x) + @abs(self.y - other.y);
    }
};

const Matrix2x2 = [2]Vector2;

const directions = [_]Vector2{
    Vector2{ .x = 0, .y = 1 },
    Vector2{ .x = 1, .y = 0 },
    Vector2{ .x = 0, .y = -1 },
    Vector2{ .x = -1, .y = 0 },
};

const rotations = [_]Matrix2x2{
    Matrix2x2{ Vector2{ .x = 1, .y = 0 }, Vector2{ .x = 0, .y = 1 } },
    Matrix2x2{ Vector2{ .x = 0, .y = -1 }, Vector2{ .x = 1, .y = 0 } },
    Matrix2x2{ Vector2{ .x = -1, .y = 0 }, Vector2{ .x = 0, .y = -1 } },
    Matrix2x2{ Vector2{ .x = 0, .y = 1 }, Vector2{ .x = -1, .y = 0 } },
};

fn parseInput() ![]const Action {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var actions = std.ArrayList(Action).init(std.heap.c_allocator);
    defer actions.deinit();

    while (lines.next()) |line| {
        var action = Action{ .type = undefined, .value = undefined };
        switch (line[0]) {
            'N' => action.type = ActionType.North,
            'E' => action.type = ActionType.East,
            'S' => action.type = ActionType.South,
            'W' => action.type = ActionType.West,
            'L' => action.type = ActionType.Left,
            'R' => action.type = ActionType.Right,
            'F' => action.type = ActionType.Forward,
            else => unreachable,
        }
        action.value = try std.fmt.parseInt(u32, line[1..], 10);

        try actions.append(action);
    }

    return actions.toOwnedSlice();
}

pub fn part1() !u64 {
    var actions = try parseInput();

    var facing: usize = @intFromEnum(ActionType.East);
    var pos = Vector2{ .x = 0, .y = 0 };
    for (actions) |a| {
        switch (a.type) {
            ActionType.North, ActionType.East, ActionType.South, ActionType.West => {
                const d = directions[@intFromEnum(a.type)];
                pos = pos.add(d.mul(a.value));
            },
            ActionType.Left => {
                const rot = 4 - @divExact(a.value, 90);
                facing = @mod(facing + rot, 4);
            },
            ActionType.Right => {
                const rot = @divExact(a.value, 90);
                facing = @mod(facing + rot, 4);
            },
            ActionType.Forward => pos = pos.add(directions[facing].mul(a.value)),
        }
    }

    return pos.manhattanDistance(Vector2{ .x = 0, .y = 0 });
}

pub fn part2() !u64 {
    var actions = try parseInput();

    var ship = Vector2{ .x = 0, .y = 0 };
    var waypoint = Vector2{ .x = 10, .y = 1 };
    for (actions) |a| {
        switch (a.type) {
            ActionType.North, ActionType.East, ActionType.South, ActionType.West => {
                const d = directions[@intFromEnum(a.type)];
                waypoint = waypoint.add(d.mul(a.value));
            },
            ActionType.Left => {
                const rot = 4 - @divExact(a.value, 90);
                waypoint = waypoint.matMul(rotations[rot]);
            },
            ActionType.Right => {
                const rot = @divExact(a.value, 90);
                waypoint = waypoint.matMul(rotations[rot]);
            },
            ActionType.Forward => ship = ship.add(waypoint.mul(a.value)),
        }
    }

    return ship.manhattanDistance(Vector2{ .x = 0, .y = 0 });
}
