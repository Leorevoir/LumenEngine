//
// @file: lexer.zig
// @brief: defines the lexer for the Builder language
//

const std = @import("std");
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;

//
// public
//

pub const LexerError = error{
    UnexpectedCharacter,
    UnterminatedString,
};

pub const Lexer = struct {
    source: []const u8,
    position: usize,
    line: usize,
    column: usize,
    start_column: usize,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .position = 0,
            .line = 1,
            .column = 1,
            .start_column = 1,
        };
    }

    pub fn nextToken(self: *Lexer) LexerError!Token {
        self.skipWhitespace();

        if (self.isAtEnd()) {
            return self.makeToken(.eof, "");
        }

        self.start_column = self.column;
        const c = self.advance();

        switch (c) {
            '{' => return self.makeToken(.left_brace, "{"),
            '}' => return self.makeToken(.right_brace, "}"),
            '[' => return self.makeToken(.left_bracket, "["),
            ']' => return self.makeToken(.right_bracket, "]"),
            '=' => return self.makeToken(.equals, "="),
            ',' => return self.makeToken(.comma, ","),
            '"' => return try self.string(),
            else => {
                if (isAlpha(c) or c == '_') {
                    return self.identifier();
                }
                return error.UnexpectedCharacter;
            },
        }
    }

    fn isAtEnd(self: *const Lexer) bool {
        return self.position >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.position];
        self.position += 1;
        self.column += 1;
        return c;
    }

    fn peek(self: *const Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.position];
    }

    fn skipWhitespace(self: *Lexer) void {
        while (!self.isAtEnd()) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    self.column = 0;
                    _ = self.advance();
                },
                else => return,
            }
        }
    }

    fn string(self: *Lexer) LexerError!Token {
        const start = self.position;

        while (!self.isAtEnd() and self.peek() != '"') {
            if (self.peek() == '\n') {
                self.line += 1;
                self.column = 0;
            }
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return error.UnterminatedString;
        }

        const value = self.source[start..self.position];
        _ = self.advance();

        return self.makeToken(.string, value);
    }

    fn identifier(self: *Lexer) Token {
        const start = self.position - 1;

        while (!self.isAtEnd() and (isAlphaNumeric(self.peek()) or self.peek() == '_')) {
            _ = self.advance();
        }

        const text = self.source[start..self.position];
        const kind = if (std.mem.eql(u8, text, "module")) TokenKind.keyword_module else TokenKind.identifier;

        return self.makeToken(kind, text);
    }

    fn makeToken(self: *const Lexer, kind: TokenKind, lexeme: []const u8) Token {
        return .{
            .kind = kind,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.start_column,
        };
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlphaNumeric(c: u8) bool {
        return isAlpha(c) or isDigit(c);
    }
};
