package data

// Triangle side length
@(private)
l :: 30

// sqrt(3) / 2
@(private)
lambda :: 0.8660254

Vertex :: struct {
    pos: [3]f32,
    col: [3]f32,
}

VERTICES: [3]Vertex = {
    Vertex{pos = {0, 2 * lambda * l / 3, 0}, col = {1, 0, 0}},
    Vertex{pos = {l / 2, -lambda * l / 3, 0}, col = {0, 1, 0}},
    Vertex{pos = {-l / 2, -lambda * l / 3, 0}, col = {0, 0, 1}},
}
