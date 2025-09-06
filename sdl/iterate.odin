package sdl

import "../data"
import "core:math/linalg"
import sdl3 "vendor:sdl3"

rot_speed := linalg.to_radians(f32(90))
angle := f32(0)

last_ticks := sdl3.GetTicks()

iterate :: proc(state: ^data.State) -> sdl3.AppResult {
    win_size: [2]i32
    sdl3.GetWindowSize(state.window, &win_size.x, &win_size.y)

    // Set rotation angle
    new_ticks := sdl3.GetTicks()
    delta_time := f32(new_ticks - last_ticks) / 1000
    last_ticks = new_ticks
    angle += rot_speed * delta_time
    uniform_data := data.mvp(
        angle,
        {0, 0, -300},
        {0, 0, -0},
        {0, 0, -300},
        linalg.to_radians(f32(60)),
        f32(win_size.x) / f32(win_size.y),
    )

    // Create GPU commands
    cmd_buffer := sdl3.AcquireGPUCommandBuffer(state.gpu)
    if cmd_buffer == nil {
        sdl3.Log("Couldn't get GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Map the data transfer buffer to the GPU
    if !data.map_vertex_buffer(state) { return .FAILURE }
    data.copy_to_vertex_buffer(state, 0, rawptr(&data.VERTICES))
    data.unmap_vertex_buffer(state)

    // Map the index transfer buffer to the GPU
    if !data.map_index_buffer(state) { return .FAILURE }
    data.copy_to_index_buffer(state, rawptr(&data.INDICES))
    data.unmap_index_buffer(state)

    // Map the texture transfer buffer to the GPU
    if !data.map_texture_data_buffer(state) {
        return .FAILURE
    }
    data.copy_to_texture_data_buffer(state, 0)
    data.unmap_texture_data_buffer(state)

    // Begin copy pass
    copy_pass := sdl3.BeginGPUCopyPass(cmd_buffer)

    data.upload_vertex_buffer(state, copy_pass)
    data.upload_index_buffer(state, copy_pass)
    data.upload_texture_data_buffer(state, copy_pass)

    // End copy pass
    sdl3.EndGPUCopyPass(copy_pass)

    // Get swapchain texture
    swapchain_texture: ^sdl3.GPUTexture = nil
    if !sdl3.WaitAndAcquireGPUSwapchainTexture(cmd_buffer, state.window, &swapchain_texture, nil, nil) {
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
        nil,
    )

    // Bind pipeline
    sdl3.BindGPUGraphicsPipeline(render_pass, state.pipeline)

    // Push uniform data
    sdl3.PushGPUVertexUniformData(cmd_buffer, 0, rawptr(&uniform_data), size_of(data.Uniform))

    data.bind_vertex_buffer(state, render_pass)
    data.bind_index_buffer(state, render_pass)
    data.bind_sampler(state, render_pass)

    // Draw pushed indices
    sdl3.DrawGPUIndexedPrimitives(render_pass, len(data.INDICES), 1, 0, 0, 0)

    // End render pass
    sdl3.EndGPURenderPass(render_pass)

    // Submit the command buffer
    if !sdl3.SubmitGPUCommandBuffer(cmd_buffer) {
        sdl3.Log("Couldn't submit the GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    return .CONTINUE
}
