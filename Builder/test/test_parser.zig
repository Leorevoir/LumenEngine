const std = @import("std");
const testing = std.testing;
const build_parser = @import("build-parser");
const parseModuleFile = build_parser.parseModuleFile;
const model = build_parser.model;

test "valid module file" {
    const source =
        \\module Core {
        \\    type = shared
        \\    language = cpp
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\    public_includes = [
        \\        "Public"
        \\    ]
        \\    defines = [
        \\        "LUMEN_ENGINE"
        \\    ]
        \\    deps = [ ]
        \\}
    ;

    var desc = try parseModuleFile(testing.allocator, source);
    defer desc.deinit(testing.allocator);

    try testing.expectEqualStrings("Core", desc.name);
    try testing.expectEqual(model.ModuleKind.shared, desc.kind);
    try testing.expectEqual(model.Language.cpp, desc.language);
    try testing.expectEqual(@as(usize, 1), desc.sources.len);
    try testing.expectEqualStrings("Private/*.cpp", desc.sources[0]);
    try testing.expectEqual(@as(usize, 1), desc.public_includes.len);
    try testing.expectEqualStrings("Public", desc.public_includes[0]);
    try testing.expectEqual(@as(usize, 1), desc.defines.len);
    try testing.expectEqualStrings("LUMEN_ENGINE", desc.defines[0]);
    try testing.expectEqual(@as(usize, 0), desc.deps.len);
}

test "module with dependencies" {
    const source =
        \\module VulkanRHI {
        \\    type = shared
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\    public_includes = [
        \\        "Public"
        \\    ]
        \\    defines = [
        \\        "LUMEN_ENGINE"
        \\    ]
        \\    deps = [ Core, Maths ]
        \\}
    ;

    var desc = try parseModuleFile(testing.allocator, source);
    defer desc.deinit(testing.allocator);

    try testing.expectEqualStrings("VulkanRHI", desc.name);
    try testing.expectEqual(@as(usize, 2), desc.deps.len);
    try testing.expectEqualStrings("Core", desc.deps[0]);
    try testing.expectEqualStrings("Maths", desc.deps[1]);
}

test "missing required field type" {
    const source =
        \\module Core {
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.MissingRequiredField, result);
}

test "missing required field sources" {
    const source =
        \\module Core {
        \\    type = shared
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.MissingRequiredField, result);
}

test "invalid enum value for type" {
    const source =
        \\module Core {
        \\    type = invalid
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.InvalidEnumValue, result);
}

test "invalid enum value for language" {
    const source =
        \\module Core {
        \\    type = shared
        \\    language = rust
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.InvalidEnumValue, result);
}

test "invalid list element type in sources" {
    const source =
        \\module Core {
        \\    type = shared
        \\    sources = [
        \\        identifier_instead_of_string
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.InvalidListElementType, result);
}

test "invalid list element type in deps" {
    const source =
        \\module Core {
        \\    type = shared
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\    deps = [ "string_instead_of_identifier" ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.InvalidListElementType, result);
}

test "duplicate field" {
    const source =
        \\module Core {
        \\    type = shared
        \\    type = static
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.DuplicateField, result);
}

test "syntax error - missing brace" {
    const source =
        \\module Core {
        \\    type = shared
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.UnexpectedToken, result);
}

test "syntax error - unterminated string" {
    const source =
        \\module Core {
        \\    type = shared
        \\    sources = [
        \\        "unterminated
        \\    ]
        \\}
    ;

    const result = parseModuleFile(testing.allocator, source);
    try testing.expectError(error.UnterminatedString, result);
}

test "default language is cpp" {
    const source =
        \\module Core {
        \\    type = shared
        \\    sources = [
        \\        "Private/*.cpp"
        \\    ]
        \\}
    ;

    var desc = try parseModuleFile(testing.allocator, source);
    defer desc.deinit(testing.allocator);

    try testing.expectEqual(model.Language.cpp, desc.language);
}

test "static module kind" {
    const source =
        \\module StaticLib {
        \\    type = static
        \\    sources = [
        \\        "src/*.cpp"
        \\    ]
        \\}
    ;

    var desc = try parseModuleFile(testing.allocator, source);
    defer desc.deinit(testing.allocator);

    try testing.expectEqual(model.ModuleKind.static, desc.kind);
}

test "executable module kind" {
    const source =
        \\module App {
        \\    type = executable
        \\    sources = [
        \\        "main.cpp"
        \\    ]
        \\}
    ;

    var desc = try parseModuleFile(testing.allocator, source);
    defer desc.deinit(testing.allocator);

    try testing.expectEqual(model.ModuleKind.executable, desc.kind);
}
