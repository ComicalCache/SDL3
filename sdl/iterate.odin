package sdl

import "core:math/linalg"
import "core:text/edit"
import "core:text/i18n"
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
    transfer_buffer: ^sdl3.GPUTransferBuffer,
    vertex_buffer: ^sdl3.GPUBuffer,
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
        {0, 0, -50},
        {0, 0, -0},
        {0, 0, -50},
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
    vertex_ptr := sdl3.MapGPUTransferBuffer(gpu, transfer_buffer, false)
    sdl3.memcpy(vertex_ptr, rawptr(&data.VERTICES), size_of(data.Vertex) * len(data.VERTICES))
    sdl3.UnmapGPUTransferBuffer(gpu, transfer_buffer)

    // Begin copy pass
    copy_pass := sdl3.BeginGPUCopyPass(cmd_buffer)

    // Copy our vertices
    source_buffer := sdl3.GPUTransferBufferLocation {
        transfer_buffer = transfer_buffer,
        offset          = 0,
    }
    target_buffer := sdl3.GPUBufferRegion {
        buffer = vertex_buffer,
        offset = 0,
        size   = size_of(data.Vertex) * len(data.VERTICES),
    }
    sdl3.UploadToGPUBuffer(copy_pass, source_buffer, target_buffer, false)

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

    // Set clear color
    color_target_info := sdl3.GPUColorTargetInfo {
        texture     = texture,
        clear_color = {.11, .11, .11, 1},
        load_op     = .CLEAR,
        store_op    = .STORE,
    }

    // Begin render pass
    render_pass := sdl3.BeginGPURenderPass(cmd_buffer, &color_target_info, 1, nil)

    // Bind pipeline
    sdl3.BindGPUGraphicsPipeline(render_pass, pipeline)

    // Push uniform data
    sdl3.PushGPUVertexUniformData(cmd_buffer, 0, rawptr(&uniform_data), size_of(data.Uniform))

    // Bind vertex data
    vertex_buffer_binding := sdl3.GPUBufferBinding {
        buffer = vertex_buffer,
        offset = 0,
    }
    sdl3.BindGPUVertexBuffers(render_pass, 0, &vertex_buffer_binding, 1)

    // Draw pushed data
    sdl3.DrawGPUPrimitives(render_pass, len(data.VERTICES), 1, 0, 0)

    // End render pass
    sdl3.EndGPURenderPass(render_pass)

    // Submit the command buffer
    if !sdl3.SubmitGPUCommandBuffer(cmd_buffer) {
        sdl3.Log("Couldn't submit the GPU command buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    return .CONTINUE
}
