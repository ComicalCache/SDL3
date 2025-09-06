package data

import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

DataBuffer :: struct {
    transfer_buffer:        ^sdl3.GPUTransferBuffer,
    mapped_transfer_buffer: [^]byte,
    data:                   [dynamic]^sdl3.GPUBuffer,
    data_len:               [dynamic]u32,
}

IndexDataBuffer :: struct {
    transfer_buffer:        ^sdl3.GPUTransferBuffer,
    mapped_transfer_buffer: [^]byte,
    data:                   ^sdl3.GPUBuffer,
    data_len:               u32,
}

TextureData :: struct {
    surface: ^sdl3.Surface,
    texture: ^sdl3.GPUTexture,
}

TextureBuffer :: struct {
    sampler:                ^sdl3.GPUSampler,
    transfer_buffer:        ^sdl3.GPUTransferBuffer,
    mapped_transfer_buffer: [^]byte,
    data:                   [dynamic]TextureData,
    data_len:               [dynamic]u32,
}

State :: struct {
    window:         ^sdl3.Window,
    gpu:            ^sdl3.GPUDevice,
    pipeline:       ^sdl3.GPUGraphicsPipeline,
    vertex_buffer:  DataBuffer,
    index_buffer:   IndexDataBuffer,
    texture_buffer: TextureBuffer,
}

clean_up :: proc(state: ^State) {
    sdl3.ReleaseGPUTransferBuffer(state.gpu, state.texture_buffer.transfer_buffer)
    for texture_data in state.texture_buffer.data {
        sdl3.DestroySurface(texture_data.surface)
        sdl3.ReleaseGPUTexture(state.gpu, texture_data.texture)
    }
    sdl3.ReleaseGPUSampler(state.gpu, state.texture_buffer.sampler)

    sdl3.ReleaseGPUTransferBuffer(state.gpu, state.index_buffer.transfer_buffer)
    sdl3.ReleaseGPUBuffer(state.gpu, state.index_buffer.data)

    sdl3.ReleaseGPUTransferBuffer(state.gpu, state.vertex_buffer.transfer_buffer)
    for vertex_data in state.vertex_buffer.data {
        sdl3.ReleaseGPUBuffer(state.gpu, vertex_data)
    }

    sdl3.ReleaseGPUGraphicsPipeline(state.gpu, state.pipeline)
    sdl3.DestroyGPUDevice(state.gpu)
    sdl3.DestroyWindow(state.window)
}

create_window :: proc(state: ^State, title: cstring, w, h: i32, flags: sdl3.WindowFlags) -> bool {
    state.window = sdl3.CreateWindow(title, w, h, flags)
    if state.window == nil {
        sdl3.Log("Couldn't create window: %s", sdl3.GetError())
        return false
    }

    return true
}

create_gpu :: proc(state: ^State) -> bool {
    state.gpu = sdl3.CreateGPUDevice({.MSL}, true, nil)
    if state.gpu == nil {
        sdl3.Log("Couldn't create GPU device: %s", sdl3.GetError())
        return false
    }
    if !sdl3.ClaimWindowForGPUDevice(state.gpu, state.window) {
        sdl3.Log("Couldn't claim window for GPU device: %s", sdl3.GetError())
        return false
    }
    if !sdl3.SetGPUSwapchainParameters(state.gpu, state.window, .SDR, .IMMEDIATE) {
        sdl3.Log("Couldn't disable VSYNC")
        return false
    }

    return true
}

create_pipeline :: proc(state: ^State, vertex_shader, fragment_shader: ^sdl3.GPUShader) -> bool {
    color_target_description := sdl3.GPUColorTargetDescription {
        format = sdl3.GetGPUSwapchainTextureFormat(state.gpu, state.window),
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
        pitch              = size_of(Vertex),
    }

    vertex_attributes, vertex_attributes_len := vertex_attributes()

    create_info := sdl3.GPUGraphicsPipelineCreateInfo {
        rasterizer_state = {fill_mode = .FILL, cull_mode = .NONE, front_face = .CLOCKWISE},
        target_info = {num_color_targets = 1, color_target_descriptions = &color_target_description},
        primitive_type = .TRIANGLELIST,
        vertex_shader = vertex_shader,
        fragment_shader = fragment_shader,
        vertex_input_state = {
            num_vertex_buffers = 1,
            vertex_buffer_descriptions = &vertex_buffer_description,
            num_vertex_attributes = vertex_attributes_len,
            vertex_attributes = vertex_attributes,
        },
    }

    state.pipeline = sdl3.CreateGPUGraphicsPipeline(state.gpu, create_info)
    if state.pipeline == nil {
        sdl3.Log("Couldn't create graphics pipeline: %s", sdl3.GetError())
        return false
    }

    return true
}

