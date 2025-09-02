#include "utility.h"

SDL_GPUShader *load_shader(SDL_GPUDevice *gpu, const char *path, const char *entrypoint, SDL_GPUShaderStage stage) {
    size_t file_size;
    void *file = SDL_LoadFile(path, &file_size);
    if (!file) {
        return NULL;
    }

    SDL_GPUShaderCreateInfo shaderInfo = {.code = file,
                                          .code_size = file_size,
                                          .entrypoint = entrypoint,
                                          .format = SDL_GPU_SHADERFORMAT_MSL,
                                          .stage = stage,
                                          .num_samplers = 0,
                                          .num_uniform_buffers = 0,
                                          .num_storage_buffers = 0,
                                          .num_storage_textures = 0};
    SDL_GPUShader *shader = SDL_CreateGPUShader(gpu, &shaderInfo);

    SDL_free(file);

    return shader;
}
