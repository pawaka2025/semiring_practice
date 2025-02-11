const std = @import("std");

/// Basic sparse matrix in CSR form, heap-allocated.
pub const CSR = struct {
    /// Heap memory allocator.
    allocator: std.mem.Allocator,
    /// Number of rows in the matrix.
    rows: usize,
    /// Number of columns in the matrix.
    cols: usize,
    /// Array of nonzero values.
    nonzeroes: []f64,
    /// Array of columns these nonzero values are located at.
    colIndices: []usize,
    /// Cumulative numbers of rows occupied by non-zero values.
    rowPointers: []usize,

    /// Initiates an instance of this object. 
    /// All fields are heap-allocated except 'rows' and 'cols' because they are
    /// zero-dimensional objects, thus only scale at O(1) even at very large struct sizes.
    /// Heap-allocating them wastes computational time. We need this struct to be as fast as possible.
    pub fn init(
        allocator: std.mem.Allocator,
        rows: usize,
        cols: usize,
        nonzeroes: []const f64,
        colIndices: []const usize,
        rowPointers: []const usize,
    ) !CSR {

        // Allocate memory for the CSR arrays
        const nonzeroes_ = try allocator.alloc(f64, nonzeroes.len);
        @memcpy(nonzeroes_, nonzeroes);
        const colIndices_ = try allocator.alloc(usize, colIndices.len);
        @memcpy(colIndices_, colIndices);
        const rowPointers_ = try allocator.alloc(usize, rowPointers.len);
        @memcpy(rowPointers_, rowPointers);

        // Copy the input data into the allocated arrays
        return .{
            .allocator = allocator,
            .rows = rows,
            .cols = cols,
            .nonzeroes = nonzeroes_,
            .colIndices = colIndices_,
            .rowPointers = rowPointers_,
        };
    }

    /// Deallocs this struct. Always call this after use.
    /// Idempotency built in to prevent undefined behavior from calling this twice.
    pub fn deinit(self: *CSR) void {
        if (self.nonzeroes.len > 0) {
            self.allocator.free(self.nonzeroes);
            self.nonzeroes = &[_]f64{};
        }
        if (self.colIndices.len > 0) {
            self.allocator.free(self.colIndices);
            self.colIndices = &[_]usize{};
        }
        if (self.rowPointers.len > 0) {
            self.allocator.free(self.rowPointers);
            self.rowPointers = &[_]usize{};
        }
    }

    /// Init with an adjacency matrix directly to allow using much larger datasets.
    pub fn init_with_adjMatrix(allocator: std.mem.Allocator, adjMatrix: [][] f64) !CSR {
        return .{
            .allocator = allocator,
            .rows = adjMatrix.len,
            .cols = if (adjMatrix.len > 0) adjMatrix[0].len else 0,
            .nonzeroes = try create_nonzeroes(allocator, adjMatrix),
            .colIndices = try create_column_index(allocator, adjMatrix),
            .rowPointers = try create_row_pointers(allocator, adjMatrix),
        };
    }

    pub fn print(self: CSR) void {
        std.debug.print("CSR Matrix: rows = {}, cols = {}\n", .{self.rows, self.cols});
        std.debug.print("Nonzero values: {d:.1}\n", .{self.nonzeroes});
        std.debug.print("Column indices: {d:.1}\n", .{self.colIndices}); 
        std.debug.print("Row pointers cumulative count: {d:.1}\n", .{self.rowPointers});
    }

    pub fn spmmv(
        self: *CSR, vector: [] f64, result: []f64) void {
        // Ensure the result vector is zeroed out before accumulation
        for (result) |*r| {
            r.* = 0.0;
        }

        // Iterate over each row of the CSR matrix
        for (0..self.rows) |i| {
        // Row range in the CSR format
        const row_start = self.rowPointers[i];
        const row_end = self.rowPointers[i + 1];

        // Perform dot product of the row with the vector
        var sum: f64 = 0.0;
        for (row_start..row_end) |j| {
            sum += self.nonzeroes[j] * vector[self.colIndices[j]];
        }
        
        // Store result
        result[i] = sum;
        }
    }

};

/// Derive a data array, consisting of non-zero values.
/// ex: 
/// 0 2 0 0 3
/// 2 0 4 5 0 
/// 0 4 0 6 0
/// 0 5 6 0 7
/// 3 0 0 7 0
/// becomes [2, 3, 2, 4, 5, 4, 6, 5, 6, 7, 3, 7]
fn create_nonzeroes(allocator: std.mem.Allocator, adjMatrix: [][] f64) ![]f64 {
    var data = std.ArrayList(f64).init(allocator);

    for (adjMatrix) |row| {
        for (row) |value| {
            if (value != 0) {
                try data.append(value);
            }
        }
    }

    return data.toOwnedSlice();
}

/// Derive a column index array, consisting of columns these non-zero values are located at:
/// ex: 
/// 0 2 0 0 3
/// 2 0 4 5 0 
/// 0 4 0 6 0
/// 0 5 6 0 7
/// 3 0 0 7 0
/// becomes [1, 4, 0, 2, 3, 1, 3, 1, 2, 4, 0, 3]
fn create_column_index(allocator: std.mem.Allocator, adjMatrix: [][] f64) ![]usize {
    var column_indices = std.ArrayList(usize).init(allocator);

    for (adjMatrix) |row| {
        for (row, 0..) |value, col| {
            if (value != 0) {
                try column_indices.append(col);
            }
        }
    }

    return column_indices.toOwnedSlice();
}

///Derive a row pointers array, consisting of cumulative numbers of rows occupied by non-zero values
///We need to add an extra element on the front consisting of the value 0.
/// 0 2 0 0 3
/// 2 0 4 5 0 
/// 0 4 0 6 0
/// 0 5 6 0 7
/// 3 0 0 7 0
/// becomes [0, 2, 5, 7, 10, 12]
fn create_row_pointers(allocator: std.mem.Allocator, adjMatrix: [][] f64) ![]usize {
    var row_pointers = std.ArrayList(usize).init(allocator);
    try row_pointers.append(0); // Start with 0

    var cumulative_count: usize = 0;

    for (adjMatrix) |row| {
        for (row) |value| {
            if (value != 0) {
                cumulative_count += 1;
            }
        }
        try row_pointers.append(cumulative_count);
    }

    return row_pointers.toOwnedSlice();
}

// const gmf = @import("generate_matrix_float.zig");
