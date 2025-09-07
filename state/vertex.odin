package state

import sdl3 "vendor:sdl3"

VertexBuffer :: struct {
    transfer_buffer:        ^sdl3.GPUTransferBuffer,
    mapped_transfer_buffer: [^]byte,
    data:                   [dynamic]^sdl3.GPUBuffer,
    data_len:               [dynamic]u32,
}

create_vertex_upload_buffer :: proc(s: ^State) -> bool {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.vertex_buffer.transfer_buffer)

    size: u32 = 0
    for len in s.vertex_buffer.data_len { size += len }

    s.vertex_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(s.gpu, {usage = .UPLOAD, size = size})
    if s.vertex_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create vertex transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

append_vertex_buffer :: proc(s: ^State, size: u32) -> bool {
    buffer := sdl3.CreateGPUBuffer(s.gpu, {usage = {.VERTEX}, size = size})
    if buffer == nil {
        sdl3.Log("Couldn't create vertex buffer: %s", sdl3.GetError())
        return false
    }

    append(&s.vertex_buffer.data, buffer)
    append(&s.vertex_buffer.data_len, size)

    return true
}

clear_vertex_buffer :: proc(s: ^State) {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.vertex_buffer.transfer_buffer)

    for buffer in s.vertex_buffer.data { sdl3.ReleaseGPUBuffer(s.gpu, buffer) }
    clear(&s.vertex_buffer.data)

    clear(&s.vertex_buffer.data_len)
}

map_vertex_buffer :: proc(s: ^State) -> bool {
    s.vertex_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(s.gpu, s.vertex_buffer.transfer_buffer, false)
    if s.vertex_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the vertex buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_vertex_buffer :: proc(s: ^State, idx: uint, data: rawptr) {
    offset: u32 = 0
    for data_len_idx in 0 ..< idx { offset += s.vertex_buffer.data_len[data_len_idx] }

    sdl3.memcpy(s.vertex_buffer.mapped_transfer_buffer[offset:], data, uint(s.vertex_buffer.data_len[idx]))
}

unmap_vertex_buffer :: proc(s: ^State) {
    sdl3.UnmapGPUTransferBuffer(s.gpu, s.vertex_buffer.transfer_buffer)
}

upload_vertex_buffer :: proc(s: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    offset: u32 = 0
    for idx in 0 ..< len(s.vertex_buffer.data) {
        data_len := s.vertex_buffer.data_len[idx]

        sdl3.UploadToGPUBuffer(
            copy_pass,
            {transfer_buffer = s.vertex_buffer.transfer_buffer, offset = offset},
            {buffer = s.vertex_buffer.data[idx], offset = 0, size = data_len},
            false,
        )

        offset += data_len
    }
}

bind_vertex_buffer :: proc(s: ^State, render_pass: ^sdl3.GPURenderPass) {
    bindings := make([^]sdl3.GPUBufferBinding, len(s.vertex_buffer.data))

    offset: u32 = 0
    for idx in 0 ..< len(s.vertex_buffer.data) {
        bindings[idx] = sdl3.GPUBufferBinding {
            buffer = s.vertex_buffer.data[idx],
            offset = offset,
        }

        offset += s.vertex_buffer.data_len[idx]
    }

    sdl3.BindGPUVertexBuffers(render_pass, 0, bindings, u32(len(s.vertex_buffer.data)))
}
