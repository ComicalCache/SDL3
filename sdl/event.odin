package sdl

import sdl3 "vendor:sdl3"

event :: proc(event: sdl3.Event) -> sdl3.AppResult {
    #partial switch event.type {
    case .QUIT: return .SUCCESS
    case .KEY_DOWN: #partial switch event.key.scancode {
        case .ESCAPE: fallthrough
        case .Q: return .SUCCESS
        }
    }

    return .CONTINUE
}
