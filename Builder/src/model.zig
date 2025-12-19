//
// @file: model.zig
// @brief: model database
//

const std = @import("std");

//
// public
//

pub const ModuleKind = enum {
    shared,
    static,
    executable,
};

pub const Language = enum {
    cpp,
};

pub const ModuleDesc = struct {
    name: []const u8,
    kind: ModuleKind,
    language: Language,
    sources: [][]const u8,
    public_includes: [][]const u8,
    defines: [][]const u8,
    deps: [][]const u8,

    pub fn deinit(self: *ModuleDesc, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        for (self.sources) |s| allocator.free(s);
        allocator.free(self.sources);
        for (self.public_includes) |s| allocator.free(s);
        allocator.free(self.public_includes);
        for (self.defines) |s| allocator.free(s);
        allocator.free(self.defines);
        for (self.deps) |s| allocator.free(s);
        allocator.free(self.deps);
    }
};
