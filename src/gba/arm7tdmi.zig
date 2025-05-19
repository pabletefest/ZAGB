const std = @import("std");

const CpuStateMode = enum(u1) {
    ARM = 0,
    THUMB = 1,
};

const CPSRBitsMask = enum(u32) {
    N = 0x80000000,
    Z = 0x40000000,
    C = 0x20000000,
    V = 0x10000000,
    I = 0x00000080,
    F = 0x00000040,
    T = 0x00000020,
};

const ProgramStatusRegister = packed struct(u32) {
    mode_bits: enum(u5) {
        old_user = 0,
        old_fiq = 1,
        old_irq = 2,
        old_supervisor = 3,
        user = 16,
        fiq = 17,
        irq = 18,
        supervisor = 19,
        abort = 23,
        undef = 27,
        system = 31,
    },
    state_bit: enum(u1) {
        arm = 0,
        thumb = 1,
    },
    fiq_disable: enum(u1) {
        enable = 0,
        disable = 1,
    },
    irq_disable: enum(u1) {
        enable = 0,
        disable = 1,
    },
    unused_abort_disable: u1,
    unused_endian: u1,
    reserved_1: u14,
    unused_jazelle_mode: enum(u1) {
        none = 0,
        jazelle_bytecode = 1,
    },
    reserved_2: u2,
    sticky_overflow: enum(u1) {
        none = 0,
        sticky_overflow = 1,
    },
    overflow_flag: enum(u1) {
        no_overflow = 0,
        overflow = 1,
    },
    carry_flag: enum(u1) {
        no_carry = 0,
        carry = 1,
    },
    zero_flag: enum(u1) {
        not_zero = 0,
        zero = 1,
    },
    sign_flag: enum(u1) {
        not_signed = 0,
        signed = 1,
    },

    fn getRegRaw(self: ProgramStatusRegister) u32 {
        return @bitCast(self);
    }

    fn setRegRaw(self: *ProgramStatusRegister, value: u32) void {
        self.* = @bitCast(value);
    }

    fn setBits(self: *ProgramStatusRegister, bits_mask: CPSRBitsMask) void {
        self.setRegRaw(self.getRegRaw() | @intFromEnum(bits_mask));
    }

    fn clearBits(self: *ProgramStatusRegister, bits_mask: CPSRBitsMask) void {
        self.setRegRaw(self.getRegRaw() & ~(@intFromEnum(bits_mask)));
    }

    fn isBitSet(self: ProgramStatusRegister, bits_mask: CPSRBitsMask) bool {
        return (self.getRegRaw() & @intFromEnum(bits_mask)) > 0;
    }

    comptime {
        std.debug.assert(@sizeOf(ProgramStatusRegister) == @sizeOf(u32));
    }
};

const PCIncrement = enum(u3) {
    THUMB_INC = 2,
    ARM_INC = 4,
};

const CPU = struct {
    gpr: [16]u32,
    banked_regs: [7][7]u32, // we bank regs 8-14 included, to simplify the process
    cpsr: ProgramStatusRegister,
    spsr: [7]ProgramStatusRegister,
    pipeline: [2]u32,

    pub fn init() CPU {
        return CPU{
            .gpr = std.mem.zeroes([16]u32),
            .banked_regs = std.mem.zeroes([7][7]u32),
            .cpsr = std.mem.zeroes(ProgramStatusRegister),
            .spsr = std.mem.zeroes([7]ProgramStatusRegister),
            .pipeline = std.mem.zeroes([2]u32),
        };
    }

    fn getPC(self: CPU) u32 {
        return self.gpr[15];
    }

    fn setPC(self: *CPU, value: u32) void {
        self.gpr[15] = value;
    }

    fn incrementPC(self: *CPU, increment: PCIncrement) void {
        self.gpr[15] +%= @intFromEnum(increment);
    }
};

test "CPU init" {
    var cpu = CPU.init();

    try std.testing.expectEqual(cpu.cpsr.getRegRaw(), 0);

    cpu.cpsr.setRegRaw(100);

    try std.testing.expectEqual(cpu.cpsr.getRegRaw(), 100);

    cpu.cpsr.mode_bits = @enumFromInt(19);

    try std.testing.expectEqual(@intFromEnum(cpu.cpsr.mode_bits), 19);
}

test "CPSR bits funcs" {
    var cpsr: ProgramStatusRegister = std.mem.zeroes(ProgramStatusRegister);

    try std.testing.expectEqual(cpsr.isBitSet(CPSRBitsMask.T), false);

    cpsr.setBits(CPSRBitsMask.T);

    try std.testing.expectEqual(cpsr.isBitSet(CPSRBitsMask.T), true);

    cpsr.clearBits(CPSRBitsMask.T);

    try std.testing.expectEqual(cpsr.isBitSet(CPSRBitsMask.T), false);
}

test "PC register operations" {
    var cpu = CPU.init();

    try std.testing.expectEqual(cpu.getPC(), 0);

    cpu.setPC(0xFFFFFFFF);

    try std.testing.expectEqual(cpu.getPC(), 0xFFFFFFFF);

    cpu.incrementPC(PCIncrement.THUMB_INC);

    try std.testing.expectEqual(cpu.getPC(), 0x00000001);
}
