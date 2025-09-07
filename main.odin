package main

import "app_state"
import "sdl"
import "state"
import sdl3 "vendor:sdl3"

NS :: 1000000000
FPS_TARGET :: 144
FRAME_TIME_NS :: (NS / FPS_TARGET)

main :: proc() {
    sdl3.SetLogPriorities(.DEBUG)

    s := state.State{}
    as := app_state.AppState{}

    halt: bool
    result := sdl.init(&s, &as)
    switch result {
    case .CONTINUE: halt = false
    case .SUCCESS: fallthrough
    case .FAILURE: halt = true
    }

    for !halt {
        frame_start := sdl3.GetPerformanceCounter()

        // Handle events
        e := sdl3.Event{}
        for sdl3.PollEvent(&e) && !halt {
            switch sdl.event(e, &s, &as) {
            case .CONTINUE: break
            case .SUCCESS: fallthrough
            case .FAILURE: halt = true
            }
        }

        // Check for early abort
        if result != .CONTINUE do break

        // Business and render logic
        result = sdl.iterate(&s, &as)
        switch result {
        case .CONTINUE: break
        case .SUCCESS: fallthrough
        case .FAILURE: halt = true
        }

        // Delay next frame if necessary to hit FPS target
        frame_time_ns := (sdl3.GetPerformanceCounter() - frame_start) * NS / sdl3.GetPerformanceFrequency()
        if frame_time_ns < FRAME_TIME_NS do sdl3.DelayPrecise(FRAME_TIME_NS - frame_time_ns)
    }

    sdl.quit(result, &s)
}
