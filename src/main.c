#include <SDL3/SDL.h>
#include <SDL3/SDL_gpu.h>
#include <stdlib.h>

#include "uniform.h"
#include "utility.h"
#include "vertex.h"

#define WINDOW_WIDTH 640
#define WINDOW_HEIGHT 480

#define NS 1000000000
#define FRAMES_PER_SECOND_TARGET 144
#define FRAME_TIME_NS (NS / FRAMES_PER_SECOND_TARGET)

static SDL_Window *window = NULL;
static SDL_GPUDevice *gpu = NULL;

static SDL_GPUGraphicsPipeline *pipeline = NULL;
static SDL_GPUBuffer *vertex_buffer = NULL;
static SDL_GPUTransferBuffer *transfer_buffer = NULL;

static Uniform uniform_data = {0};

SDL_AppResult SDL_AppInit();
SDL_AppResult SDL_AppEvent(SDL_Event *event);
SDL_AppResult SDL_AppIterate();
void SDL_AppQuit(SDL_AppResult result);

int main(void) {
    bool halt;
    SDL_AppResult result = SDL_AppInit();

    switch (result) {
    case SDL_APP_CONTINUE:
        halt = false;
        break;
    case SDL_APP_SUCCESS:
    case SDL_APP_FAILURE:
        halt = true;
    }

    while (!halt) {
        Uint64 frame_start = SDL_GetPerformanceCounter();

        // Handle events
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            result = SDL_AppEvent(&event);
            switch (result) {
            case SDL_APP_CONTINUE:
                continue;
            case SDL_APP_SUCCESS:
            case SDL_APP_FAILURE:
                halt = true;
                break;
            }
        }

        // Check for early abort
        if (result != SDL_APP_CONTINUE)
            break;

        // Business logic
        result = SDL_AppIterate();
        switch (result) {
        case SDL_APP_CONTINUE:
            break;
        case SDL_APP_SUCCESS:
        case SDL_APP_FAILURE:
            halt = true;
        }

        // Delay next frame if necessary to hit frame per second target
        Uint64 frame_time_ns = (SDL_GetPerformanceCounter() - frame_start) * NS / SDL_GetPerformanceFrequency();
        if (frame_time_ns < FRAME_TIME_NS)
            SDL_DelayPrecise(FRAME_TIME_NS - frame_time_ns);
    }

    SDL_AppQuit(result);
}

