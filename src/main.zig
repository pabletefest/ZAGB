const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("ZAGB_lib");

const GBA = @import("gba/gba.zig").GBA;

pub fn main() !void {
    std.debug.print("GBA emulator written in Zig!\n", .{});
}

test "GBA init/deinit" {
    var gba = try GBA.init(std.testing.allocator);
    defer gba.deinit();
}
