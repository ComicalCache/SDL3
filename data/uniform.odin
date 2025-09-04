package data

import "core:math/linalg"

Uniform :: struct {
    // (x rotation, y rotation, z rotation, aspect ratio)
    data: matrix[4, 4]f32,
}

mvp :: proc(angle: f32, translation, eye, centre: linalg.Vector3f32, fov, aspcet: f32) -> Uniform {
    // Rotate at y axis by angle and translate it's position
    model := linalg.matrix4_translate(translation) * linalg.matrix4_rotate(angle, linalg.Vector3f32{0, 1, 0})
    // Consider y axis to be the "up" axis
    view := linalg.matrix4_look_at(eye, centre, linalg.Vector3f32{0, 1, 0})
    proj := linalg.matrix4_perspective(fov, aspcet, 1, 1000)

    return Uniform{data = proj * view * model}
}