SDL_AppResult SDL_AppInit() {
    SDL_SetAppMetadata("SDL3", "1.0.0", "cc.cmath.sdl3");

    // Initialize SDL3
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create window
    window = SDL_CreateWindow("SDL3 + Metal", 620, 480, SDL_WINDOW_RESIZABLE | SDL_WINDOW_METAL);
    if (!window) {
        SDL_Log("Couldn't create window: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create GPU device and claim window for GPU device
    gpu = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_MSL, true, NULL);
    if (!gpu) {
        SDL_Log("Couldn't create gpu device: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    if (!SDL_ClaimWindowForGPUDevice(gpu, window)) {
        SDL_Log("Couldn't claim window for gpu device: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Disable VSYNC
    if (!SDL_SetGPUSwapchainParameters(gpu, window, SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL_GPU_PRESENTMODE_IMMEDIATE)) {
        SDL_Log("Failed to disable VSYNC: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Load vertex shader
    SDL_GPUShader *vertex_shader = load_shader(gpu, "shaders/vert.metal", "vertex_main", SDL_GPU_SHADERSTAGE_VERTEX, 1);
    if (!vertex_shader) {
        SDL_Log("Failed to load vertex shader: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Load fragment shader
    SDL_GPUShader *fragment_shader =
        load_shader(gpu, "shaders/frag.metal", "fragment_main", SDL_GPU_SHADERSTAGE_FRAGMENT, 0);
    if (!fragment_shader) {
        SDL_Log("Failed to load fragment shader: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create pipeline info
    SDL_GPUGraphicsPipelineCreateInfo pipeline_create_info = {
        .rasterizer_state = {.fill_mode = SDL_GPU_FILLMODE_FILL,
                             .cull_mode = SDL_GPU_CULLMODE_NONE,
                             .front_face = SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE},
        .target_info =
            {
                .num_color_targets = 1,
                .color_target_descriptions =
                    (SDL_GPUColorTargetDescription[]){
                        {.format = SDL_GetGPUSwapchainTextureFormat(gpu, window),
                         .blend_state = {.enable_blend = true,
                                         .color_blend_op = SDL_GPU_BLENDOP_ADD,
                                         .alpha_blend_op = SDL_GPU_BLENDOP_ADD,
                                         .src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA,
                                         .dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                         .src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA,
                                         .dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA}}},
            },
        .primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .vertex_shader = vertex_shader,
        .fragment_shader = fragment_shader,
        .vertex_input_state = {
            .num_vertex_buffers = 1,
            .vertex_buffer_descriptions =
                (SDL_GPUVertexBufferDescription[]){{.slot = 0,
                                                    .input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX,
                                                    .instance_step_rate = 0,
                                                    .pitch = sizeof(Vertex)}},
            .num_vertex_attributes = 2,
            .vertex_attributes = (SDL_GPUVertexAttribute[]){
                {.buffer_slot = 0, .format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, .location = 0, .offset = 0},
                {.buffer_slot = 0,
                 .format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,
                 .location = 1,
                 .offset = sizeof(float) * 2}}}};

    // Create pipeline
    pipeline = SDL_CreateGPUGraphicsPipeline(gpu, &pipeline_create_info);
    if (!pipeline) {
        SDL_Log("Failed to create pipeline: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Clean up resources
    SDL_ReleaseGPUShader(gpu, vertex_shader);
    SDL_ReleaseGPUShader(gpu, fragment_shader);

    // Create vertex buffer
    SDL_GPUBufferCreateInfo buffer_create_info = {.usage = SDL_GPU_BUFFERUSAGE_VERTEX,
                                                  .size = (Uint32)(sizeof(Vertex) * num_vertices)};
    vertex_buffer = SDL_CreateGPUBuffer(gpu, &buffer_create_info);
    if (!vertex_buffer) {
        SDL_Log("Failed to create vertex buffer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Create transfer buffer
    SDL_GPUTransferBufferCreateInfo transer_buffer_create_info = {.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
                                                                  .size = (Uint32)(sizeof(Vertex) * num_vertices)};
    transfer_buffer = SDL_CreateGPUTransferBuffer(gpu, &transer_buffer_create_info);
    if (!transfer_buffer) {
        SDL_Log("Failed to create transfer buffer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(SDL_Event *event) {
    if (event->type == SDL_EVENT_QUIT)
        return SDL_APP_SUCCESS;

    if (event->type == SDL_EVENT_KEY_DOWN) {
        switch (event->key.key) {
        case SDLK_ESCAPE:
        case SDLK_Q:
            return SDL_APP_SUCCESS;
        default:
            return SDL_APP_CONTINUE;
        }
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate() {
    int width, height;
    SDL_GetWindowSize(window, &width, &height);

    // Set the angle to rotate to
    Uint64 ticks = SDL_GetTicks();
    double now = ((double)ticks / 1000.0);
    uniform_data.aspect_ration = (float)height / (float)width;
    uniform_data.x_angle = (float)now;
    uniform_data.y_angle = (float)now;
    uniform_data.z_angle = (float)now;

    // Create GPU commands
    SDL_GPUCommandBuffer *cmd_buffer = SDL_AcquireGPUCommandBuffer(gpu);
    if (!cmd_buffer) {
        SDL_Log("Failed to get GPU command buffer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Begin the copy pass
    SDL_GPUCopyPass *copy_pass = SDL_BeginGPUCopyPass(cmd_buffer);

    // Map the transfer buffer to the GPU
    Vertex *vertex_ptr = SDL_MapGPUTransferBuffer(gpu, transfer_buffer, false);
    SDL_memcpy(vertex_ptr, vertices, sizeof(Vertex) * num_vertices);
    SDL_UnmapGPUTransferBuffer(gpu, transfer_buffer);

    // Copy our vertices
    SDL_GPUTransferBufferLocation source_buffer = {.transfer_buffer = transfer_buffer, .offset = 0};
    SDL_GPUBufferRegion target_buffer = {
        .buffer = vertex_buffer, .offset = 0, .size = (Uint32)(sizeof(Vertex) * num_vertices)};
    SDL_UploadToGPUBuffer(copy_pass, &source_buffer, &target_buffer, true);

    // End copy pass
    SDL_EndGPUCopyPass(copy_pass);

    // Get swapchain texture
    SDL_GPUTexture *texture;
    if (!SDL_WaitAndAcquireGPUSwapchainTexture(cmd_buffer, window, &texture, NULL, NULL)) {
        SDL_Log("Failed to wait for and acquire GPU swapchain texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    if (!texture) {
        // Window may be minimized
        return SDL_APP_CONTINUE;
    }

    // Set clear color
    SDL_GPUColorTargetInfo color_target_info = {
        .texture = texture,
        .cycle = true,
        .clear_color = (SDL_FColor){0.11f, 0.11f, 0.11f, 1.0f},
        .load_op = SDL_GPU_LOADOP_CLEAR,
        .store_op = SDL_GPU_STOREOP_STORE,
    };

    // Begin render pass
    SDL_GPURenderPass *render_pass = SDL_BeginGPURenderPass(cmd_buffer, &color_target_info, 1, NULL);

    // Bind pipeline
    SDL_BindGPUGraphicsPipeline(render_pass, pipeline);

    // Push uniform data
    SDL_PushGPUVertexUniformData(cmd_buffer, 0, (void *)&uniform_data, sizeof(Uniform));

    // Push vertex data
    SDL_GPUBufferBinding vertex_buffer_binding = {.buffer = vertex_buffer, .offset = 0};
    SDL_BindGPUVertexBuffers(render_pass, 0, &vertex_buffer_binding, 1);

    // Draw pushed data
    SDL_DrawGPUPrimitives(render_pass, 3, 1, 0, 0);

    // End render pass
    SDL_EndGPURenderPass(render_pass);

    // Submit the command buffer
    SDL_SubmitGPUCommandBuffer(cmd_buffer);

    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(const SDL_AppResult result) {
    if (transfer_buffer)
        SDL_ReleaseGPUTransferBuffer(gpu, transfer_buffer);

    if (vertex_buffer)
        SDL_ReleaseGPUBuffer(gpu, vertex_buffer);

    if (pipeline)
        SDL_ReleaseGPUGraphicsPipeline(gpu, pipeline);

    if (gpu)
        SDL_DestroyGPUDevice(gpu);

    if (window)
        SDL_DestroyWindow(window);

    if (result == SDL_APP_FAILURE)
        SDL_Log("App quit with failure");
}
