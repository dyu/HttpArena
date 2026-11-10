const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});
    // workaround for the error `panic: option "target" declared twice`
    const target = b.graph.host;
    const optimize = .fast;

    const mimalloc = b.dependency("mimalloc", .{ .target = target, .optimize = optimize }).module("mimalloc");

    _ = @import("anole").addApp(b, .{
        .name = "anole-arena",
        .root_source_file = b.path("src/main.zig"),
        .imports = &.{.{ .name = "mimalloc", .module = mimalloc }},
        .protos = &.{.{ .name = "benchmark_pb", .file = b.path("proto/benchmark.proto") }},
    });
}
