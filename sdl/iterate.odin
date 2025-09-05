package sdl

import "core:math/linalg"
import sdl3 "vendor:sdl3"

import "../data"

rot_speed := linalg.to_radians(f32(90))
angle := f32(0)

last_ticks := sdl3.GetTicks()

@(require_results)
iterate :: proc(
    window: ^sdl3.Window,
    gpu: ^sdl3.GPUDevice,
    pipeline: ^sdl3.GPUGraphicsPipeline,
    vertex_buffer, index_buffer: ^sdl3.GPUBuffer,
    transfer_buffer: ^sdl3.GPUTransferBuffer,
) -> sdl3.AppResult {
    win_size: [2]i32
    sdl3.GetWindowSize(window, &win_size.x, &win_size.y)

    // Set rotation angle
    new_ticks := sdl3.GetTicks()
    delta_time := f32(new_ticks - last_ticks) / 1000
    last_ticks = new_ticks
    angle += rot_speed * delta_time
    uniform_data := data.mvp(
        angle,
        {0, 0, -100},
        {0, 0, -0},
        {0, 0, -100},
        linalg.to_radians(f32(60)),
        f32(win_size.x) / f32(win_size.y),
    )

    // Create GPU commands
    cmd_buffer := sdl3.AcquireGPUCommandBuffer(gpu)
    if cmd_buffer == nil {
        sdl3.Log("Couldn't get GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Map the transfer buffer to the GPU
    mapped_transfer_buffer := transmute([^]byte)sdl3.MapGPUTransferBuffer(gpu, transfer_buffer, false)
    if mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the transfer buffer: %s", sdl3.GetError())
        return .FAILURE
    }
    sdl3.memcpy(mapped_transfer_buffer, rawptr(&data.VERTICES), data.VERTICES_BYTE_LEN)
    sdl3.memcpy(mapped_transfer_buffer[data.VERTICES_BYTE_LEN:], rawptr(&data.INDICES), data.INDICES_BYTE_LEN)
    sdl3.UnmapGPUTransferBuffer(gpu, transfer_buffer)

    // Begin copy pass
    copy_pass := sdl3.BeginGPUCopyPass(cmd_buffer)

    // Copy our vertices
    sdl3.UploadToGPUBuffer(
        copy_pass,
        {transfer_buffer = transfer_buffer, offset = 0},
        {buffer = vertex_buffer, offset = 0, size = u32(data.VERTICES_BYTE_LEN)},
        false,
    )

    // Copy our indices
    sdl3.UploadToGPUBuffer(
        copy_pass,
        {transfer_buffer = transfer_buffer, offset = u32(data.VERTICES_BYTE_LEN)},
        {buffer = index_buffer, offset = 0, size = u32(data.INDICES_BYTE_LEN)},
        false,
    )

    // End copy pass
    sdl3.EndGPUCopyPass(copy_pass)

    // Get swapchain texture
    texture: ^sdl3.GPUTexture = nil
    if !sdl3.WaitAndAcquireGPUSwapchainTexture(cmd_buffer, window, &texture, nil, nil) {
        sdl3.Log("Couldn't wait for and acquire GPU swapchain texture: %s", sdl3.GetError())
        return .FAILURE
    }
    if texture == nil {
        // Window may be minimized
        return .CONTINUE
    }

    // Begin render pass
    render_pass := sdl3.BeginGPURenderPass(
        cmd_buffer,
        &(sdl3.GPUColorTargetInfo {
                texture = texture,
                clear_color = {.11, .11, .11, 1},
                load_op = .CLEAR,
                store_op = .STORE,
            }),
        1,
        nil,
    )

    // Bind pipeline
    sdl3.BindGPUGraphicsPipeline(render_pass, pipeline)

    // Push uniform data
    sdl3.PushGPUVertexUniformData(cmd_buffer, 0, rawptr(&uniform_data), size_of(data.Uniform))

    // Bind vertex data
    sdl3.BindGPUVertexBuffers(render_pass, 0, &(sdl3.GPUBufferBinding{buffer = vertex_buffer, offset = 0}), 1)

    // Bind indices data
    sdl3.BindGPUIndexBuffer(render_pass, {buffer = index_buffer}, ._16BIT)

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
