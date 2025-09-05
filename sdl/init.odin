package sdl

import sdl3 "vendor:sdl3"
import sdl3i "vendor:sdl3/image"

import "../data"

@(require_results)
init :: proc(
    window: ^^sdl3.Window,
    gpu: ^^sdl3.GPUDevice,
    pipeline: ^^sdl3.GPUGraphicsPipeline,
    vertex_buffer, index_buffer: ^^sdl3.GPUBuffer,
    transfer_buffer: ^^sdl3.GPUTransferBuffer,
    image: ^^sdl3.Surface,
    texture: ^^sdl3.GPUTexture,
    sampler: ^^sdl3.GPUSampler,
    texture_transfer_buffer: ^^sdl3.GPUTransferBuffer,
) -> sdl3.AppResult {
    if !sdl3.SetAppMetadata("SDl3 + Metal", "1.0.0", "cc.cmath.sdl3") {
        sdl3.Log("Couldn't set app metadata: %s", sdl3.GetError())
        return .FAILURE
    }

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
    vertex_shader := load_shader(gpu^, "shaders/vert.metal", "vertex_main", .VERTEX, 1, 0)
    if vertex_shader == nil {
        sdl3.Log("Couldn't load vertex shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Load fragment shader
    fragment_shader := load_shader(gpu^, "shaders/frag.metal", "fragment_main", .FRAGMENT, 0, 1)
    if fragment_shader == nil {
        sdl3.Log("Couldn't load fragment shader: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create color target descriptions
    color_target_description := sdl3.GPUColorTargetDescription {
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
    vertex_buffer_description := sdl3.GPUVertexBufferDescription {
        slot               = 0,
        input_rate         = .VERTEX,
        instance_step_rate = 0,
        pitch              = size_of(data.Vertex),
    }

    // Create vertex attributes
    vertex_attributes := []sdl3.GPUVertexAttribute {
        {buffer_slot = 0, format = .FLOAT3, location = 0, offset = u32(offset_of(data.Vertex, pos))},
        {buffer_slot = 0, format = .FLOAT3, location = 1, offset = u32(offset_of(data.Vertex, col))},
        {buffer_slot = 0, format = .FLOAT2, location = 2, offset = u32(offset_of(data.Vertex, uv))},
    }

    // Create pipeline info
    pipeline_create_info: sdl3.GPUGraphicsPipelineCreateInfo = {
        rasterizer_state = {fill_mode = .FILL, cull_mode = .NONE, front_face = .CLOCKWISE},
        target_info = {num_color_targets = 1, color_target_descriptions = &color_target_description},
        primitive_type = .TRIANGLELIST,
        vertex_shader = vertex_shader,
        fragment_shader = fragment_shader,
        vertex_input_state = {
            num_vertex_buffers = 1,
            vertex_buffer_descriptions = &vertex_buffer_description,
            num_vertex_attributes = u32(len(vertex_attributes)),
            vertex_attributes = raw_data(vertex_attributes),
        },
    }

    // Create pipeline
    pipeline^ = sdl3.CreateGPUGraphicsPipeline(gpu^, pipeline_create_info)
    if pipeline^ == nil {
        sdl3.Log("Couldn't create graphics pipeline: %s", sdl3.GetError())
        return .FAILURE
    }

    // Clean up shaders after they have been put in the pipeline
    sdl3.ReleaseGPUShader(gpu^, vertex_shader)
    sdl3.ReleaseGPUShader(gpu^, fragment_shader)

    // Load image
    image^ = sdl3i.Load("media/jumbo_schreiner.png")
    if image^ == nil {
        sdl3.Log("Couldn't load image")
        return .FAILURE
    }
    texture^ = sdl3.CreateGPUTexture(
        gpu^,
        {
            type = .D2,
            format = .R8G8B8A8_UNORM,
            usage = {.SAMPLER},
            width = u32(image^.w),
            height = u32(image^.h),
            layer_count_or_depth = 1,
            num_levels = 1,
        },
    )
    if texture^ == nil {
        sdl3.Log("Coudln't create GPU texture: %s", sdl3.GetError())
        return .FAILURE
    }

    sampler^ = sdl3.CreateGPUSampler(gpu^, {min_filter = .LINEAR, mag_filter = .LINEAR, mipmap_mode = .LINEAR})
    if sampler^ == nil {
        sdl3.Log("Couldn't create GPU sampler: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create vertex buffer
    vertex_buffer^ = sdl3.CreateGPUBuffer(gpu^, {usage = {.VERTEX}, size = u32(data.VERTICES_BYTE_LEN)})
    if vertex_buffer^ == nil {
        sdl3.Log("Couldn't create vertex buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create index buffer
    index_buffer^ = sdl3.CreateGPUBuffer(gpu^, {usage = {.INDEX}, size = u32(data.INDICES_BYTE_LEN)})
    if index_buffer^ == nil {
        sdl3.Log("Couldn't create index buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create transfer buffer
    transfer_buffer^ = sdl3.CreateGPUTransferBuffer(
        gpu^,
        {usage = .UPLOAD, size = u32(data.VERTICES_BYTE_LEN + data.INDICES_BYTE_LEN)},
    )
    if transfer_buffer^ == nil {
        sdl3.Log("Couldn't create transfer buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    // Create texture transfer buffer
    texture_transfer_buffer^ = sdl3.CreateGPUTransferBuffer(
        gpu^,
        {usage = .UPLOAD, size = u32(image^.w * image^.h * 4)},
    )
    if texture_transfer_buffer^ == nil {
        sdl3.Log("Couldn't create texture transfer buffer: %s", sdl3.GetError())
        return .FAILURE
    }

    return .CONTINUE
}
