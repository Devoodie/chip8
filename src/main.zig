const std = @import("std");
const chip8 = @import("chip8.zig");

pub fn execute_instruction(virtual_machine: *chip8.chip8) void {
    var opcode: u16 = 0;
    opcode |= virtual_machine.memory[virtual_machine.pc];
    opcode <<= 8;
    opcode |= virtual_machine.memory[virtual_machine.pc + 1];

    switch (opcode & 0xF000) {
        0x0000 => blk: {
            switch (opcode & 0x00EE) {
                0x00E0 => {
                    for (&virtual_machine.display) |*width| {
                        for (width) |*height| {
                            height.* = 0;
                        }
                    }
                    break :blk;
                },
                0x00EE => {
                    virtual_machine.pc = 0;
                    for (0..16) |_| {
                        virtual_machine.pc <<= 1;
                        virtual_machine.pc |= virtual_machine.stack.pop();
                        std.debug.print("{d}", .{virtual_machine.pc});
                    }
                    break :blk;
                },
                else => {
                    std.debug.print("No valid opcode found!", .{});
                    break :blk;
                },
            }
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
        else => default: {
            std.debug.print("No Valid Opcode Found!", .{});
            break :default;
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

    var virtual_machine = chip8.chip8{ .stack = std.BitStack.init(allocator) };
    virtual_machine.init();

    const vm_pointer = &virtual_machine;
    const instructions = try rom.readToEndAlloc(allocator, rom_data.size);
    rom.close();

    for (vm_pointer.*.memory[512 .. 512 + instructions.len], instructions) |*address, instruction| {
        address.* = instruction;
    }

    allocator.free(instructions);

    while (true) {
        execute_instruction(vm_pointer);
        vm_pointer.*.pc += 2;
    }

    std.debug.print("{d}", .{virtual_machine.memory[512]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
