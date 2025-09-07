package sdl

import "../data"
import "../state"
import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

init :: proc(s: ^state.State) -> sdl3.AppResult {
    if !sdl3.SetAppMetadata("SDl3 + Metal", "1.0.0", "cc.cmath.sdl3") {
        sdl3.Log("Couldn't set app metadata: %s", sdl3.GetError())
        return .FAILURE
    }

    // Initialize SDL3
    if !sdl3.Init({.VIDEO}) {
        sdl3.Log("Couldn't initialize SDL3: %s", sdl3.GetError())
        return .FAILURE
    }

    if !state.create_window(s, "SDL3 + Metal", 620, 480, {.RESIZABLE, .METAL}) { return .FAILURE }
    if !state.create_gpu(s) { return .FAILURE }

    // Load vertex shader
    vertex_shader := load_shader(s.gpu, "shaders/vert.metal", "vertex_main", .VERTEX, 1, 0)
    if vertex_shader == nil {
        sdl3.Log("Couldn't load vertex shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Load fragment shader
    fragment_shader := load_shader(s.gpu, "shaders/frag.metal", "fragment_main", .FRAGMENT, 0, 1)
    if fragment_shader == nil {
        sdl3.Log("Couldn't load fragment shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create pipeline
    if !state.create_pipeline(s, vertex_shader, fragment_shader) { return .FAILURE }

    // Clean up shaders after they have been put in the pipeline
    sdl3.ReleaseGPUShader(s.gpu, vertex_shader)
    sdl3.ReleaseGPUShader(s.gpu, fragment_shader)

    // Create sampler
    if !state.create_sampler(s, {min_filter = .LINEAR, mag_filter = .LINEAR, mipmap_mode = .LINEAR}) {
        return .FAILURE
    }

    // Load texture
    if !state.append_texture_data_buffer(s, "media/jumbo_schreiner.png", .R8G8B8A8_UNORM, 4) { return .FAILURE }

    // Create vertex and index buffer
    if !state.append_vertex_buffer(s, u32(data.VERTICES_BYTE_LEN())) { return .FAILURE }
    if !state.set_index_buffer(s, u32(data.INDICES_BYTE_LEN())) { return .FAILURE }

    // Create transfer buffers
    if !state.create_vertex_upload_buffer(s) { return .FAILURE }
    if !state.create_index_upload_buffer(s) { return .FAILURE }
    if !state.create_texture_data_upload_buffer(s) { return .FAILURE }

    return .CONTINUE
}
