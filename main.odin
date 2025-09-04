package main

import sdl3 "vendor:sdl3"

import "sdl"

NS :: 1000000000
FPS_TARGET :: 144
FRAME_TIME_NS :: (NS / FPS_TARGET)

main :: proc() {
    sdl3.SetLogPriorities(.DEBUG)

    window: ^sdl3.Window = nil
    gpu: ^sdl3.GPUDevice = nil

    pipeline: ^sdl3.GPUGraphicsPipeline = nil
    vertex_buffer: ^sdl3.GPUBuffer = nil
    transfer_buffer: ^sdl3.GPUTransferBuffer = nil

    halt: bool
    result := sdl.init(&window, &gpu, &pipeline, &vertex_buffer, &transfer_buffer)
    switch result {
    case .CONTINUE: halt = false
    case .SUCCESS: fallthrough
    case .FAILURE: halt = true
    }

    for !halt {
        frame_start := sdl3.GetPerformanceCounter()

        // Handle events
        event := sdl3.Event{}
        for sdl3.PollEvent(&event) && !halt {
            switch sdl.event(event) {
            case .CONTINUE: break
            case .SUCCESS: fallthrough
            case .FAILURE: halt = true
            }
        }

        // Check for early abort
        if result != .CONTINUE {
            break
        }

        // Business and render logic
        result = sdl.iterate(window, gpu, pipeline, transfer_buffer, vertex_buffer)
        switch result {
        case .CONTINUE: break
        case .SUCCESS: fallthrough
        case .FAILURE: halt = true
        }

        // Delay next frame if necessary to hit FPS target
        frame_time_ns := (sdl3.GetPerformanceCounter() - frame_start) * NS / sdl3.GetPerformanceFrequency()
        if frame_time_ns < FRAME_TIME_NS {
            sdl3.DelayPrecise(FRAME_TIME_NS - frame_time_ns)
        }
    }

    sdl.quit(result, window, gpu, pipeline, vertex_buffer, transfer_buffer)
}
