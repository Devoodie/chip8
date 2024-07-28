const std = @import("std");
const chip8 = @import("chip8.zig");
const c = @cImport(@cInclude("SDL2/SDL.h"));

pub fn sdlDraw(bitmap: [32][64]u1, renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(renderer);
    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    var screen_x: c_int = 0;
    var screen_y: c_int = 0;

    for (bitmap, 0..) |row, row_index| {
        for (row, 0..) |column, column_index| {
            if (column == 1) {
                screen_x = @as(c_int, @intCast(column_index)) * 20;
                screen_y = @as(c_int, @intCast(row_index)) * 20;
                _ = c.SDL_RenderDrawLine(renderer, screen_x, screen_y, screen_x + 20, screen_y);
                for (0..20) |i| {
                    _ = c.SDL_RenderDrawLine(renderer, screen_x + @as(c_int, @intCast(i)), screen_y, screen_x + @as(c_int, @intCast(i)), screen_y + 20);
                }
            }
        }
    }
    _ = c.SDL_RenderPresent(renderer);
}

//pub fn wait(timer: *std.time.Timer, executed_instructions: *u16) void {
//    if (timer.read() >= 1000000000) {
//       executed_instructions.* = 0;
//      timer.reset();
// } else if (executed_instructions.* > 600) {
//    std.time.sleep(1000000000 - timer.read());
// }
//}

pub fn decrementTimers(delay: *u8, sound: *u8, previous_time: i128) void {
    const decrement = @as(u8, @intCast(@divExact((std.time.nanoTimestamp() - previous_time), 16666666)));
    if (delay.* > 0) {
        const delay_result = @subWithOverflow(delay.*, decrement);
        if (delay_result[1] < 0) {
            delay.* -= decrement[0];
        } else {
            delay.* = 0;
        }
    }

    if (sound.* > 0) {
        const sound_result = @subWithOverflow(sound.*, decrement);
        if (sound_result[1] < 0) {
            sound.* -= decrement[0];
        } else {
            delay.* = 0;
        }
    }
}

pub fn GetKeys(key_array: [*c]u8, keyboard: *[16]u1) void {
    for (keyboard) |*key| {
        key.* = 0;
    }
    var keys_set: bool = true;
    if (key_array[c.SDL_SCANCODE_1] == 1) {
        keys_set = true;
        keyboard[1] = 1;
    }
    if (key_array[c.SDL_SCANCODE_2] == 1) {
        keys_set = true;
        keyboard[2] = 1;
    }
    if (key_array[c.SDL_SCANCODE_3] == 1) {
        keys_set = true;
        keyboard[3] = 1;
    }
    if (key_array[c.SDL_SCANCODE_4] == 1) {
        keys_set = true;
        keyboard[0xC] = 1;
    }
    if (key_array[c.SDL_SCANCODE_Q] == 1) {
        keys_set = true;
        keyboard[4] = 1;
    }
    if (key_array[c.SDL_SCANCODE_W] == 1) {
        keys_set = true;
        keyboard[5] = 1;
    }
    if (key_array[c.SDL_SCANCODE_E] == 1) {
        keys_set = true;
        keyboard[6] = 1;
    }
    if (key_array[c.SDL_SCANCODE_R] == 1) {
        keys_set = true;
        keyboard[0xD] = 1;
    }
    if (key_array[c.SDL_SCANCODE_A] == 1) {
        keys_set = true;
        keyboard[7] = 1;
    }
    if (key_array[c.SDL_SCANCODE_S] == 1) {
        keys_set = true;
        keyboard[8] = 1;
    }
    if (key_array[c.SDL_SCANCODE_D] == 1) {
        keys_set = true;
        keyboard[9] = 1;
    }
    if (key_array[c.SDL_SCANCODE_F] == 1) {
        keys_set = true;
        keyboard[0xE] = 1;
    }
    if (key_array[c.SDL_SCANCODE_Z] == 1) {
        keys_set = true;
        keyboard[0xA] = 1;
    }
    if (key_array[c.SDL_SCANCODE_X] == 1) {
        keys_set = true;
        keyboard[0] = 1;
    }
    if (key_array[c.SDL_SCANCODE_C] == 1) {
        keys_set = true;
        keyboard[0xB] = 1;
    }
    if (key_array[c.SDL_SCANCODE_V] == 1) {
        keys_set = true;
        keyboard[0xF] = 1;
    }
}

