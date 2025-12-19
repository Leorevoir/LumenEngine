//
// @file: ast.zig
// @brief: defines the AST nodes for the Builder language
//

const std = @import("std");

//
// public
//

pub const ValueNode = union(enum) {
    string: []const u8,
    identifier: []const u8,
    list: []ValueNode,

    pub fn deinit(self: *ValueNode, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .list => |list| {
                for (list) |*item| {
                    item.deinit(allocator);
                }
                allocator.free(list);
            },
            else => {},
        }
    }
};

pub const FieldNode = struct {
    name: []const u8,
    value: ValueNode,
    line: usize,
    column: usize,

    pub fn deinit(self: *FieldNode, allocator: std.mem.Allocator) void {
        self.value.deinit(allocator);
    }
};

pub const ModuleNode = struct {
    name: []const u8,
    fields: []FieldNode,

    pub fn deinit(self: *ModuleNode, allocator: std.mem.Allocator) void {
        for (self.fields) |*field| {
            field.deinit(allocator);
        }
        allocator.free(self.fields);
    }
};
