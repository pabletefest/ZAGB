const std = @import("std");

pub const Memory = struct {
    bios_rom: [16 * 1024]u8,
    ewram: [256 * 1024]u8,
    iwram: [32 * 1024]u8,
    palette_ram: [1024]u8,
    vram: [96 * 1024]u8,
    oam: [1024]u8,

    pub fn init() Memory {
        return .{};
    }

    pub fn read(comptime T: type, address: u32) T {
        _ = address;
        return T;
    }

    pub fn write(comptime T: type, address: u32, value: T) void {
        _ = address;
        _ = value;
    }
};
