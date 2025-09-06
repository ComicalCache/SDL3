package data

import sdl3 "vendor:sdl3"

Vertex :: struct {
    pos: [3]f32,
    col: [3]f32,
    uv:  [2]f32,
}

vertex_attributes :: proc() -> ([^]sdl3.GPUVertexAttribute, u32) {
    len: u32 = 3
    data := make([^]sdl3.GPUVertexAttribute, len)
    data[0] = {
        buffer_slot = 0,
        format      = .FLOAT3,
        location    = 0,
        offset      = u32(offset_of(Vertex, pos)),
    }
    data[1] = {
        buffer_slot = 0,
        format      = .FLOAT3,
        location    = 1,
        offset      = u32(offset_of(Vertex, col)),
    }
    data[2] = {
        buffer_slot = 0,
        format      = .FLOAT2,
        location    = 2,
        offset      = u32(offset_of(Vertex, uv)),
    }

    return data, len
}

VERTICES := [?]Vertex {
    Vertex{pos = {-100, -100, 0}, col = {1, 1, 1}, uv = {0, 1}},
    Vertex{pos = {100, -100, 0}, col = {1, 1, 1}, uv = {1, 1}},
    Vertex{pos = {-100, 100, 0}, col = {1, 1, 1}, uv = {0, 0}},
    Vertex{pos = {100, 100, 0}, col = {1, 1, 1}, uv = {1, 0}},
}
VERTICES_BYTE_LEN: uint = size_of(Vertex) * len(VERTICES)

INDICES := [?]u16{0, 2, 1, 2, 3, 1}
INDICES_BYTE_LEN: uint = size_of(u16) * len(INDICES)