create_sampler :: proc(state: ^State, create_info: sdl3.GPUSamplerCreateInfo) -> bool {
    state.texture_buffer.sampler = sdl3.CreateGPUSampler(state.gpu, create_info)
    if state.texture_buffer.sampler == nil {
        sdl3.Log("Couldn't create GPU sampler: %s", sdl3.GetError())
        return false
    }

    return true
}

bind_sampler :: proc(state: ^State, render_pass: ^sdl3.GPURenderPass) {
    bindings := make([^]sdl3.GPUTextureSamplerBinding, len(state.texture_buffer.data))
    for idx in 0 ..< len(state.texture_buffer.data) {
        bindings[idx] = sdl3.GPUTextureSamplerBinding {
            texture = state.texture_buffer.data[idx].texture,
            sampler = state.texture_buffer.sampler,
        }
    }

    sdl3.BindGPUFragmentSamplers(render_pass, 0, bindings, u32(len(state.texture_buffer.data)))
}

create_texture_data_upload_buffer :: proc(state: ^State) -> bool {
    if state.texture_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.texture_buffer.transfer_buffer)
    }

    size: u32 = 0
    for len in state.texture_buffer.data_len { size += len }

    state.texture_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(state.gpu, {usage = .UPLOAD, size = size})
    if state.texture_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create texture transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

append_texture_data_buffer :: proc(
    state: ^State,
    path: cstring,
    format: sdl3.GPUTextureFormat,
    vexel_size: u32,
) -> bool {
    surface := sdl3i.Load(path)
    if surface == nil {
        sdl3.Log("Couldn't load image")
        return false
    }

    texture := sdl3.CreateGPUTexture(
        state.gpu,
        {
            type = .D2,
            format = format,
            usage = {.SAMPLER},
            width = u32(surface.w),
            height = u32(surface.h),
            layer_count_or_depth = 1,
            num_levels = 1,
        },
    )
    if texture == nil {
        sdl3.Log("Coudln't create GPU texture: %s", sdl3.GetError())
        return false
    }

    append(&state.texture_buffer.data, TextureData{surface = surface, texture = texture})
    append(&state.texture_buffer.data_len, u32(surface.w) * u32(surface.h) * vexel_size)

    return true
}

clear_texture_data_buffer :: proc(state: ^State) {
    if state.texture_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.texture_buffer.transfer_buffer)
    }

    clear(&state.texture_buffer.data)
    clear(&state.texture_buffer.data_len)
}

map_texture_data_buffer :: proc(state: ^State) -> bool {
    state.texture_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(state.gpu, state.texture_buffer.transfer_buffer, false)
    if state.texture_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the texture data buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_texture_data_buffer :: proc(state: ^State, idx: uint) {
    offset: u32 = 0
    for data_len_idx in 0 ..< idx { offset += state.texture_buffer.data_len[data_len_idx] }

    sdl3.memcpy(
        state.texture_buffer.mapped_transfer_buffer[offset:],
        state.texture_buffer.data[idx].surface.pixels,
        uint(state.texture_buffer.data_len[idx]),
    )
}

unmap_texture_data_buffer :: proc(state: ^State) {
    sdl3.UnmapGPUTransferBuffer(state.gpu, state.texture_buffer.transfer_buffer)
}

upload_texture_data_buffer :: proc(state: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    offset: u32 = 0
    for idx in 0 ..< len(state.texture_buffer.data) {
        texture_data := state.texture_buffer.data[idx]

        sdl3.UploadToGPUTexture(
            copy_pass,
            {transfer_buffer = state.texture_buffer.transfer_buffer, offset = offset},
            {texture = texture_data.texture, w = u32(texture_data.surface.w), h = u32(texture_data.surface.h), d = 1},
            false,
        )

        offset += state.texture_buffer.data_len[idx]
    }
}

create_vertex_upload_buffer :: proc(state: ^State) -> bool {
    if state.vertex_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.vertex_buffer.transfer_buffer)
    }

    size: u32 = 0
    for len in state.vertex_buffer.data_len { size += len }

    state.vertex_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(state.gpu, {usage = .UPLOAD, size = size})
    if state.vertex_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create data transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

