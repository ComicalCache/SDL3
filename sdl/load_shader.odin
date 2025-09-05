package sdl

import sdl3 "vendor:sdl3"

@(require_results)
load_shader :: proc(
    gpu: ^sdl3.GPUDevice,
    path, entry_point: cstring,
    stage: sdl3.GPUShaderStage,
    num_uniform_buffers: u32,
) -> ^sdl3.GPUShader {
    code_len: uint = 0
    code := transmute([^]byte)sdl3.LoadFile(path, &code_len)
    if code == nil {
        return nil
    }

    shader_info := sdl3.GPUShaderCreateInfo {
        code                 = code,
        code_size            = code_len,
        entrypoint           = entry_point,
        format               = {.MSL},
        stage                = stage,
        num_samplers         = 0,
        num_uniform_buffers  = num_uniform_buffers,
        num_storage_buffers  = 0,
        num_storage_textures = 0,
    }

    shader := sdl3.CreateGPUShader(gpu, shader_info)

    sdl3.free(code)

    return shader
}
