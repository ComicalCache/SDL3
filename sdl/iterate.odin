package sdl

import "../data"
import "../state"
import "core:math/linalg"
import sdl3 "vendor:sdl3"

rot_speed := linalg.to_radians(f32(90))
angle := f32(0)

last_ticks := sdl3.GetTicks()

iterate :: proc(s: ^state.State) -> sdl3.AppResult {
    win_size: [2]i32
    sdl3.GetWindowSize(s.window, &win_size.x, &win_size.y)

    // Set rotation angle
    new_ticks := sdl3.GetTicks()
    delta_time := f32(new_ticks - last_ticks) / 1000
    last_ticks = new_ticks
    angle += rot_speed * delta_time
    uniform_data := data.mvp(
        angle,
        translation = {0, 0, -350},
        eye = {0, 200, 0},
        centre = {0, 0, -350},
        fov = linalg.to_radians(f32(60)),
        aspect = f32(win_size.x) / f32(win_size.y),
    )

    // Create GPU commands
    cmd_buffer := sdl3.AcquireGPUCommandBuffer(s.gpu)
    if cmd_buffer == nil {
        sdl3.Log("Couldn't get GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Map the data transfer buffer to the GPU
    if !state.map_vertex_buffer(s) { return .FAILURE }
    state.copy_to_vertex_buffer(s, 0, raw_data(data.VERTICES))
    state.unmap_vertex_buffer(s)

    // Map the index transfer buffer to the GPU
    if !state.map_index_buffer(s) { return .FAILURE }
    state.copy_to_index_buffer(s, raw_data(data.INDICES))
    state.unmap_index_buffer(s)

    // Map the texture transfer buffer to the GPU
    if !state.map_texture_data_buffer(s) {
        return .FAILURE
    }
    state.copy_to_texture_data_buffer(s, 0)
    state.unmap_texture_data_buffer(s)

    // Set depth
    state.set_depth_texture(s, u32(win_size.x), u32(win_size.y))

    // Begin copy pass
    copy_pass := sdl3.BeginGPUCopyPass(cmd_buffer)

    state.upload_vertex_buffer(s, copy_pass)
    state.upload_index_buffer(s, copy_pass)
    state.upload_texture_data_buffer(s, copy_pass)

    // End copy pass
    sdl3.EndGPUCopyPass(copy_pass)

    // Get swapchain texture
    swapchain_texture: ^sdl3.GPUTexture = nil
    if !sdl3.WaitAndAcquireGPUSwapchainTexture(cmd_buffer, s.window, &swapchain_texture, nil, nil) {
        sdl3.Log("Couldn't wait for and acquire GPU swapchain texture: %s", sdl3.GetError())
        return .FAILURE
    }
    if swapchain_texture == nil {
        // Window may be minimized
        return .CONTINUE
    }

    // Begin render pass
    render_pass := sdl3.BeginGPURenderPass(
        cmd_buffer,
        &(sdl3.GPUColorTargetInfo {
                texture = swapchain_texture,
                clear_color = {.11, .11, .11, 1},
                load_op = .CLEAR,
                store_op = .STORE,
            }),
        1,
        &(sdl3.GPUDepthStencilTargetInfo {
                texture = s.depth_texture,
                load_op = .CLEAR,
                clear_depth = 1,
                store_op = .DONT_CARE,
            }),
    )

    // Bind pipeline
    sdl3.BindGPUGraphicsPipeline(render_pass, s.pipeline)

    // Push uniform data
    sdl3.PushGPUVertexUniformData(cmd_buffer, 0, rawptr(&uniform_data), size_of(data.Uniform))

    state.bind_vertex_buffer(s, render_pass)
    state.bind_index_buffer(s, render_pass)
    state.bind_sampler(s, render_pass)

    // Draw pushed indices
    sdl3.DrawGPUIndexedPrimitives(render_pass, u32(len(data.INDICES)), 1, 0, 0, 0)

    // End render pass
    sdl3.EndGPURenderPass(render_pass)

    // Submit the command buffer
    if !sdl3.SubmitGPUCommandBuffer(cmd_buffer) {
        sdl3.Log("Couldn't submit the GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    return .CONTINUE
}
