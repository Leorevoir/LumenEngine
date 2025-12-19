//
// @file: lib.zig
// @brief: library entry point for the Builder language
//

const std = @import("std");
const Parser = @import("parser.zig").Parser;
const Analyzer = @import("sema.zig").Analyzer;

pub const model = @import("model.zig");
pub const token = @import("token.zig");
pub const lexer = @import("lexer.zig");
pub const ast = @import("ast.zig");
pub const parser = @import("parser.zig");
pub const sema = @import("sema.zig");

pub const ParseError = @import("parser.zig").ParseError;
pub const SemanticError = @import("sema.zig").SemanticError;

//
// public
//

pub fn parseModuleFile(allocator: std.mem.Allocator, source: []const u8) !model.ModuleDesc {
    var p = try Parser.init(allocator, source);
    var module_node = try p.parse();
    defer module_node.deinit(allocator);

    var analyzer = Analyzer.init(allocator);
    return try analyzer.analyze(module_node);
}
