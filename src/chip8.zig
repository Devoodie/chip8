const std = @import("std");

pub const chip8 = struct {
    memory: [4096]u8 = undefined,
    pc: u16 = 512,
    index: u16 = 0,
    display: [32][64]u1 = undefined,
    stack: std.ArrayList(u16),
    //delay: u8,
    //sound: u8,
    registers: [16]u8 = undefined,

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
    //     An entire function is not needed for these two operations due to the change in datastructure from BitStack to ArrayList, but outsourcing these lines into functions help with the zig testing system.
    //    pub fn pc_return(self: *chip8) void {
    //        self.pc = self.stack.pop();
    //       std.debug.print("{d}", .{self.pc});
    //   }
    //   pub fn subroutine(self: *chip8, address: u16) void {
    //       self.stack.append(self.pc);
    //        self.pc = address;
    //   }
};
