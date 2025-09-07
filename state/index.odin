package state

import sdl3 "vendor:sdl3"

IndexDataBuffer :: struct {
    transfer_buffer:        ^sdl3.GPUTransferBuffer,
    mapped_transfer_buffer: [^]byte,
    data:                   ^sdl3.GPUBuffer,
    data_len:               u32,
}

create_index_upload_buffer :: proc(s: ^State) -> bool {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.index_buffer.transfer_buffer)

    size := s.index_buffer.data_len
    s.index_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(s.gpu, {usage = .UPLOAD, size = size})
    if s.index_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create index transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

set_index_buffer :: proc(s: ^State, size: u32) -> bool {
    sdl3.ReleaseGPUBuffer(s.gpu, s.index_buffer.data)

    buffer := sdl3.CreateGPUBuffer(s.gpu, {usage = {.INDEX}, size = size})
    if buffer == nil {
        sdl3.Log("Couldn't create index buffer: %s", sdl3.GetError())
        return false
    }

    s.index_buffer.data = buffer
    s.index_buffer.data_len = size

    return true
}

clear_index_buffer :: proc(s: ^State) {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.index_buffer.transfer_buffer)
    sdl3.ReleaseGPUBuffer(s.gpu, s.index_buffer.data)
    s.index_buffer.data_len = 0
}

map_index_buffer :: proc(s: ^State) -> bool {
    s.index_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(s.gpu, s.index_buffer.transfer_buffer, false)
    if s.index_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the index buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_index_buffer :: proc(s: ^State, data: rawptr) {
    sdl3.memcpy(s.index_buffer.mapped_transfer_buffer, data, uint(s.index_buffer.data_len))
}

unmap_index_buffer :: proc(s: ^State) {
    sdl3.UnmapGPUTransferBuffer(s.gpu, s.index_buffer.transfer_buffer)
}

upload_index_buffer :: proc(s: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    sdl3.UploadToGPUBuffer(
        copy_pass,
        {transfer_buffer = s.index_buffer.transfer_buffer, offset = 0},
        {buffer = s.index_buffer.data, offset = 0, size = s.index_buffer.data_len},
        false,
    )
}

bind_index_buffer :: proc(s: ^State, render_pass: ^sdl3.GPURenderPass) {
    sdl3.BindGPUIndexBuffer(render_pass, {buffer = s.index_buffer.data}, ._16BIT)
}
