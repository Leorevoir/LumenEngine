//
// @file: token.zig
// @brief: token definitions for the Builder language
//

const std = @import("std");

//
// public
//

pub const TokenKind = enum {
    identifier,
    string,
    left_brace,
    right_brace,
    left_bracket,
    right_bracket,
    equals,
    comma,
    keyword_module,
    eof,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    line: usize,
    column: usize,
};
