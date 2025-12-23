//
// @file: build.zig
// @brief: build script for the parser library
//

const std = @import("std");

//
// public
//

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = createLibraryModule(b, target, optimize);
    const lib = createLibrary(b, lib_mod);

    b.installArtifact(lib);

    addTestsStep(b, lib_mod, target, optimize);
    addCleanStep(b);
    addHelpStep(b);
}

//
// private
//

fn createLibraryModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
}

fn createLibrary(
    b: *std.Build,
    lib_mod: *std.Build.Module,
) *std.Build.Step.Compile {
    return b.addLibrary(.{
        .name = "build-parser",
        .root_module = lib_mod,
    });
}

fn addTestsStep(
    b: *std.Build,
    lib_mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/test_parser.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    tests.root_module.addImport("build-parser", lib_mod);

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("tests", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}

fn addCleanStep(b: *std.Build) void {
    const clean_step = b.step("clean", "Remove build artifacts");

    const clean_run = b.addSystemCommand(&[_][]const u8{
        "rm", "-rf", "zig-cache", "zig-out",
    });

    clean_step.dependOn(&clean_run.step);
}

fn addHelpStep(b: *std.Build) void {
    const help_step = b.step("help", "Show help information");

    const help_run = b.addSystemCommand(&[_][]const u8{
        "echo",
        "USAGE:\n" ++
            "  zig build         - Build the library (default)\n" ++
            "  zig build tests   - Run unit tests\n" ++
            "  zig build clean   - Remove build artifacts\n" ++
            "  zig build help    - Show this help\n",
    });

    help_step.dependOn(&help_run.step);
}