append_vertex_buffer :: proc(state: ^State, size: u32) -> bool {
    buffer := sdl3.CreateGPUBuffer(state.gpu, {usage = {.VERTEX}, size = size})
    if buffer == nil {
        sdl3.Log("Couldn't create data buffer: %s", sdl3.GetError())
        return false
    }

    append(&state.vertex_buffer.data, buffer)
    append(&state.vertex_buffer.data_len, size)

    return true
}

clear_vertex_buffer :: proc(state: ^State) {
    if state.vertex_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.vertex_buffer.transfer_buffer)
    }

    clear(&state.vertex_buffer.data)
    clear(&state.vertex_buffer.data_len)
}

map_vertex_buffer :: proc(state: ^State) -> bool {
    state.vertex_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(state.gpu, state.vertex_buffer.transfer_buffer, false)
    if state.vertex_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the data buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_vertex_buffer :: proc(state: ^State, idx: uint, data: rawptr) {
    offset: u32 = 0
    for data_len_idx in 0 ..< idx { offset += state.vertex_buffer.data_len[data_len_idx] }

    sdl3.memcpy(state.vertex_buffer.mapped_transfer_buffer[offset:], data, uint(state.vertex_buffer.data_len[idx]))
}

unmap_vertex_buffer :: proc(state: ^State) {
    sdl3.UnmapGPUTransferBuffer(state.gpu, state.vertex_buffer.transfer_buffer)
}

upload_vertex_buffer :: proc(state: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    offset: u32 = 0
    for idx in 0 ..< len(state.vertex_buffer.data) {
        data_len := state.vertex_buffer.data_len[idx]

        sdl3.UploadToGPUBuffer(
            copy_pass,
            {transfer_buffer = state.vertex_buffer.transfer_buffer, offset = offset},
            {buffer = state.vertex_buffer.data[idx], offset = 0, size = data_len},
            false,
        )

        offset += data_len
    }
}

bind_vertex_buffer :: proc(state: ^State, render_pass: ^sdl3.GPURenderPass) {
    buffers := make([^]sdl3.GPUBufferBinding, len(state.vertex_buffer.data))

    offset: u32 = 0
    for idx in 0 ..< len(state.vertex_buffer.data) {
        buffers[idx] = sdl3.GPUBufferBinding {
            buffer = state.vertex_buffer.data[idx],
            offset = offset,
        }

        offset += state.vertex_buffer.data_len[idx]
    }

    sdl3.BindGPUVertexBuffers(render_pass, 0, buffers, 1)
}

create_index_upload_buffer :: proc(state: ^State) -> bool {
    if state.index_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.index_buffer.transfer_buffer)
    }

    state.index_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(
        state.gpu,
        {usage = .UPLOAD, size = state.index_buffer.data_len},
    )
    if state.index_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create data transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

append_index_buffer :: proc(state: ^State, size: u32) -> bool {
    buffer := sdl3.CreateGPUBuffer(state.gpu, {usage = {.INDEX}, size = size})
    if buffer == nil {
        sdl3.Log("Couldn't create data buffer: %s", sdl3.GetError())
        return false
    }

    state.index_buffer.data = buffer
    state.index_buffer.data_len = size

    return true
}

clear_index_buffer :: proc(state: ^State) {
    if state.index_buffer.transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(state.gpu, state.index_buffer.transfer_buffer)
    }
}

map_index_buffer :: proc(state: ^State) -> bool {
    state.index_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(state.gpu, state.index_buffer.transfer_buffer, false)
    if state.index_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the index buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_index_buffer :: proc(state: ^State, data: rawptr) {
    sdl3.memcpy(state.index_buffer.mapped_transfer_buffer, data, uint(state.index_buffer.data_len))
}

unmap_index_buffer :: proc(state: ^State) {
    sdl3.UnmapGPUTransferBuffer(state.gpu, state.index_buffer.transfer_buffer)
}

upload_index_buffer :: proc(state: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    sdl3.UploadToGPUBuffer(
        copy_pass,
        {transfer_buffer = state.index_buffer.transfer_buffer, offset = 0},
        {buffer = state.index_buffer.data, offset = 0, size = state.index_buffer.data_len},
        false,
    )
}

bind_index_buffer :: proc(state: ^State, render_pass: ^sdl3.GPURenderPass) {
    sdl3.BindGPUIndexBuffer(render_pass, {buffer = state.index_buffer.data}, ._16BIT)
}
