#+feature dynamic-literals
package data

import sdl3 "vendor:sdl3"

VertexData :: struct {
    pos: [3]f32,
    col: [3]f32,
    uv:  [2]f32,
}

vertex_data_attributes :: proc() -> ([^]sdl3.GPUVertexAttribute, u32) {
    len: u32 = 3
    data := make([^]sdl3.GPUVertexAttribute, len)
    data[0] = {
        buffer_slot = 0,
        format      = .FLOAT3,
        location    = 0,
        offset      = u32(offset_of(VertexData, pos)),
    }
    data[1] = {
        buffer_slot = 0,
        format      = .FLOAT3,
        location    = 1,
        offset      = u32(offset_of(VertexData, col)),
    }
    data[2] = {
        buffer_slot = 0,
        format      = .FLOAT2,
        location    = 2,
        offset      = u32(offset_of(VertexData, uv)),
    }

    return data, len
}

VERTICES := [dynamic]VertexData {
    // Front
    VertexData{pos = {-1, -1, 1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {1, -1, 1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {-1, 1, 1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {1, 1, 1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
    // Back
    VertexData{pos = {1, -1, -1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {-1, -1, -1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {1, 1, -1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {-1, 1, -1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
    // Left
    VertexData{pos = {-1, -1, -1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {-1, -1, 1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {-1, 1, -1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {-1, 1, 1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
    // Right
    VertexData{pos = {1, -1, 1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {1, -1, -1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {1, 1, 1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {1, 1, -1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
    // Top
    VertexData{pos = {-1, 1, 1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {1, 1, 1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {-1, 1, -1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {1, 1, -1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
    // Bottom
    VertexData{pos = {1, -1, 1}, col = {1, 1, 1}, uv = {0, 1}}, // BL
    VertexData{pos = {-1, -1, 1}, col = {1, 1, 1}, uv = {1, 1}}, // BR
    VertexData{pos = {1, -1, -1}, col = {1, 1, 1}, uv = {0, 0}}, // TL
    VertexData{pos = {-1, -1, -1}, col = {1, 1, 1}, uv = {1, 0}}, // TR
}
VERTICES_BYTE_LEN :: proc() -> uint { return size_of(VertexData) * len(VERTICES) }

INDICES := [dynamic]u16 {
    0,
    2,
    1,
    2,
    3,
    1,
    4,
    6,
    5,
    6,
    7,
    5,
    8,
    10,
    9,
    10,
    11,
    9,
    12,
    14,
    13,
    14,
    15,
    13,
    16,
    18,
    17,
    18,
    19,
    17,
    20,
    22,
    21,
    22,
    23,
    21,
}
INDICES_BYTE_LEN :: proc() -> uint { return size_of(u16) * len(INDICES) }