pub fn executeInstruction(virtual_machine: *chip8.chip8, random: *std.Random) std.mem.Allocator.Error!void {
    var opcode: u16 = 0;
    opcode |= virtual_machine.memory[virtual_machine.pc];
    opcode <<= 8;
    opcode |= virtual_machine.memory[virtual_machine.pc + 1];
    std.debug.print("Opcode: 0x{x}\n", .{opcode});

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
        0x2000 => {
            const address = opcode & 0xFFF;
            _ = try virtual_machine.stack.append(virtual_machine.pc);
            virtual_machine.pc = address;
            return;
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
        0x8000 => logic_operations: {
            const register_x: u4 = @intCast((opcode & 0xF00) >> 8);
            const register_y: u4 = @intCast((opcode & 0xF0) >> 4);
            switch (opcode & 0xF) {
                0x0 => {
                    virtual_machine.registers[register_x] = virtual_machine.registers[register_y];
                    break :logic_operations;
                },
                0x1 => {
                    virtual_machine.registers[register_x] |= virtual_machine.registers[register_y];
                    break :logic_operations;
                },
                0x2 => {
                    virtual_machine.registers[register_x] &= virtual_machine.registers[register_y];
                    break :logic_operations;
                },
                0x3 => {
                    virtual_machine.registers[register_x] ^= virtual_machine.registers[register_y];
                    break :logic_operations;
                },
                0x4 => {
                    const sum = (@addWithOverflow(virtual_machine.registers[register_x], virtual_machine.registers[register_y]));
                    virtual_machine.registers[register_x] = sum[0];

                    if (sum[1] <= 0) {
                        virtual_machine.registers[15] = 0;
                    } else {
                        virtual_machine.registers[15] = 1;
                    }
                    break :logic_operations;
                },
                0x5 => {
                    const difference = @subWithOverflow(virtual_machine.registers[register_x], virtual_machine.registers[register_y]);
                    virtual_machine.registers[register_x] = difference[0];

                    if (difference[1] <= 0) {
                        virtual_machine.registers[15] = 1;
                    } else {
                        virtual_machine.registers[15] = 0;
                    }
                    break :logic_operations;
                },
                0x6 => {
                    virtual_machine.registers[register_x] = virtual_machine.registers[register_y];
                    const result = virtual_machine.registers[register_x] & 0b1;
                    virtual_machine.registers[register_x] >>= 1;
                    if (result == 1) {
                        virtual_machine.registers[15] = 1;
                    } else {
                        virtual_machine.registers[15] = 0;
                    }
                    break :logic_operations;
                },
                0x7 => {
                    const difference = @subWithOverflow(virtual_machine.registers[register_y], virtual_machine.registers[register_x]);

                    virtual_machine.registers[register_x] = difference[0];
                    if (difference[1] <= 0) {
                        virtual_machine.registers[15] = 1;
                    } else {
                        virtual_machine.registers[15] = 0;
                    }
                    break :logic_operations;
                },
                0xE => {
                    virtual_machine.registers[register_x] = virtual_machine.registers[register_y];
                    const result = @shlWithOverflow(virtual_machine.registers[register_x], 1);
                    virtual_machine.registers[register_x] = result[0];
                    if (result[1] <= 0) {
                        virtual_machine.registers[15] = 0;
                    } else {
                        virtual_machine.registers[15] = 1;
                    }
                    break :logic_operations;
                },

                else => {
                    std.debug.print("0x8000 invalid last nib!", .{});
                    break :logic_operations;
                },
            }
        },
        0x9000 => registers_not_equal: {
            const x_register: u4 = @intCast((opcode & 0xF00) >> 8);
            const y_register: u4 = @intCast((opcode & 0xF0) >> 4);
            if (!(virtual_machine.registers[x_register] == virtual_machine.registers[y_register])) {
                virtual_machine.pc += 2;
            }
            break :registers_not_equal;
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
            const register: u4 = @intCast((opcode & 0xF00) >> 8);
            const value: u8 = @intCast((random.intRangeAtMost(u8, 0, 0xFF)) & opcode & 0xFF);
            virtual_machine.registers[register] = value;
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
                virtual_machine.registers[15] = 0;

                row: for (0..8) |_| {
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
        0xE000 => skip_key: {
            switch (opcode & 0xFF) {
                0x9E => {
                    const key: u4 = @intCast((opcode & 0xF00) >> 8);
                    if (virtual_machine.keypad[virtual_machine.registers[key]] == 1) {
                        virtual_machine.pc += 2;
                        std.debug.print("0xE000 {d} was pressed!\n", .{key});
                    }
                    break :skip_key;
                },
                0xA1 => {
                    const key: u4 = @intCast((opcode & 0xF00) >> 8);
                    if (!(virtual_machine.keypad[virtual_machine.registers[key]] == 1)) {
                        virtual_machine.pc += 2;
                        std.debug.print("0xE000 {d} was not pressed!\n", .{key});
                    }
                    break :skip_key;
                },
                else => {
                    std.debug.print("0xE000 No Valid Opcode Found!", .{});
                    break :skip_key;
                },
            }
        },
        0xF000 => blk: {
            const nib: u4 = @intCast((opcode & 0xF00) >> 8);
            switch (opcode & 0xFF) {
                0x0A => {
                    const register = ((opcode & 0xF00) >> 8);
                    for (virtual_machine.keypad, 0..) |input, index| {
                        if (input == 1) {
                            virtual_machine.registers[register] = @intCast(index);
                            break :blk;
                        }
                    }
                    return;
                },
                0x07 => {
                    virtual_machine.registers[nib] = virtual_machine.delay;
                    break :blk;
                },
                0x15 => {
                    virtual_machine.delay = virtual_machine.registers[nib];
                    break :blk;
                },
                0x18 => {
                    virtual_machine.sound = virtual_machine.registers[nib];
                    break :blk;
                },
                0x1E => {
                    virtual_machine.index += virtual_machine.registers[nib];
                    break :blk;
                },
                0x29 => {
                    virtual_machine.index = 80 + (virtual_machine.registers[nib] * 5);
                    break :blk;
                },
                0x33 => {
                    const value = virtual_machine.registers[nib];
                    const digit_1 = (value % 100) % 10;
                    const digit_2 = ((value % 100) - digit_1) / 10;
                    const digit_3 = ((value - (digit_1 + digit_2))) / 100;
                    virtual_machine.memory[virtual_machine.index] = digit_3;
                    virtual_machine.memory[virtual_machine.index + 1] = digit_2;
                    virtual_machine.memory[virtual_machine.index + 2] = digit_1;
                    break :blk;
                },
                0x55 => {
                    var i: u8 = 0;
                    for (virtual_machine.registers[0 .. nib + 1], 0..) |value, index| {
                        i = @intCast(index);
                        virtual_machine.memory[virtual_machine.index + i] = value;
                    }
                    break :blk;
                },
                0x65 => {
                    var i: u8 = 0;
                    for (virtual_machine.registers[0 .. nib + 1], 0..) |*value, index| {
                        i = @intCast(index);
                        value.* = virtual_machine.memory[virtual_machine.index + i];
                    }
                    break :blk;
                },
                else => {
                    std.debug.print("0xF000 No Valid Opcode Found!", .{});
                    break :blk;
                },
            }
        },
        else => default: {
            std.debug.print("No Valid Opcode Found!", .{});
            break :default;
        },
    }
    virtual_machine.pc += 2;
    std.time.sleep(std.time.ns_per_s / 900);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const rom = try std.fs.openFileAbsolute("/home/devooty/programming/chip8/roms/Pong(1 player).ch8", .{});
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

    var xoshiro = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

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

    //const timer = try std.time.Timer.start();
    //const timer_pointer = @constCast(&timer);

    var time: i128 = 1;

    while (true) {
        _ = c.SDL_PollEvent(event_pointer);
        if (event.type == c.SDL_QUIT) {
            c.SDL_DestroyWindow(screen);
            c.SDL_Quit();
            return;
        }

        keyboard = @constCast(c.SDL_GetKeyboardState(null));
        GetKeys(keyboard, &virtual_machine.keypad);

        decrementTimers(&virtual_machine.delay, &virtual_machine.sound, time);
        time = std.time.nanoTimestamp();

        //        wait(timer_pointer, &executed_intstructions);

        _ = try executeInstruction(vm_pointer, @constCast(&xoshiro.random()));
        sdlDraw(vm_pointer.display, renderer);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
