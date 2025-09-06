package sdl

import "../data"
import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

init :: proc(state: ^data.State) -> sdl3.AppResult {
    if !sdl3.SetAppMetadata("SDl3 + Metal", "1.0.0", "cc.cmath.sdl3") {
        sdl3.Log("Couldn't set app metadata: %s", sdl3.GetError())
        return .FAILURE
    }

    // Initialize SDL3
    if !sdl3.Init({.VIDEO}) {
        sdl3.Log("Couldn't initialize SDL3: %s", sdl3.GetError())
        return .FAILURE
    }

    if !data.create_window(state, "SDL3 + Metal", 620, 480, {.RESIZABLE, .METAL}) { return .FAILURE }
    if !data.create_gpu(state) { return .FAILURE }

    // Load vertex shader
    vertex_shader := load_shader(state.gpu, "shaders/vert.metal", "vertex_main", .VERTEX, 1, 0)
    if vertex_shader == nil {
        sdl3.Log("Couldn't load vertex shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Load fragment shader
    fragment_shader := load_shader(state.gpu, "shaders/frag.metal", "fragment_main", .FRAGMENT, 0, 1)
    if fragment_shader == nil {
        sdl3.Log("Couldn't load fragment shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create pipeline
    if !data.create_pipeline(state, vertex_shader, fragment_shader) { return .FAILURE }

    // Clean up shaders after they have been put in the pipeline
    sdl3.ReleaseGPUShader(state.gpu, vertex_shader)
    sdl3.ReleaseGPUShader(state.gpu, fragment_shader)

    // Create sampler
    if !data.create_sampler(state, {min_filter = .LINEAR, mag_filter = .LINEAR, mipmap_mode = .LINEAR}) {
        return .FAILURE
    }

    // Load texture
    if !data.append_texture_data_buffer(state, "media/jumbo_schreiner.png", .R8G8B8A8_UNORM, 4) { return .FAILURE }

    // Create vertex and index buffer
    if !data.append_vertex_buffer(state, u32(data.VERTICES_BYTE_LEN)) { return .FAILURE }
    if !data.append_index_buffer(state, u32(data.INDICES_BYTE_LEN)) { return .FAILURE }

    // Create transfer buffers
    if !data.create_vertex_upload_buffer(state) { return .FAILURE }
    if !data.create_index_upload_buffer(state) { return .FAILURE }
    if !data.create_texture_data_upload_buffer(state) { return .FAILURE }

    return .CONTINUE
}
