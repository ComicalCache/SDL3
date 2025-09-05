package sdl

import sdl3 "vendor:sdl3"

quit :: proc(
    result: sdl3.AppResult,
    window: ^sdl3.Window,
    gpu: ^sdl3.GPUDevice,
    pipeline: ^sdl3.GPUGraphicsPipeline,
    vertex_buffer, index_buffer: ^sdl3.GPUBuffer,
    transfer_buffer: ^sdl3.GPUTransferBuffer,
) {
    if transfer_buffer != nil {
        sdl3.ReleaseGPUTransferBuffer(gpu, transfer_buffer)
    }

    if index_buffer != nil {
        sdl3.ReleaseGPUBuffer(gpu, index_buffer)
    }

    if vertex_buffer != nil {
        sdl3.ReleaseGPUBuffer(gpu, vertex_buffer)
    }

    if pipeline != nil {
        sdl3.ReleaseGPUGraphicsPipeline(gpu, pipeline)
    }

    if gpu != nil {
        sdl3.DestroyGPUDevice(gpu)
    }

    if window != nil {
        sdl3.DestroyWindow(window)
    }

    if result == .FAILURE {
        sdl3.Log("Quit app with failure")
    }
}
