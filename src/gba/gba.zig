const std = @import("std");

const ARM7TDMI = @import("arm7tdmi.zig").CPU;
const Memory = @import("memory.zig").Memory;

pub const GBA = struct {
    alloc: std.mem.Allocator,
    memory: *Memory,
    cpu: ARM7TDMI,

    pub fn init(allocator: std.mem.Allocator) !GBA {
        const memory = try allocator.create(Memory);
        errdefer allocator.destroy(memory);

        const cpu = ARM7TDMI.init(memory);

        return .{
            .alloc = allocator,
            .memory = memory,
            .cpu = cpu,
        };
    }

    pub fn deinit(self: *GBA) void {
        self.alloc.destroy(self.memory);
    }
};
