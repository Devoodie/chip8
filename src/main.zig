const std = @import("std");
const chip8 = @import("chip8.zig");
const c = @cImport(@cInclude("SDL2/SDL.h"));

pub fn sdlDraw(bitmap: [64][36]u1, renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 0);
    var screen_x: c_int = 0;
    var screen_y: c_int = 0;

    for (bitmap, 0..) |row, row_index| {
        for (row, 0..) |column, column_index| {
            if (column == 1) {
                screen_x = row_index * 20;
                screen_y = column_index * 20;

                for (0..20) |i| {
                    c.SDL_RenderDrawLine(renderer, screen_x, screen_y + i, screen_x + 20, screen_y);
                }
            }
        }
    }
}

pub fn executeInstruction(virtual_machine: *chip8.chip8) std.mem.Allocator.Error!void {
    var opcode: u16 = 0;
    opcode |= virtual_machine.memory[virtual_machine.pc];
    opcode <<= 8;
    opcode |= virtual_machine.memory[virtual_machine.pc + 1];
    std.debug.print("Opcode: 0x{x}\n", .{opcode});

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
        0x1000 => {
            virtual_machine.pc = opcode & 0xFFF;
            std.debug.print("Jumping to 0x{x}\n", .{virtual_machine.pc});
            return;
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
        0xD000 => draw: {
            var x_register: u8 = virtual_machine.registers[((opcode & 0xF00) >> 8)] & 63;
            var y_register: u8 = virtual_machine.registers[(opcode & 0xF0) >> 4] & 31;
            const n: u4 = @intCast(opcode & 0xF);
            virtual_machine.registers[15] = 0;
            var sprite_row: u8 = 0;
            var pixel: u1 = 0;

            for (0..n) |i| {
                sprite_row = virtual_machine.memory[virtual_machine.index + i];
                virtual_machine.registers[15] = 0;
                row: for (0..8) |_| {
                    pixel = @intCast((sprite_row << 7) >> 7);
                    if (x_register > 63) {
                        break :row;
                    } else if ((virtual_machine.display[y_register][x_register] == 1) and (pixel == 1)) {
                        virtual_machine.registers[15] = 1;
                        virtual_machine.display[y_register][x_register] = 0;
                    } else {
                        virtual_machine.display[y_register][x_register] = pixel;
                    }
                    x_register += 1;
                }
                y_register += 1;
            }
            break :draw;
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
    virtual_machine.pc += 2;
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

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        std.debug.print("Could not init SDL: {s}", .{c.SDL_GetError()});
        return;
    }
    const screen = c.SDL_CreateWindow("Dev's Chip8", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 1280, 640, 0);
    const renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_SOFTWARE);
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    //    _ = c.SDL_RenderPresent(renderer);
    //    _ = c.SDL_Delay(3000);

    // c.SDL_DestroyWindow(screen);
    // c.SDL_Quit();

    while (true) {
        _ = try executeInstruction(vm_pointer);
        sdlDraw(vm_pointer.display, renderer);
    }

    std.debug.print("{d}", .{virtual_machine.memory[512]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
