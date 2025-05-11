const std = @import("std");

const CpuStateMode = enum {
    ARM = 0,
    THUMB = 1,
};

var CPU = struct {
    gpr: [16]u32,
    banked_regs: [7][7]u32, // we bank regs 8-14 included, to simplify the process
    cpsr: u32,
    spsr: [7]u32,
    cpuState: CpuStateMode,
};
