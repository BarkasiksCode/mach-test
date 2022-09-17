const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

pub const App = @This();

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
fragment_state: *const gpu.FragmentState,

fn create_vertex_state(vs_module: *gpu.ShaderModule) gpu.VertexState {
	return gpu.VertexState{
		.module = vs_module,
		.entry_point = "main",
	};
}

fn create_fragment_state(fs_module: *gpu.ShaderModule, targets: []const gpu.ColorTargetState) gpu.FragmentState {
	return gpu.FragmentState.init(.{
		.module = fs_module,
		.entry_point = "main",
		.targets = targets,
	});
}

fn create_color_target_state(swap_chain_format: gpu.Texture.Format) gpu.ColorTargetState {
	const blend = gpu.BlendState{};
	const color_target = gpu.ColorTargetState{
		.format = swap_chain_format,
		.blend = &blend,
		.write_mask = gpu.ColorWriteMaskFlags.all,
	};

	return color_target;
}

pub fn init(app: *App, core: *mach.Core) !void {
	std.debug.print("Init function called\n", .{});

	const fs_module = core.device.createShaderModuleWGSL("vert.wgsl", @embedFile("./frag.wgsl"));
	const vs_module = core.device.createShaderModuleWGSL("frag.wgsl", @embedFile("./vert.wgsl"));

	const color_target = create_color_target_state(core.swap_chain_format);

	const fragment = create_fragment_state(fs_module, &.{color_target});

	app.fragment_state = &fragment;

	const pipeline_descriptor = gpu.RenderPipeline.Descriptor {
		.fragment = &fragment,
		.vertex = create_vertex_state(vs_module)
	};

	std.debug.print("frag state before createRenderPipeline:\n{?}\n\n", .{app.fragment_state.*});

	app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
	app.queue = core.device.getQueue();

	std.debug.print("frag state after createRenderPipeline:\n{?}\n\n", .{app.fragment_state.*});

	vs_module.release();
	fs_module.release();
}

pub fn deinit(_: *App, _: *mach.Core) void {
	std.debug.print("Deinit function called\n", .{});
}

pub fn update(app: *App, core: *mach.Core) !void {

	std.debug.print("frag state during update:\n{?}\n\n", .{app.fragment_state.*});

	const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
	const color_attachment = gpu.RenderPassColorAttachment{
		.view = back_buffer_view,
		.clear_value = gpu.Color{
			.r = 0.1,
			.g = 0.1,
			.b = 0.1,
			.a = 1.0
		},
		.load_op = .clear,
		.store_op = .store,
	};

	const encoder = core.device.createCommandEncoder(null);
	const render_pass_info = gpu.RenderPassDescriptor.init(.{
		.color_attachments = &.{color_attachment},
	});
	const pass = encoder.beginRenderPass(&render_pass_info);
	pass.setPipeline(app.pipeline);
	pass.draw(3, 1, 0, 0);
	pass.end();
	pass.release();

	var command = encoder.finish(null);
	encoder.release();

	app.queue.submit(&.{command});
	command.release();

	core.swap_chain.?.present();
	back_buffer_view.release();
}
