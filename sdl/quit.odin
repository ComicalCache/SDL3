package sdl

import "../data"
import sdl3 "vendor:sdl3"

quit :: proc(result: sdl3.AppResult, state: ^data.State) {
    data.clean_up(state)

    if result == .FAILURE {
        sdl3.Log("Quit app with failure")
    }
}
