package data

Vertex :: struct {
    pos: [3]f32,
    col: [3]f32,
    uv:  [2]f32,
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
