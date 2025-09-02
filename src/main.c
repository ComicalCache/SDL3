#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>
#include <stdlib.h>

#include "state.h"

#define WINDOW_WIDTH 640
#define WINDOW_HEIGHT 480

#define NS 1000000000
#define FRAMES_PER_SECOND_TARGET 144
#define FRAME_TIME_NS (NS / FRAMES_PER_SECOND_TARGET)

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_AudioStream *audio = NULL;

static Uint8 *sound_buffer = NULL;
static Uint32 sound_len = 0;

static SDL_Texture *texture = NULL;

static State state = (State){0};

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
            SDL_DelayPrecise((Uint32)(FRAME_TIME_NS - frame_time_ns));
    }

    SDL_AppQuit(result);
}

SDL_AppResult SDL_AppInit() {
    state = (State){0};

    SDL_SetAppMetadata("SDL3", "1.0.0", "cc.cmath.sdl3");

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer("SDL3", WINDOW_WIDTH, WINDOW_HEIGHT, 0, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_SetWindowResizable(window, true)) {
        SDL_Log("Couldn't set the window to resizable: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_AudioSpec audio_spec;
    if (!SDL_LoadWAV("media/effect.wav", &audio_spec, &sound_buffer, &sound_len)) {
        SDL_Log("Couldn't load WAV: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    audio = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, NULL, NULL);
    if (!audio) {
        SDL_Log("Couldn't open audio device: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_ResumeAudioStreamDevice(audio);

    texture = IMG_LoadTexture(renderer, "media/dvd.svg");
    if (!texture) {
        SDL_Log("Couldn't create texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    AS_init(&state, (Vec2d){.x = WINDOW_WIDTH, .y = WINDOW_HEIGHT}, (Vec2d){.x = 75, .y = 45},
            SDL_GetPerformanceCounter());

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

    if (event->type == SDL_EVENT_WINDOW_RESIZED) {
        state.dims.x = event->window.data1;
        state.dims.y = event->window.data2;

        return SDL_APP_CONTINUE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate() {
    // Background
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);

    // Calculate frame delta
    const Uint64 counter = SDL_GetPerformanceCounter();
    const Uint64 freq = SDL_GetPerformanceFrequency();
    float delta = (float)(counter - state.prev_counter) / (float)freq;
    state.prev_counter = counter;

    // Update state
    AS_tick(&state, delta);

    // DVD logo
    const Uint64 ticks = SDL_GetTicks();
    const double now = (double)ticks / 1000.0;
    const float red = (float)(0.5 + 0.5 * SDL_sin(now));
    const float green = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
    const float blue = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));
    SDL_SetTextureColorModFloat(texture, red, green, blue);
    SDL_RenderTexture(renderer, texture, NULL, &state.rect);

    // FPS count
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    SDL_RenderDebugTextFormat(renderer, 0.f, 0.f, "FPS: %d", (int)(1. / (double)delta));

    // Play sound
    if (state.hit_wall) {
        SDL_ClearAudioStream(audio);
        SDL_PutAudioStreamData(audio, sound_buffer, (int)sound_len);
    }

    // Render all
    SDL_RenderPresent(renderer);

    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(const SDL_AppResult result) {
    if (texture)
        SDL_DestroyTexture(texture);

    if (audio)
        SDL_DestroyAudioStream(audio);

    if (sound_buffer)
        SDL_free(sound_buffer);

    if (renderer)
        SDL_DestroyRenderer(renderer);

    if (window)
        SDL_DestroyWindow(window);

    if (result == SDL_APP_FAILURE)
        SDL_Log("App quit with failure");
}
