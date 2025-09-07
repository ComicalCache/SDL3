package app_state

import "../data"
import "core:math/linalg"
import sdl3 "vendor:sdl3"

AppState :: struct {
    camera:          Camera,
    uniform_data:    data.UniformData,
    capture_mouse:   bool,
    mouse_movement:  [2]f32,
    key_press_state: #sparse[sdl3.Scancode]bool,
}

frame_init :: proc(as: ^AppState, delta_time: f32) {
    camera_update(as, delta_time)

    as.mouse_movement = {}
}

mvp :: proc(
    as: ^AppState,
    rotation_angle: f32,
    rotation_axis: linalg.Vector3f32,
    translation: linalg.Vector3f32,
    aspect: f32,
) -> (
    model: matrix[4, 4]f32,
    view: matrix[4, 4]f32,
    proj: matrix[4, 4]f32,
) {
    // Rotate at y axis by angle and translate it's position
    model = linalg.matrix4_translate(translation) * linalg.matrix4_rotate(rotation_angle, rotation_axis)
    // Consider y axis to be the "up" axis
    view = linalg.matrix4_look_at(as.camera.eye, as.camera.centre, linalg.Vector3f32{0, 1, 0})
    proj = linalg.matrix4_perspective(as.camera.fov, aspect, 1, 1000)

    return model, view, proj
}
