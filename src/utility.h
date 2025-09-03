#ifndef UTILITY_H
#define UTILITY_H

#include <SDL3/SDL.h>

SDL_GPUShader *load_shader(SDL_GPUDevice *gpu, const char *path, const char *entrypoint, SDL_GPUShaderStage stage,
                           Uint32 num_uniform_buffers);

#endif
