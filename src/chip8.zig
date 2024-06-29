const std = @import("std");

pub const chip8 = struct {
    memory: [4096]u8 = undefined,
    pc: u16 = 512,
    //index: u16,
    display: [64][36]u1 = undefined,
    stack: std.BitStack,
    //delay: u8,
    //sound: u8,
    //registers: [16]u8,

    pub fn init(self: *chip8) void {
        const fonts = [80]u8{
            0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
            0x20, 0x60, 0x20, 0x20, 0x70, // 1
            0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
            0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
            0x90, 0x90, 0xF0, 0x10, 0x10, // 4
            0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
            0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
            0xF0, 0x10, 0x20, 0x40, 0x40, // 7
            0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
            0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
            0xF0, 0x90, 0xF0, 0x90, 0x90, // A
            0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
            0xF0, 0x80, 0x80, 0x80, 0xF0, // C
            0xE0, 0x90, 0x90, 0x90, 0xE0, // D
            0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
            0xF0, 0x80, 0xF0, 0x80, 0x80, // F
        };
        for (self.memory[80..160], fonts) |*value, font| {
            value.* = font;
        }
    }

    pub fn pc_return(self: *chip8) void {
        self.pc = 0;
        for (0..16) |_| {
            self.pc <<= 1;
            self.pc |= self.stack.pop();
            std.debug.print("{d}", .{self.pc});
        }
    }
    pub fn subroutine(self: *chip8, address: u12) void {
        var bit: u1 = 0;
        for (0..16) |_| {
            bit |= self.pc;
            self.pc >>= 1;
            self.stack.push(bit);
        }
        self.pc = address;
    }
};
