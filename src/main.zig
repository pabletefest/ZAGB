const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("ZAGB_lib");

const CPU = @import("gba/arm7tdmi.zig");

pub fn main() !void {
    std.debug.print("GBA emulator written in Zig!\n", .{});
}
