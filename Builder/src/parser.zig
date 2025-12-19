//
// @file: parser.zig
// @brief: parser for the Builder language
//

const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const LexerError = @import("lexer.zig").LexerError;
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const ast = @import("ast.zig");

pub const ParseError = error{
    UnexpectedToken,
    ExpectedModuleKeyword,
    ExpectedIdentifier,
    ExpectedLeftBrace,
    ExpectedRightBrace,
    ExpectedEquals,
    ExpectedString,
    ExpectedLeftBracket,
    ExpectedRightBracket,
    EmptyList,
    OutOfMemory,
} || LexerError;

pub const Parser = struct {
    lexer: Lexer,
    current: Token,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) ParseError!Parser {
        var lexer = Lexer.init(source);
        const current = try lexer.nextToken();
        return .{
            .lexer = lexer,
            .current = current,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) ParseError!ast.ModuleNode {
        return try self.parseModule();
    }

    fn parseModule(self: *Parser) ParseError!ast.ModuleNode {
        try self.expect(.keyword_module);
        const name = try self.expectIdentifier();
        try self.expect(.left_brace);

        var fields = try std.ArrayList(ast.FieldNode).initCapacity(self.allocator, 8);
        errdefer {
            for (fields.items) |*field| {
                field.deinit(self.allocator);
            }
            fields.deinit(self.allocator);
        }

        while (self.current.kind != .right_brace and self.current.kind != .eof) {
            const field = try self.parseField();
            try fields.append(self.allocator, field);
        }

        try self.expect(.right_brace);

        const result = try fields.toOwnedSlice(self.allocator);
        return .{
            .name = name,
            .fields = result,
        };
    }

    fn parseField(self: *Parser) ParseError!ast.FieldNode {
        const line = self.current.line;
        const column = self.current.column;
        const name = try self.expectIdentifier();
        try self.expect(.equals);
        const value = try self.parseValue();

        return .{
            .name = name,
            .value = value,
            .line = line,
            .column = column,
        };
    }

    fn parseValue(self: *Parser) ParseError!ast.ValueNode {
        switch (self.current.kind) {
            .string => {
                const value = self.current.lexeme;
                try self.advance();
                return ast.ValueNode{ .string = value };
            },
            .identifier => {
                const value = self.current.lexeme;
                try self.advance();
                return ast.ValueNode{ .identifier = value };
            },
            .left_bracket => {
                return try self.parseList();
            },
            else => return error.UnexpectedToken,
        }
    }

    fn parseList(self: *Parser) ParseError!ast.ValueNode {
        try self.expect(.left_bracket);

        var items = try std.ArrayList(ast.ValueNode).initCapacity(self.allocator, 4);
        errdefer {
            for (items.items) |*item| {
                item.deinit(self.allocator);
            }
            items.deinit(self.allocator);
        }

        if (self.current.kind == .right_bracket) {
            try self.advance();
            const result = try items.toOwnedSlice(self.allocator);
            return ast.ValueNode{ .list = result };
        }

        while (true) {
            const item = try self.parseValue();
            try items.append(self.allocator, item);

            if (self.current.kind == .comma) {
                try self.advance();
            } else {
                break;
            }
        }

        try self.expect(.right_bracket);

        const result = try items.toOwnedSlice(self.allocator);
        return ast.ValueNode{ .list = result };
    }

    fn advance(self: *Parser) ParseError!void {
        self.current = try self.lexer.nextToken();
    }

    fn expect(self: *Parser, kind: TokenKind) ParseError!void {
        if (self.current.kind != kind) {
            return error.UnexpectedToken;
        }
        try self.advance();
    }

    fn expectIdentifier(self: *Parser) ParseError![]const u8 {
        if (self.current.kind != .identifier) {
            return error.ExpectedIdentifier;
        }
        const lexeme = self.current.lexeme;
        try self.advance();
        return lexeme;
    }
};
