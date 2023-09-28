const std = @import("std");
const fmt = @import("std").fmt;
const mem = @import("std").mem;
const data = @embedFile("04.txt");

const Passport = std.StringArrayHashMap([]const u8);

fn parseInput() ![]Passport {
    var parts = mem.tokenizeSequence(u8, data, "\n\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var passports = std.ArrayList(Passport).init(gpa.allocator());
    defer passports.deinit();

    while (parts.next()) |p| {
        var passport = Passport.init(gpa.allocator());

        var fields = mem.tokenizeAny(u8, p, " \n");
        while (fields.next()) |f| {
            var key = f[0..3];
            var value = f[4..];
            try passport.put(key, value);
        }
        try passports.append(passport);
    }

    return passports.toOwnedSlice();
}

pub fn part1() !i64 {
    const passports = try parseInput();

    var valid: i64 = 0;
    for (passports) |p| {
        if (p.count() <= 6) {
            continue;
        }
        if (p.count() == 7 and p.contains("cid")) {
            continue;
        }

        valid += 1;
    }
    return valid;
}

pub fn part2() !i64 {
    const passports = try parseInput();

    var valid: i64 = 0;
    for (passports) |p| {
        if (p.count() <= 6) {
            continue;
        }
        if (p.count() == 7 and p.contains("cid")) {
            continue;
        }

        const byr = p.get("byr").?;
        if (byr.len != 4) {
            continue;
        }
        const byr_value = fmt.parseInt(i64, byr, 10) catch continue;
        if (byr_value < 1920 or byr_value > 2002) {
            continue;
        }

        const iyr = p.get("iyr").?;
        if (iyr.len != 4) {
            continue;
        }
        const iyr_value = fmt.parseInt(i64, iyr, 10) catch continue;
        if (iyr_value < 2010 or iyr_value > 2020) {
            continue;
        }

        const eyr = p.get("eyr").?;
        if (eyr.len != 4) {
            continue;
        }
        const eyr_value = fmt.parseInt(i64, eyr, 10) catch continue;
        if (eyr_value < 2020 or eyr_value > 2030) {
            continue;
        }

        const hgt = p.get("hgt").?;
        const hgt_unit = hgt[hgt.len - 2 ..];
        const hgt_value = fmt.parseInt(i64, hgt[0 .. hgt.len - 2], 10) catch continue;
        if (mem.eql(u8, hgt_unit, "cm")) {
            if (hgt_value < 150 or hgt_value > 193) {
                continue;
            }
        } else if (mem.eql(u8, hgt_unit, "in")) {
            if (hgt_value < 59 or hgt_value > 76) {
                continue;
            }
        } else {
            continue;
        }

        const hcl = p.get("hcl").?;
        if (hcl.len != 7 or hcl[0] != '#') {
            continue;
        }
        _ = fmt.parseInt(i64, hcl[1..], 16) catch continue;

        const ecl = p.get("ecl").?;
        if (!mem.eql(u8, ecl, "amb") and
            !mem.eql(u8, ecl, "blu") and
            !mem.eql(u8, ecl, "brn") and
            !mem.eql(u8, ecl, "gry") and
            !mem.eql(u8, ecl, "grn") and
            !mem.eql(u8, ecl, "hzl") and
            !mem.eql(u8, ecl, "oth"))
        {
            continue;
        }

        const pid = p.get("pid").?;
        if (pid.len != 9) {
            continue;
        }
        _ = fmt.parseInt(i64, pid, 10) catch continue;

        valid += 1;
    }
    return valid;
}
