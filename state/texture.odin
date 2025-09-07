package state

import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

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

set_depth_texture :: proc(s: ^State, w: u32, h: u32) -> bool {
    sdl3.ReleaseGPUTexture(s.gpu, s.depth_texture)

    s.depth_texture = sdl3.CreateGPUTexture(
        s.gpu,
        {
            format = .D16_UNORM,
            usage = {.DEPTH_STENCIL_TARGET},
            width = w,
            height = h,
            layer_count_or_depth = 1,
            num_levels = 1,
        },
    )
    if s.depth_texture == nil {
        sdl3.Log("Coudln't create GPU texture: %s", sdl3.GetError())
        return false
    }

    return true
}

create_texture_data_upload_buffer :: proc(s: ^State) -> bool {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.texture_buffer.transfer_buffer)

    size: u32 = 0
    for len in s.texture_buffer.data_len { size += len }

    s.texture_buffer.transfer_buffer = sdl3.CreateGPUTransferBuffer(s.gpu, {usage = .UPLOAD, size = size})
    if s.texture_buffer.transfer_buffer == nil {
        sdl3.Log("Couldn't create texture transfer buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

append_texture_data_buffer :: proc(s: ^State, path: cstring, format: sdl3.GPUTextureFormat, vexel_size: u32) -> bool {
    surface := sdl3i.Load(path)
    if surface == nil {
        sdl3.Log("Couldn't load image")
        return false
    }

    texture := sdl3.CreateGPUTexture(
        s.gpu,
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

    append(&s.texture_buffer.data, TextureData{surface = surface, texture = texture})
    append(&s.texture_buffer.data_len, u32(surface.w) * u32(surface.h) * vexel_size)

    return true
}

clear_texture_data_buffer :: proc(s: ^State) {
    sdl3.ReleaseGPUTransferBuffer(s.gpu, s.texture_buffer.transfer_buffer)

    for buffer in s.texture_buffer.data {
        sdl3.DestroySurface(buffer.surface)
        sdl3.ReleaseGPUTexture(s.gpu, buffer.texture)
    }
    clear(&s.texture_buffer.data)

    clear(&s.texture_buffer.data_len)
}

map_texture_data_buffer :: proc(s: ^State) -> bool {
    s.texture_buffer.mapped_transfer_buffer =
    transmute([^]byte)sdl3.MapGPUTransferBuffer(s.gpu, s.texture_buffer.transfer_buffer, false)
    if s.texture_buffer.mapped_transfer_buffer == nil {
        sdl3.Log("Couldn't map the texture data buffer: %s", sdl3.GetError())
        return false
    }

    return true
}

copy_to_texture_data_buffer :: proc(s: ^State, idx: uint) {
    offset: u32 = 0
    for data_len_idx in 0 ..< idx { offset += s.texture_buffer.data_len[data_len_idx] }

    sdl3.memcpy(
        s.texture_buffer.mapped_transfer_buffer[offset:],
        s.texture_buffer.data[idx].surface.pixels,
        uint(s.texture_buffer.data_len[idx]),
    )
}

unmap_texture_data_buffer :: proc(s: ^State) {
    sdl3.UnmapGPUTransferBuffer(s.gpu, s.texture_buffer.transfer_buffer)
}

upload_texture_data_buffer :: proc(s: ^State, copy_pass: ^sdl3.GPUCopyPass) {
    offset: u32 = 0
    for idx in 0 ..< len(s.texture_buffer.data) {
        texture_data := s.texture_buffer.data[idx]

        sdl3.UploadToGPUTexture(
            copy_pass,
            {transfer_buffer = s.texture_buffer.transfer_buffer, offset = offset},
            {texture = texture_data.texture, w = u32(texture_data.surface.w), h = u32(texture_data.surface.h), d = 1},
            false,
        )

        offset += s.texture_buffer.data_len[idx]
    }
}
