const std = @import("std");
const testing = std.testing;
const gmf = @import("generate_matrix_float.zig");


fn  generate_scalar(min: f64, max: f64) f64 {
    var result: f64 = undefined;
    var rand = std.crypto.random;

    if (min > max) result = 0.0 
    else result = min + rand.float(f64) * (max - min);
    return result;
}
pub fn generate_vector(allocator: std.mem.Allocator, size: usize, min: f64, max: f64) ![]f64 {
    const result = try allocator.alloc(f64, size);
    
    for (result) |*n| n.* = generate_scalar(min, max);
    return result;
}
// pub fn print_scalar(scalar: f64, width: usize, precision: usize) void {
//     std.debug.print("{d: >[w].[p]}", .{ .d = scalar, .w = width, .p = precision });
// }

pub fn print_vector(vector: []f64, width: usize, precision: usize) void {
    std.debug.print("Vector: \n", .{});
    for (vector) |n| {
        gmf.print_scalar(n, width, precision);
    }
    std.debug.print("\n", .{});
}


test "test_vector" {
    const gpa = std.heap.page_allocator;
    const vector = try generate_vector(gpa, 8, 4, 10);
    defer gpa.free(vector);
    
    print_vector(vector);
    try testing.expectEqual(vector.len, 8);
}
