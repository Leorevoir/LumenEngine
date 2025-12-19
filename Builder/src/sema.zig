//
// @file: sema.zig
// @brief: semantic analyzer for the Builder language
//

const std = @import("std");
const ast = @import("ast.zig");
const model = @import("model.zig");

//
// public
//

pub const SemanticError = error{
    MissingRequiredField,
    InvalidEnumValue,
    InvalidListElementType,
    DuplicateField,
    InvalidFieldValue,
    OutOfMemory,
};

pub const Analyzer = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Analyzer {
        return .{ .allocator = allocator };
    }

    pub fn analyze(self: *Analyzer, module_node: ast.ModuleNode) SemanticError!model.ModuleDesc {
        var type_field: ?[]const u8 = null;
        var language_field: ?[]const u8 = null;
        var sources_field: ?[][]const u8 = null;
        var public_includes_field: ?[][]const u8 = null;
        var defines_field: ?[][]const u8 = null;
        var deps_field: ?[][]const u8 = null;
        errdefer {
            if (sources_field) |s| {
                for (s) |item| self.allocator.free(item);
                self.allocator.free(s);
            }
            if (public_includes_field) |p| {
                for (p) |item| self.allocator.free(item);
                self.allocator.free(p);
            }
            if (defines_field) |d| {
                for (d) |item| self.allocator.free(item);
                self.allocator.free(d);
            }
            if (deps_field) |dep| {
                for (dep) |item| self.allocator.free(item);
                self.allocator.free(dep);
            }
        }

        var seen_fields = std.StringHashMap(void).init(self.allocator);
        defer seen_fields.deinit();

        for (module_node.fields) |field| {
            if (seen_fields.contains(field.name)) {
                return error.DuplicateField;
            }
            try seen_fields.put(field.name, {});

            if (std.mem.eql(u8, field.name, "type")) {
                type_field = try self.extractIdentifier(field.value);
            } else if (std.mem.eql(u8, field.name, "language")) {
                language_field = try self.extractIdentifier(field.value);
            } else if (std.mem.eql(u8, field.name, "sources")) {
                sources_field = try self.extractStringList(field.value);
            } else if (std.mem.eql(u8, field.name, "public_includes")) {
                public_includes_field = try self.extractStringList(field.value);
            } else if (std.mem.eql(u8, field.name, "defines")) {
                defines_field = try self.extractStringList(field.value);
            } else if (std.mem.eql(u8, field.name, "deps")) {
                deps_field = try self.extractIdentifierList(field.value);
            }
        }

        const type_str = type_field orelse return error.MissingRequiredField;
        const language_str = language_field orelse "cpp";
        const sources = sources_field orelse return error.MissingRequiredField;

        const kind = self.parseModuleKind(type_str) catch return error.InvalidEnumValue;
        const language = self.parseLanguage(language_str) catch return error.InvalidEnumValue;

        const public_includes = public_includes_field orelse try self.allocator.alloc([]const u8, 0);
        const defines = defines_field orelse try self.allocator.alloc([]const u8, 0);
        const deps = deps_field orelse try self.allocator.alloc([]const u8, 0);

        const name = try self.allocator.dupe(u8, module_node.name);

        return .{
            .name = name,
            .kind = kind,
            .language = language,
            .sources = sources,
            .public_includes = public_includes,
            .defines = defines,
            .deps = deps,
        };
    }

    fn extractIdentifier(_: *Analyzer, value: ast.ValueNode) SemanticError![]const u8 {
        switch (value) {
            .identifier => |id| return id,
            else => return error.InvalidFieldValue,
        }
    }

    fn extractStringList(self: *Analyzer, value: ast.ValueNode) SemanticError![][]const u8 {
        switch (value) {
            .list => |items| {
                var result = try self.allocator.alloc([]const u8, items.len);
                for (items, 0..) |item, i| {
                    switch (item) {
                        .string => |s| {
                            result[i] = try self.allocator.dupe(u8, s);
                        },
                        else => {
                            for (result[0..i]) |s| self.allocator.free(s);
                            self.allocator.free(result);
                            return error.InvalidListElementType;
                        },
                    }
                }
                return result;
            },
            else => return error.InvalidFieldValue,
        }
    }

    fn extractIdentifierList(self: *Analyzer, value: ast.ValueNode) SemanticError![][]const u8 {
        switch (value) {
            .list => |items| {
                var result = try self.allocator.alloc([]const u8, items.len);
                for (items, 0..) |item, i| {
                    switch (item) {
                        .identifier => |id| {
                            result[i] = try self.allocator.dupe(u8, id);
                        },
                        else => {
                            for (result[0..i]) |s| self.allocator.free(s);
                            self.allocator.free(result);
                            return error.InvalidListElementType;
                        },
                    }
                }
                return result;
            },
            else => return error.InvalidFieldValue,
        }
    }

    fn parseModuleKind(_: *Analyzer, str: []const u8) !model.ModuleKind {
        if (std.mem.eql(u8, str, "shared")) return .shared;
        if (std.mem.eql(u8, str, "static")) return .static;
        if (std.mem.eql(u8, str, "executable")) return .executable;
        return error.InvalidEnumValue;
    }

    fn parseLanguage(_: *Analyzer, str: []const u8) !model.Language {
        if (std.mem.eql(u8, str, "cpp")) return .cpp;
        return error.InvalidEnumValue;
    }
};
