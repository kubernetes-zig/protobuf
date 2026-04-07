const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Runtime library module — this is what consumers import
    const module = b.addModule("protobuf", .{
        .root_source_file = b.path("src/protobuf.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Static library
    const lib = b.addLibrary(.{
        .name = "zig-protobuf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/protobuf.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });
    b.installArtifact(lib);

    // protoc-gen-zig generator executable
    const gen_module = b.createModule(.{
        .root_source_file = b.path("bootstrapped-generator/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    gen_module.addImport("protobuf", module);

    const gen_exe = b.addExecutable(.{
        .name = "protoc-gen-zig",
        .root_module = gen_module,
    });
    b.installArtifact(gen_exe);

    // Tests — runtime only
    const test_step = b.step("test", "Run runtime library tests");
    const mod_tests = b.addTest(.{ .root_module = module });
    test_step.dependOn(&b.addRunArtifact(mod_tests).step);
}
