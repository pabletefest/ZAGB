const std = @import("std");

const CpuStateMode = enum(u1) {
    ARM = 0,
    THUMB = 1,
};

const OperationModes = enum(u5) {
    OLD_USER = 0,
    OLD_FIQ = 1,
    OLD_IRQ = 2,
    OLD_SUPERVISOR = 3,
    USER = 16,
    FIQ = 17,
    IRQ = 18,
    SUPERVISOR = 19,
    ABORT = 23,
    UNDEFINED = 27,
    SYSTEM = 31,

    fn getRegBankOfMode(self: OperationModes) u5 {
        return switch (self) {
            .USER, .SYSTEM => 0,
            .FIQ => 1,
            .IRQ => 2,
            .SUPERVISOR => 3,
            .ABORT => 4,
            .UNDEFINED => 5,
            else => unreachable,
        };
    }
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
    mode_bits: OperationModes,
    state_bit: CpuStateMode,
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

pub const CPU = struct {
    gpr: [16]u32,
    banked_regs: [6][7]u32, // we bank regs 8-14 included, to simplify the process
    cpsr: ProgramStatusRegister,
    spsr: [6]ProgramStatusRegister,
    pipeline: [2]u32,

    const SP = 13;
    const LR = 14;
    const PC = 15;

    pub fn init() CPU {
        var cpu = CPU{
            .gpr = std.mem.zeroes([16]u32),
            .banked_regs = std.mem.zeroes([6][7]u32),
            .cpsr = std.mem.zeroes(ProgramStatusRegister),
            .spsr = std.mem.zeroes([6]ProgramStatusRegister),
            .pipeline = std.mem.zeroes([2]u32),
        };

        cpu.cpsr.mode_bits = OperationModes.SUPERVISOR;
        cpu.cpsr.state_bit = CpuStateMode.ARM;

        return cpu;
    }

    fn read(comptime T: type, address: u32) T {
        _ = address;
    }

    fn write(comptime T: type, address: u32, value: T) void {
        _ = address;
        _ = value;
    }

    fn flushPipeline(self: *CPU) void {
        _ = self;
    }

    fn getPC(self: CPU) u32 {
        return self.gpr[PC];
    }

    fn setPC(self: *CPU, value: u32) void {
        self.gpr[PC] = value;
    }

    fn incrementPC(self: *CPU, increment: PCIncrement) void {
        self.gpr[PC] +%= @intFromEnum(increment);
    }

    fn enterOperationMode(self: *CPU, new_mode: OperationModes) void {
        const banked_regs_offset = 8; // HI registers [8, 12]

        const prev_mode = self.cpsr.mode_bits;
        const prev_bank = prev_mode.getRegBankOfMode();
        const new_bank = new_mode.getRegBankOfMode();

        if (prev_mode == .FIQ) {
            for (8..SP) |index| {
                self.banked_regs[prev_bank][index - banked_regs_offset] = self.gpr[index];
                self.gpr[index] = self.banked_regs[OperationModes.USER.getRegBankOfMode()][index - banked_regs_offset];
            }
        } else if (new_mode == .FIQ) {
            for (8..SP) |index| {
                self.banked_regs[OperationModes.USER.getRegBankOfMode()][index - banked_regs_offset] = self.gpr[index];
                self.gpr[index] = self.banked_regs[new_bank][index - banked_regs_offset];
            }
        }

        self.banked_regs[prev_bank][SP - banked_regs_offset] = self.gpr[SP];
        self.banked_regs[prev_bank][LR - banked_regs_offset] = self.gpr[LR];

        self.gpr[SP] = self.banked_regs[new_bank][SP - banked_regs_offset];
        self.gpr[LR] = self.banked_regs[new_bank][LR - banked_regs_offset];

        if (prev_mode != .USER or prev_mode != .SYSTEM) {
            self.spsr[prev_bank] = self.cpsr;
            self.cpsr = self.spsr[new_bank];
        }

        self.cpsr.mode_bits = new_mode;
    }
};

test "CPU init" {
    var cpu = CPU.init();

    const cpsr_init: u6 = 19 | (0 << 5); // Supervisor and ARM modes

    try std.testing.expectEqual(cpu.cpsr.getRegRaw(), cpsr_init);

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

test "Enter operation mode" {
    var cpu = CPU.init();

    cpu.enterOperationMode(OperationModes.FIQ);

    try std.testing.expectEqual(OperationModes.FIQ, cpu.cpsr.mode_bits);
}
