const std = @import("std");

const CpuStateMode = enum(u1) {
    ARM = 0,
    THUMB = 1,
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

    comptime {
        std.debug.assert(@sizeOf(ProgramStatusRegister == @sizeOf(u32)));
    }
};

var CPU = struct {
    gpr: [16]u32,
    banked_regs: [7][7]u32, // we bank regs 8-14 included, to simplify the process
    cpsr: ProgramStatusRegister,
    spsr: [7]ProgramStatusRegister,
    cpuState: CpuStateMode,
};
