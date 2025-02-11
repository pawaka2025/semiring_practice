const std = @import("std");
const math = std.math;

pub fn  generate_scalar(density_grade: f64, min: f64, max: f64) f64 {
    var rand = std.crypto.random;
    const threshold = rand.float(f64);

    if (min > max) return 0.0; // Ensure valid range

    // Generate a float within [min, max] if within density threshold
    return if (threshold < density_grade) 
        min + rand.float(f64) * (max - min) 
    else 
        0.0;
}

fn  generate_row(allocator: std.mem.Allocator, size: usize, row_index: usize, density_grade: f64, min: f64, max: f64) ![]f64 {
    const result = try allocator.alloc(f64, size); // Proper allocation with error propagation

    for (result) |*n | n.* = generate_scalar(density_grade, min, max);
    result[row_index] = 0;
    
    return result;
}
fn  free_row(allocator: std.mem.Allocator, array: []f64) void {
    allocator.free(array);
}

pub fn  generate_matrix(allocator: std.mem.Allocator, size: usize, density_grade: f64, min: f64, max: f64) ![][]f64 {
    const result:[][]f64 = try allocator.alloc([]f64, size);
    var row_index: usize = 0;

    for (result) |*n| {
        n.* = try generate_row(allocator,size, row_index, density_grade, min, max);
        row_index = row_index + 1;
    }

    return result;
}
pub fn  free_matrix(allocator: std.mem.Allocator, matrix: [][]f64) void {
    for (matrix) |row| free_row(allocator, row);
    allocator.free(matrix);
}

pub fn print_scalar(scalar: f64, width: usize, precision: usize) void {
    std.debug.print("{d: >[w].[p]}", .{ .d = scalar, .w = width, .p = precision });
}
pub fn print_row(row: []f64, width: usize, precision: usize) void {
    for (row) |*n| print_scalar(n.*, width, precision);
    std.debug.print("\n", .{});
}
pub fn print_matrix(matrix: [][]f64, width: usize, precision: usize) void {
    std.debug.print("Adjacency matrix: \n", .{});
    for (matrix) |*n| print_row(n.*, width, precision);
}