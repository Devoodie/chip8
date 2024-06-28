const std = @import("std");
const chip8 = @import("chip8.zig");

pub fn execute_instruction(virtual_machine: *chip8.chip8) void {
    var opcode: u16 = 0;
    opcode |= virtual_machine.memory[virtual_machine.pc];
    opcode = opcode << 8;
    opcode |= virtual_machine.memory[virtual_machine.pc + 1];

    switch (opcode & 0xF000) {
        0x0000 => blk: {
            break :blk;
        },
        0x1000 => blk: {
            break :blk;
        },
        0x2000 => blk: {
            break :blk;
        },
        0x3000 => blk: {
            break :blk;
        },
        0x4000 => blk: {
            break :blk;
        },
        0x5000 => blk: {
            break :blk;
        },
        0x6000 => blk: {
            break :blk;
        },
        0x7000 => blk: {
            break :blk;
        },
        0x8000 => blk: {
            break :blk;
        },
        0x9000 => blk: {
            break :blk;
        },
        0xA000 => blk: {
            break :blk;
        },
        0xB000 => blk: {
            break :blk;
        },
        0xC000 => blk: {
            break :blk;
        },
        0xD000 => blk: {
            break :blk;
        },
        0xE000 => blk: {
            break :blk;
        },
        0xF000 => blk: {
            break :blk;
        },
        else => blk: {
            std.debug.print("No Valid Opcode Found!", .{});
            break :blk;
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const rom = try std.fs.openFileAbsolute("/home/devooty/programming/chip8/roms/PONG", .{});
    _ = try rom.seekTo(0);
    const rom_data = try rom.stat();

    var virtual_machine = chip8.chip8{};
    virtual_machine.init();

    const vm_pointer = &virtual_machine;
    const instructions = try rom.readToEndAlloc(allocator, rom_data.size);
    rom.close();

    for (vm_pointer.*.memory[512 .. 512 + instructions.len], instructions) |*address, instruction| {
        address.* = instruction;
    }

    allocator.free(instructions);

    execute_instruction(vm_pointer);

    std.debug.print("{d}", .{virtual_machine.memory[512]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
