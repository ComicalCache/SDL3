package sdl

import "../app_state"
import "../state"
import sdl3 "vendor:sdl3"

event :: proc(event: sdl3.Event, s: ^state.State, as: ^app_state.AppState) -> sdl3.AppResult {
    #partial switch event.type {
    case .QUIT: return .SUCCESS
    case .KEY_DOWN:
        #partial switch event.key.scancode {
        case .ESCAPE: if as.capture_mouse {
                as.capture_mouse = false
                if !state.set_window_relative_mouse(s, false) do return .FAILURE
            }
        case .Q: return .SUCCESS
        }

        as.key_press_state[event.key.scancode] = true
    case .KEY_UP: as.key_press_state[event.key.scancode] = false
    case .MOUSE_BUTTON_DOWN: if event.button.button == 1 && !as.capture_mouse {
            as.capture_mouse = true
            if !state.set_window_relative_mouse(s, true) do return .FAILURE
        }
    case .MOUSE_MOTION: if as.capture_mouse do as.mouse_movement += {event.motion.xrel, event.motion.yrel}
    }

    return .CONTINUE
}
