const std = @import("std");

const Pkg = std.build.Pkg;

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
	const mode = b.standardReleaseOptions();

	const name = "app";
	const mach = @import("lib/mach/build.zig");
	const example_app = mach.App.init(
		b,
		.{
			.name = name,
			.src = "src/main.zig",
			.target = target,
			.deps = &[_]Pkg{ },
		},
	);
	example_app.setBuildMode(mode);
	example_app.link(.{});

	const compile_step = b.step("compile-" ++ name, "Compile " ++ name);
	compile_step.dependOn(&b.addInstallArtifact(example_app.step).step);
	b.getInstallStep().dependOn(compile_step);

	const run_cmd = example_app.run();
	run_cmd.dependOn(compile_step);

	const run_step = b.step(name, "Run " ++ name);
	run_step.dependOn(run_cmd);
}
