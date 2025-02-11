const std = @import("std");
const csr = @import("csr.zig");
const gmf = @import("generate_matrix_float.zig");
const gv = @import("generate_vector.zig");

pub fn  main() !void {
    // hyperparameters
    const gpa = std.heap.page_allocator;
    const size: usize = 5;
    const density_grade: f64 = 0.4;
    const min = -9.9;
    const max = 10.9;
    const width = 8;
    const precision = 2;

    // adjacency matrix
    const adjMatrix = try gmf.generate_matrix(gpa, size, density_grade, min, max);
    defer gmf.free_matrix(gpa, adjMatrix);
    gmf.print_matrix(adjMatrix, width, precision);

    // vector
    const vector = try gv.generate_vector(gpa, size, min, max);
    defer gpa.free(vector);

    // CSR
    
    
}