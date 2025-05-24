const std = @import("std");

pub const MemOpError = error{
    UnusedAddressRange,
    MisalignedAddress,
    ReadOnlyMemory,
};

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

    pub fn read(comptime T: type, self: *const Memory, address: u32) MemOpError!type {
        const word_size = @sizeOf(T);
        var mapped_addr = address & 0x0FFFFFFF; // upper 4 bits unused

        switch (@TypeOf(T)) {
            u16 => mapped_addr &= ~0b1,
            u32 => mapped_addr &= ~0b11,
            else => {},
        }

        if (mapped_addr >= 0x00000000 and mapped_addr <= 0x00003FFF) { // BIOS
            const word_addr = mapped_addr & 0x3FFF;
            return std.mem.readInt(T, &self.bios_rom[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x02000000 and mapped_addr <= 0x0203FFFF) { // EWRAM
            const word_addr = mapped_addr & 0x3FFFF;
            return std.mem.readInt(T, &self.ewram[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x03000000 and mapped_addr <= 0x03007FFF) { // IWRAM
            const word_addr = mapped_addr & 0x7FFF;
            return std.mem.readInt(T, &self.iwram[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x04000000 and mapped_addr <= 0x040003FE) { // IO Registers

        } else if (mapped_addr >= 0x05000000 and mapped_addr <= 0x050003FF) { // Palette RAM
            const word_addr = mapped_addr & 0x3FF;
            return std.mem.readInt(T, &self.palette_ram[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x06000000 and mapped_addr <= 0x06017FFF) { // VRAM
            // check later on (16-bit words)
            const word_addr = mapped_addr & 0x17FFF;
            return std.mem.readInt(T, &self.vram[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x07000000 and mapped_addr <= 0x000003FF) { // OAM
            const word_addr = mapped_addr & 0x3FF;
            return std.mem.readInt(T, &self.oam[word_addr..(word_addr + word_size)], .little);
        } else if (mapped_addr >= 0x08000000 and mapped_addr <= 0x0DFFFFFF) { // Game Pak ROM/FlashROM

        } else if (mapped_addr >= 0x0E000000 and mapped_addr <= 0x0E00FFFF) { // Game Pak SRAM

        } else {
            std.debug.print("Unused memory address space! Address: 0x{X}", .{address});
            return MemOpError.UnusedAddressRange;
        }
    }

    pub fn write(comptime T: type, self: *Memory, address: u32, value: T) MemOpError!void {
        const word_size = @sizeOf(T);
        const mapped_addr = address & 0x0FFFFFFF; // upper 4 bits unused

        switch (@TypeOf(T)) {
            u16 => mapped_addr &= ~0b1,
            u32 => mapped_addr &= ~0b11,
            else => {},
        }

        if (mapped_addr >= 0x00000000 and mapped_addr <= 0x00003FFF) { // BIOS
            return MemOpError.ReadOnlyMemory;
        } else if (mapped_addr >= 0x02000000 and mapped_addr <= 0x0203FFFF) { // EWRAM
            const word_addr = mapped_addr & 0x3FFFF;
            std.mem.writeInt(T, &self.ewram[word_addr..(word_addr + word_size)], value, .little);
        } else if (mapped_addr >= 0x03000000 and mapped_addr <= 0x03007FFF) { // IWRAM
            const word_addr = mapped_addr & 0x7FFF;
            std.mem.readInt(T, &self.iwram[word_addr..(word_addr + word_size)], value, .little);
        } else if (mapped_addr >= 0x04000000 and mapped_addr <= 0x040003FE) { // IO Registers

        } else if (mapped_addr >= 0x05000000 and mapped_addr <= 0x050003FF) { // Palette RAM
            const word_addr = mapped_addr & 0x3FF;
            std.mem.readInt(T, &self.palette_ram[word_addr..(word_addr + word_size)], value, .little);
        } else if (mapped_addr >= 0x06000000 and mapped_addr <= 0x06017FFF) { // VRAM
            // check later on (16-bit words)
            const word_addr = mapped_addr & 0x17FFF;
            std.mem.readInt(T, &self.vram[word_addr..(word_addr + word_size)], value, .little);
        } else if (mapped_addr >= 0x07000000 and mapped_addr <= 0x000003FF) { // OAM
            const word_addr = mapped_addr & 0x3FF;
            std.mem.readInt(T, &self.oam[word_addr..(word_addr + word_size)], value, .little);
        } else if (mapped_addr >= 0x08000000 and mapped_addr <= 0x0DFFFFFF) { // Game Pak ROM/FlashROM
            return MemOpError.ReadOnlyMemory;
        } else if (mapped_addr >= 0x0E000000 and mapped_addr <= 0x0E00FFFF) { // Game Pak SRAM

        } else {
            std.debug.print("Unused memory address space! Address: 0x{X}", .{address});
            return MemOpError.UnusedAddressRange;
        }
    }
};
