package app_state

import "core:math"
import "core:math/linalg"

@(private)
MOUSE_SENSITIVITY :: .3
@(private)
MOVEMENT_SPEED :: 1

Camera :: struct {
    fov:    f32,
    yaw:    f32,
    pitch:  f32,
    eye:    linalg.Vector3f32,
    centre: linalg.Vector3f32,
}

@(private)
camera_update :: proc(as: ^AppState, delta_time: f32) {
    move_inputs := linalg.Vector2f32{}
    if as.key_press_state[.W] do move_inputs.y += 1
    if as.key_press_state[.S] do move_inputs.y -= 1
    if as.key_press_state[.D] do move_inputs.x += 1
    if as.key_press_state[.A] do move_inputs.x -= 1

    look_inputs := as.mouse_movement * MOUSE_SENSITIVITY

    as.camera.yaw = math.wrap(as.camera.yaw - look_inputs.x, 360)
    as.camera.pitch = math.clamp(as.camera.pitch - look_inputs.y, -89.5, 89.5)

    look := linalg.matrix3_from_yaw_pitch_roll(linalg.to_radians(as.camera.yaw), linalg.to_radians(as.camera.pitch), 0)
    forward := look * linalg.Vector3f32{0, 0, -1}
    sideways := look * linalg.Vector3f32{1, 0, 0}

    movement := forward * move_inputs.y + sideways * move_inputs.x
    if as.key_press_state[.SPACE] do movement.y += 1
    if as.key_press_state[.LCTRL] do movement.y -= 1

    sprinting: f32 = as.key_press_state[.LSHIFT] ? 2 : 1
    motion := linalg.normalize0(movement) * MOVEMENT_SPEED * sprinting * delta_time
    as.camera.eye += motion
    as.camera.centre = as.camera.eye + forward
}
