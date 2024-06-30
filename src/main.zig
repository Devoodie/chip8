const std = @import("std");
const chip8 = @import("chip8.zig");

pub fn execute_instruction(virtual_machine: *chip8.chip8) std.mem.Allocator.Error!void {
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
                    virtual_machine.pc = virtual_machine.stack.pop();
                    break :blk;
                },
                else => {
                    std.debug.print("No valid opcode found!\n", .{});
                    break :blk;
                },
            }
            break :blk;
        },
        0x1000 => jump: {
            virtual_machine.pc = opcode & 0xFFF;
            std.debug.print("Jumping to 0x{x}\n", .{virtual_machine.pc});
            break :jump;
        },
        0x2000 => subroutine: {
            const address = opcode & 0xFFF;
            _ = try virtual_machine.stack.append(virtual_machine.pc);
            virtual_machine.pc = address;
            break :subroutine;
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
        0x6000 => set_register: {
            const register = (opcode & 0xF00) >> 8;
            const value: u8 = @intCast(opcode & 0xFF);
            virtual_machine.registers[register] = value;
            std.debug.print("Value: {d} at Register:{d}\n", .{ value, register });
            break :set_register;
        },
        0x7000 => add_register: {
            const register = (opcode & 0xF00) >> 8;
            const value: u8 = @intCast(opcode & 0xFF);
            std.debug.print("{d} + {d} in Register: {d}\n", .{ virtual_machine.registers[register], value, register });
            virtual_machine.registers[register] += value;
            break :add_register;
        },
        0x8000 => blk: {
            break :blk;
        },
        0x9000 => blk: {
            break :blk;
        },
        0xA000 => set_index: {
            const address = opcode & 0xFFF;
            virtual_machine.index = address;
            break :set_index;
        },
        0xB000 => blk: {
            break :blk;
        },
        0xC000 => blk: {
            break :blk;
        },
        0xD000 => display: {
            const x_register: u4 = @intCast();
            const y_register: u4 = @intCast();
            const n: u4 = @intCast();
            break :display;
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

    var virtual_machine = chip8.chip8{ .stack = std.ArrayList(u16).init(allocator) };
    virtual_machine.init();

    const vm_pointer = &virtual_machine;
    const instructions = try rom.readToEndAlloc(allocator, rom_data.size);
    rom.close();

    for (vm_pointer.*.memory[512 .. 512 + instructions.len], instructions) |*address, instruction| {
        address.* = instruction;
    }

    allocator.free(instructions);

    while (true) {
        _ = try execute_instruction(vm_pointer);
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
