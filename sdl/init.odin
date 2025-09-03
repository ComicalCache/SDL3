package sdl

import sdl3 "vendor:sdl3"

import "../data"

@(require_results)
init :: proc(
    window: ^^sdl3.Window,
    gpu: ^^sdl3.GPUDevice,
    pipeline: ^^sdl3.GPUGraphicsPipeline,
    vertex_buffer: ^^sdl3.GPUBuffer,
    transfer_buffer: ^^sdl3.GPUTransferBuffer,
) -> sdl3.AppResult {
    assert(sdl3.SetAppMetadata("SDl3 + Metal", "1.0.0", "cc.cmath.sdl3"))

    // Initialize SDL3
    if !sdl3.Init({.VIDEO}) {
        sdl3.Log("Couldn't initialize SDL3: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create window
    window^ = sdl3.CreateWindow("SDL3 + Metal", 620, 480, {.RESIZABLE, .METAL})
    if window^ == nil {
        sdl3.Log("Couldn't create window: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create GPU device and claim window for GPU device
    gpu^ = sdl3.CreateGPUDevice({.MSL}, true, nil)
    if gpu^ == nil {
        sdl3.Log("Couldn't create GPU device: %s", sdl3.GetError())
        return .FAILURE
    }
    if !sdl3.ClaimWindowForGPUDevice(gpu^, window^) {
        sdl3.Log("Couldn't claim window for GPU device: %s", sdl3.GetError())
        return .FAILURE
    }

    // Disable VSYNC
    if !sdl3.SetGPUSwapchainParameters(gpu^, window^, .SDR, .IMMEDIATE) {
        sdl3.Log("Couldn't disable VSYNC")
        return .FAILURE
    }

    // Load vertex shader
    vertex_shader := load_shader(gpu^, "shaders/vert.metal", "vertex_main", .VERTEX, 1)
    if vertex_shader == nil {
        sdl3.Log("Couldn't to load vertex shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Load fragment shader
    fragment_shader := load_shader(gpu^, "shaders/frag.metal", "fragment_main", .FRAGMENT, 0)
    if fragment_shader == nil {
        sdl3.Log("Couldn't to load fragment shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create color target descriptions
    color_target_descriptions := make([^]sdl3.GPUColorTargetDescription, 1)
    color_target_descriptions[0] = sdl3.GPUColorTargetDescription {
        format = sdl3.GetGPUSwapchainTextureFormat(gpu^, window^),
        blend_state = {
            enable_blend = true,
            color_blend_op = .ADD,
            alpha_blend_op = .ADD,
            src_color_blendfactor = .SRC_ALPHA,
            dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
            src_alpha_blendfactor = .SRC_ALPHA,
            dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA,
        },
    }

    // Create vertex buffer descriptions
    vertex_buffer_descriptions := make([^]sdl3.GPUVertexBufferDescription, 1)
    vertex_buffer_descriptions[0] = sdl3.GPUVertexBufferDescription {
        slot               = 0,
        input_rate         = .VERTEX,
        instance_step_rate = 0,
        pitch              = size_of(data.Vertex),
    }

    // Create vertex attributes
    vertex_attributes := make([^]sdl3.GPUVertexAttribute, 2)
    vertex_attributes[0] = sdl3.GPUVertexAttribute {
        buffer_slot = 0,
        format      = .FLOAT2,
        location    = 0,
        offset      = 0,
    }
    vertex_attributes[1] = sdl3.GPUVertexAttribute {
        buffer_slot = 0,
        format      = .FLOAT4,
        location    = 1,
        offset      = size_of(f32) * 2,
    }

    // Create pipeline info
    pipeline_create_info: sdl3.GPUGraphicsPipelineCreateInfo = {
        rasterizer_state = {fill_mode = .FILL, cull_mode = .NONE, front_face = .CLOCKWISE},
        target_info = {num_color_targets = 1, color_target_descriptions = color_target_descriptions},
        primitive_type = .TRIANGLELIST,
        vertex_shader = vertex_shader,
        fragment_shader = fragment_shader,
        vertex_input_state = {
            num_vertex_buffers = 1,
            vertex_buffer_descriptions = vertex_buffer_descriptions,
            num_vertex_attributes = 2,
            vertex_attributes = vertex_attributes,
        },
    }

    // Create pipeline
    pipeline^ = sdl3.CreateGPUGraphicsPipeline(gpu^, pipeline_create_info)
    if pipeline^ == nil {
        sdl3.Log("Couldn't to create graphics pipeline: %s", sdl3.GetError())
        return .FAILURE
    }

    // Clean up shaders after they have been put in the pipeline
    sdl3.ReleaseGPUShader(gpu^, vertex_shader)
    sdl3.ReleaseGPUShader(gpu^, fragment_shader)

    // Create vertex buffer
    buffer_create_info := sdl3.GPUBufferCreateInfo {
        usage = {.VERTEX},
        size  = u32(size_of(data.Vertex) * len(data.VERTICES)),
    }
    vertex_buffer^ = sdl3.CreateGPUBuffer(gpu^, buffer_create_info)
    if vertex_buffer^ == nil {
        sdl3.Log("Couldn't to create vertex buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create transfer buffer
    transfer_buffer_create_info := sdl3.GPUTransferBufferCreateInfo {
        usage = .UPLOAD,
        size  = u32(size_of(data.Vertex) * len(data.VERTICES)),
    }
    transfer_buffer^ = sdl3.CreateGPUTransferBuffer(gpu^, transfer_buffer_create_info)
    if transfer_buffer^ == nil {
        sdl3.Log("Couldn't to create transfer buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    return .CONTINUE
}
