package sdl

import "../state"
import sdl3 "vendor:sdl3"

quit :: proc(result: sdl3.AppResult, s: ^state.State) {
    state.free_state(s)

    if result == .FAILURE {
        sdl3.Log("Quit app with failure")
    }
}
