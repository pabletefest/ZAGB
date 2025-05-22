const std = @import("std");

const ARM7TDMI = @import("arm7tdmi.zig").CPU;

pub const GBA = struct {
    alloc: std.mem.Allocator,
    cpu: *ARM7TDMI,

    pub fn init(allocator: std.mem.Allocator) !GBA {
        const cpu = try allocator.create(ARM7TDMI);
        errdefer allocator.destroy(cpu);

        return .{
            .alloc = allocator,
            .cpu = cpu,
        };
    }

    pub fn deinit(self: *GBA) void {
        self.alloc.destroy(self.cpu);
    }
};
