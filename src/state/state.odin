package state

import "../data"
import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

State :: struct {
    window:         ^sdl3.Window,
    gpu:            ^sdl3.GPUDevice,
    pipeline:       ^sdl3.GPUGraphicsPipeline,
    depth_texture:  ^sdl3.GPUTexture,
    vertex_buffer:  VertexBuffer,
    index_buffer:   IndexDataBuffer,
    texture_buffer: TextureBuffer,
}

free_state :: proc(s: ^State) {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.texture_buffer.transfer_buffer)
    for texture_data in s.texture_buffer.data {
        sdl3.DestroySurface(texture_data.surface)
        sdl3.ReleaseGPUTexture(s.gpu, texture_data.texture)
    }
    sdl3.ReleaseGPUSampler(s.gpu, s.texture_buffer.sampler)

    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.index_buffer.transfer_buffer)
    sdl3.ReleaseGPUBuffer(s.gpu, s.index_buffer.data)

    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.vertex_buffer.transfer_buffer)
    for vertex_data in s.vertex_buffer.data do sdl3.ReleaseGPUBuffer(s.gpu, vertex_data)

    sdl3.ReleaseGPUTexture(s.gpu, s.depth_texture)
    sdl3.ReleaseGPUGraphicsPipeline(s.gpu, s.pipeline)
    sdl3.DestroyGPUDevice(s.gpu)
    sdl3.DestroyWindow(s.window)
}

create_window :: proc(s: ^State, title: cstring, w, h: i32, flags: sdl3.WindowFlags) -> bool {
    s.window = sdl3.CreateWindow(title, w, h, flags)
    if s.window == nil {
        sdl3.Log("Couldn't create window: %s", sdl3.GetError())
        return false
    }
    if !sdl3.SetWindowRelativeMouseMode(s.window, true) {
        sdl3.Log("Couldn't set window relative mouse: %s", sdl3.GetError())
        return false
    }

    return true
}

create_gpu :: proc(s: ^State) -> bool {
    s.gpu = sdl3.CreateGPUDevice({.MSL}, true, nil)
    if s.gpu == nil {
        sdl3.Log("Couldn't create GPU device: %s", sdl3.GetError())
        return false
    }
    if !sdl3.ClaimWindowForGPUDevice(s.gpu, s.window) {
        sdl3.Log("Couldn't claim window for GPU device: %s", sdl3.GetError())
        return false
    }
    if !sdl3.SetGPUSwapchainParameters(s.gpu, s.window, .SDR, .IMMEDIATE) {
        sdl3.Log("Couldn't disable VSYNC")
        return false
    }

    return true
}

create_pipeline :: proc(s: ^State, vertex_shader, fragment_shader: ^sdl3.GPUShader) -> bool {
    color_target_description := sdl3.GPUColorTargetDescription {
        format = sdl3.GetGPUSwapchainTextureFormat(s.gpu, s.window),
        blend_state = {
            enable_blend = true,
            color_blend_op = .ADD,
            alpha_blend_op = .ADD,
            src_color_blendfactor = .SRC_ALPHA,
            dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
            src_alpha_blendfactor = .SRC_ALPHA,
            dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA,
        },
    }

    vertex_buffer_description := sdl3.GPUVertexBufferDescription {
        slot               = 0,
        input_rate         = .VERTEX,
        instance_step_rate = 0,
        pitch              = size_of(data.VertexData),
    }

    vertex_attributes, vertex_attributes_len := data.vertex_data_attributes()

    create_info := sdl3.GPUGraphicsPipelineCreateInfo {
        rasterizer_state = {fill_mode = .FILL, cull_mode = .BACK, front_face = .CLOCKWISE},
        target_info = {
            num_color_targets = 1,
            color_target_descriptions = &color_target_description,
            has_depth_stencil_target = true,
            depth_stencil_format = .D32_FLOAT,
        },
        primitive_type = .TRIANGLELIST,
        vertex_shader = vertex_shader,
        fragment_shader = fragment_shader,
        vertex_input_state = {
            num_vertex_buffers = 1,
            vertex_buffer_descriptions = &vertex_buffer_description,
            num_vertex_attributes = vertex_attributes_len,
            vertex_attributes = vertex_attributes,
        },
        depth_stencil_state = {compare_op = .LESS, enable_depth_test = true, enable_depth_write = true},
    }

    s.pipeline = sdl3.CreateGPUGraphicsPipeline(s.gpu, create_info)
    if s.pipeline == nil {
        sdl3.Log("Couldn't create graphics pipeline: %s", sdl3.GetError())
        return false
    }

    return true
}

create_sampler :: proc(s: ^State, create_info: sdl3.GPUSamplerCreateInfo) -> bool {
    s.texture_buffer.sampler = sdl3.CreateGPUSampler(s.gpu, create_info)
    if s.texture_buffer.sampler == nil {
        sdl3.Log("Couldn't create GPU sampler: %s", sdl3.GetError())
        return false
    }

    return true
}

bind_sampler :: proc(s: ^State, render_pass: ^sdl3.GPURenderPass) {
    bindings := make([^]sdl3.GPUTextureSamplerBinding, len(s.texture_buffer.data))
    for idx in 0 ..< len(s.texture_buffer.data) {
        bindings[idx] = sdl3.GPUTextureSamplerBinding {
            texture = s.texture_buffer.data[idx].texture,
            sampler = s.texture_buffer.sampler,
        }
    }

    sdl3.BindGPUFragmentSamplers(render_pass, 0, bindings, u32(len(s.texture_buffer.data)))
}

set_window_relative_mouse :: proc(s: ^State, enabled: bool) -> bool {
    if !enabled {
        win_size: [2]i32
        sdl3.GetWindowSize(s.window, &win_size.x, &win_size.y)

        sdl3.WarpMouseInWindow(s.window, f32(win_size.x) / 2, f32(win_size.y) / 2)
    }

    if !sdl3.SetWindowRelativeMouseMode(s.window, enabled) {
        sdl3.Log("Couldn't set window relative mouse: %s", sdl3.GetError())
        return false
    }

    return true
}
