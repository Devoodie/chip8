const std = @import("std");
const chip8 = @import("chip8.zig");

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

    std.debug.print("{s}", .{virtual_machine.memory});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
