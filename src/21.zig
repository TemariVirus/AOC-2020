const std = @import("std");
const Allocator = std.mem.Allocator;
const data = @embedFile("21.txt");

const IngredientSet = std.bit_set.ArrayBitSet(usize, 256);
const AllergenSet = std.bit_set.IntegerBitSet(32);
const Food = struct {
    ingredients: IngredientSet,
    allergens: AllergenSet,
};

fn parseInput(allocator: Allocator) !struct { []Food, [][]const u8, [][]const u8 } {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    var foods = std.ArrayList(Food).init(allocator);
    var ingredients = std.StringHashMap(usize).init(allocator);
    defer ingredients.deinit();
    var allergens = std.StringHashMap(usize).init(allocator);
    defer allergens.deinit();

    while (lines.next()) |line| {
        var parts = std.mem.tokenizeSequence(u8, line, " (contains ");

        var ingredients_str = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
        var ingredient_set = IngredientSet.initEmpty();
        while (ingredients_str.next()) |i| {
            const entry = try ingredients.getOrPutValue(i, ingredients.count());
            const idx = entry.value_ptr.*;
            ingredient_set.set(idx);
        }

        var allergens_str = std.mem.tokenizeSequence(u8, parts.peek().?[0 .. parts.next().?.len - 1], ", ");
        var allergen_set = AllergenSet.initEmpty();
        while (allergens_str.next()) |a| {
            const entry = try allergens.getOrPutValue(a, allergens.count());
            const idx = entry.value_ptr.*;
            allergen_set.set(idx);
        }

        try foods.append(Food{ .ingredients = ingredient_set, .allergens = allergen_set });
    }

    var ingredients_arr = try allocator.alloc([]const u8, ingredients.count());
    var ingredients_iter = ingredients.iterator();
    while (ingredients_iter.next()) |entry| {
        ingredients_arr[entry.value_ptr.*] = entry.key_ptr.*;
    }

    var allergens_arr = try allocator.alloc([]const u8, allergens.count());
    var allergens_iter = allergens.iterator();
    while (allergens_iter.next()) |entry| {
        allergens_arr[entry.value_ptr.*] = entry.key_ptr.*;
    }

    return .{ try foods.toOwnedSlice(), ingredients_arr, allergens_arr };
}

fn findAllergens(foods: []Food, allergen_count: usize, allocator: Allocator) ![]usize {
    // Maps position of set bits (food ids) to lists of allergen ids of allergens that might be that food
    var candidate_map = std.AutoHashMap(usize, std.ArrayList(usize)).init(allocator);
    defer {
        candidate_map.deinit();
    }

    for (0..allergen_count) |i| {
        var possible_allergens = IngredientSet.initFull();
        for (foods) |food| {
            if (food.allergens.isSet(i)) {
                possible_allergens = possible_allergens.intersectWith(food.ingredients);
            }
        }

        var iter = possible_allergens.iterator(.{});
        while (iter.next()) |food_id| {
            if (!candidate_map.contains(food_id)) {
                try candidate_map.put(food_id, std.ArrayList(usize).init(allocator));
            }
            var arr = candidate_map.getPtr(food_id).?;
            try arr.append(i);
        }
    }

    var allergens = try allocator.alloc(usize, allergen_count);
    while (candidate_map.count() > 0) {
        var entries = candidate_map.iterator();
        while (entries.next()) |entry| {
            const food_id = entry.key_ptr.*;
            var allergen_ids = entry.value_ptr.*;

            if (allergen_ids.items.len > 1) {
                continue;
            }

            const allergen_id = allergen_ids.items[0];
            allergens[allergen_id] = food_id;
            // Remove this candidate set
            allergen_ids.deinit();
            _ = candidate_map.remove(food_id);
            // Remove the allergen from remaining candidates
            var remaining_sets = candidate_map.valueIterator();
            while (remaining_sets.next()) |ids| {
                const idx = for (0..ids.items.len) |i| {
                    if (ids.items[i] == allergen_id) {
                        break i;
                    }
                } else continue;
                _ = ids.swapRemove(idx);
            }

            break;
        } else unreachable;
    }
    return allergens;
}

pub fn part1() !u64 {
    const allocator = std.heap.c_allocator;

    const input = try parseInput(allocator);
    defer {
        allocator.free(input[0]);
        allocator.free(input[1]);
        allocator.free(input[2]);
    }

    const foods = input[0];
    const allergen_count = input[2].len;

    const allergens = try findAllergens(foods, allergen_count, allocator);
    defer allocator.free(allergens);

    var non_allergens = IngredientSet.initFull();
    for (allergens) |a| {
        non_allergens.unset(a);
    }

    var count: usize = 0;
    for (foods) |food| {
        count += food.ingredients.intersectWith(non_allergens).count();
    }
    return count;
}

pub fn part2() ![]const u8 {
    const allocator = std.heap.c_allocator;

    const input = try parseInput(allocator);
    defer {
        allocator.free(input[0]);
        allocator.free(input[1]);
        allocator.free(input[2]);
    }

    const foods = input[0];
    const ingredients = input[1];
    const allergens = input[2];
    const allergen_count = input[2].len;

    const allergen_map = try findAllergens(foods, allergen_count, allocator);
    defer allocator.free(allergen_map);

    const FoodAllergenPair = struct { food_id: usize, allergen_name: []const u8 };
    var allergen_names = try allocator.alloc(FoodAllergenPair, allergen_count);
    defer allocator.free(allergen_names);

    for (0..allergen_count) |i| {
        allergen_names[i] = .{ .food_id = allergen_map[i], .allergen_name = allergens[i] };
    }
    std.mem.sortUnstable(
        FoodAllergenPair,
        allergen_names,
        {},
        struct {
            pub fn lessThanFn(_: void, lhs: FoodAllergenPair, rhs: FoodAllergenPair) bool {
                return std.mem.lessThan(u8, lhs.allergen_name, rhs.allergen_name);
            }
        }.lessThanFn,
    );

    var result = std.ArrayList(u8).init(allocator);
    for (allergen_names) |a| {
        try result.appendSlice(ingredients[a.food_id]);
        try result.append(',');
    }
    _ = result.swapRemove(result.items.len - 1);
    return result.toOwnedSlice();
}
