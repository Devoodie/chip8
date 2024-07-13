const std = @import("std");
const chip8 = @import("chip8.zig");
const c = @cImport(@cInclude("SDL2/SDL.h"));

pub fn sdlDraw(bitmap: [32][64]u1, renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    var screen_x: c_int = 0;
    var screen_y: c_int = 0;
    // this whole section is wrong
    for (bitmap, 0..) |row, row_index| {
        for (row, 0..) |column, column_index| {
            if (column == 1) {
                screen_x = @as(c_int, @intCast(column_index)) * 20;
                screen_y = @as(c_int, @intCast(row_index)) * 20;
                //                std.debug.print("X: {d}, Y{d}\n", .{ screen_x, screen_y });
                _ = c.SDL_RenderDrawLine(renderer, screen_x, screen_y, screen_x + 20, screen_y);

                for (0..20) |i| {
                    _ = c.SDL_RenderDrawLine(renderer, screen_x + @as(c_int, @intCast(i)), screen_y, screen_x + @as(c_int, @intCast(i)), screen_y + 20);
                }
            }
        }
    }
    _ = c.SDL_RenderPresent(renderer);
}

pub fn executeInstruction(virtual_machine: *chip8.chip8) std.mem.Allocator.Error!void {
    var opcode: u16 = 0;
    opcode |= virtual_machine.memory[virtual_machine.pc];
    opcode <<= 8;
    opcode |= virtual_machine.memory[virtual_machine.pc + 1];
    //   std.debug.print("Opcode: 0x{x}\n", .{opcode});

    switch (opcode & 0xF000) {
        0x0000 => blk: {
            switch (opcode & 0x00EE) {
                0x00E0 => {
                    for (&virtual_machine.display) |*row| {
                        for (row) |*column| {
                            column.* = 0;
                        }
                    }
                    std.debug.print("Screen Cleared!\n", .{});
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
            //            std.debug.print("Jumping to 0x{x}\n", .{virtual_machine.pc});
            //           std.debug.print("Value {x}\n", .{virtual_machine.memory[virtual_machine.pc]});
            return;
        },
        0x2000 => subroutine: {
            const address = opcode & 0xFFF;
            _ = try virtual_machine.stack.append(virtual_machine.pc);
            virtual_machine.pc = address;
            break :subroutine;
        },
        0x3000 => equal_skip: {
            const value: u8 = @intCast(opcode & 0xFF);
            const register: u4 = @intCast((opcode & 0xF00) >> 8);
            if (value == virtual_machine.registers[register]) {
                virtual_machine.pc += 2;
            }
            break :equal_skip;
        },
        0x4000 => not_equal: {
            const value: u8 = @intCast(opcode & 0xFF);
            const register: u4 = @intCast((opcode & 0xF00) >> 8);
            if (!(value == virtual_machine.registers[register])) {
                virtual_machine.pc += 2;
            }
            break :not_equal;
        },
        0x5000 => registers_equal: {
            const x_register: u4 = @intCast((opcode & 0xF00) >> 8);
            const y_register: u4 = @intCast((opcode & 0xF0) >> 4);
            if (virtual_machine.registers[x_register] == virtual_machine.registers[y_register]) {
                virtual_machine.pc += 2;
            }
            break :registers_equal;
        },
        0x6000 => set_register: {
            const register = (opcode & 0xF00) >> 8;
            const value: u8 = @intCast(opcode & 0xFF);
            virtual_machine.registers[register] = value;
            //            std.debug.print("Value: {d} at Register:{d}\n", .{ value, register });
            break :set_register;
        },
        0x7000 => add_register: {
            const register = (opcode & 0xF00) >> 8;
            const value: u8 = @intCast(opcode & 0xFF);
            //            std.debug.print("{d} + {d} in Register: {d}\n", .{ virtual_machine.registers[register], value, register });
            virtual_machine.registers[register] += value;
            break :add_register;
        },
        0x8000 => blk: {
            break :blk;
        },
        0x9000 => blk: {
            const x_register: u4 = @intCast((opcode & 0xF00) >> 8);
            const y_register: u4 = @intCast((opcode & 0xF0) >> 4);
            if (!(virtual_machine.registers[x_register] == virtual_machine.registers[y_register])) {
                virtual_machine.pc += 2;
            }
            break :blk;
        },
        0xA000 => set_index: {
            const address = opcode & 0xFFF;
            virtual_machine.index = address;
            break :set_index;
        },
        0xB000 => offset_jump: {
            virtual_machine.pc = (opcode & 0xFFF) + virtual_machine.registers[0];
            break :offset_jump;
        },
        0xC000 => blk: {
            break :blk;
        },
        0xD000 => draw: {
            var x_register: u8 = virtual_machine.registers[(opcode & 0xF00) >> 8] & 63;
            var y_register: u8 = virtual_machine.registers[(opcode & 0xF0) >> 4] & 31;
            const n: u4 = @intCast(opcode & 0xF);
            virtual_machine.registers[15] = 0;
            var sprite_row: u8 = 0;
            var pixel: u1 = 0;

            for (0..n) |i| {
                sprite_row = virtual_machine.memory[virtual_machine.index + i];
                //                std.debug.print("sprite: 0x{x} at index: {d} \n", .{ sprite_row, virtual_machine.index + i });
                virtual_machine.registers[15] = 0;
                row: for (0..8) |_| {
                    //sprites should be processed big endian fix this asap
                    pixel = @intCast((sprite_row & 0b10000000) >> 7);
                    if (x_register >= 64 or y_register >= 32) {
                        break :row;
                    } else if ((virtual_machine.display[y_register][x_register] == 1) and (pixel == 1)) {
                        virtual_machine.registers[15] = 1;
                        virtual_machine.display[y_register][x_register] = 0;
                    } else {
                        virtual_machine.display[y_register][x_register] ^= pixel;
                    }
                    sprite_row <<= 1;
                    x_register += 1;
                }
                y_register += 1;
                x_register = virtual_machine.registers[(opcode & 0xF00) >> 8] & 63;
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

    const rom = try std.fs.openFileAbsolute("/home/devooty/programming/chip8/roms/chip8splash.ch8", .{});
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
    var event: c.SDL_Event = undefined;
    const event_pointer: [*c]c.SDL_Event = @constCast(&event);
    var keyboard: [*c]u8 = undefined;
    const keys = 0;
    //    _ = c.SDL_RenderPresent(renderer);
    //    _ = c.SDL_Delay(3000);

    // c.SDL_DestroyWindow(screen);
    // c.SDL_Quit();
    //var stop: u8 = 0;

    while (true) {
        _ = try executeInstruction(vm_pointer);
        _ = c.SDL_PollEvent(event_pointer);
        sdlDraw(vm_pointer.display, renderer);
        //   stop += 1;
        if (event.type == c.SDL_QUIT) {
            c.SDL_DestroyWindow(screen);
            c.SDL_Quit();
            return;
        }

        keyboard = @constCast(event.key);

        for (0..keys) |input| {
            std.debug.print("{s} was pressed!", .{keyboard[input]});
        }
    }

    std.debug.print("{d}", .{virtual_machine.memory[512]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
