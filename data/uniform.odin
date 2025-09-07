package data

import "core:math/linalg"

UniformData :: struct {
    // (x rotation, y rotation, z rotation, aspect ratio)
    mvp: matrix[4, 4]f32,
}
