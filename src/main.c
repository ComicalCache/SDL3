#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_image/SDL_image.h>
#include <stdlib.h>

#include "app_state.h"

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_AudioStream *audio = NULL;

static Uint8 *sound_buffer = NULL;
static Uint32 sound_len;

static SDL_Texture *texture = NULL;

SDL_AppResult SDL_AppInit(void **appstate, int /* argc */, char * /* argv */[]) {
    AppState **state = (AppState **)appstate;
    *state = (AppState *)malloc(sizeof(AppState));

    SDL_SetAppMetadata("Vine Boom Sound Effect Machine", "1.0.0", "cc.cmath.vine_boom");

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    const int width = 641;
    const int height = 487;

    if (!SDL_CreateWindowAndRenderer("Vine Boom Sound Effect Machine", width, height, 0, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_SetWindowResizable(window, true)) {
        SDL_Log("Couldn't set the window to resizable: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_SetRenderVSync(renderer, 1)) {
        SDL_Log("Couldn't set the renderer to VSYNC: %s", SDL_GetError());
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

    SDL_Surface *surface = IMG_Load("media/dvd.png");
    if (!surface) {
        SDL_Log("Couldn't load png: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_Surface *old_surface = surface;
    surface = SDL_ScaleSurface(surface, surface->w / 3, surface->h / 3, SDL_SCALEMODE_LINEAR);
    if (!surface) {
        SDL_Log("Couldn't scale surface: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_DestroySurface(old_surface);
    texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        SDL_Log("Couldn't create texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_DestroySurface(surface);

    init_app_state(*state, height, width, (float)texture->w, (float)texture->h, SDL_GetPerformanceCounter(),
                   SDL_GetPerformanceFrequency());

    SDL_ResumeAudioStreamDevice(audio);

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    AppState *state = appstate;
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }

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
        state->dims.x = event->window.data1;
        state->dims.y = event->window.data2;

        return SDL_APP_CONTINUE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    AppState *state = appstate;

    // Background
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);

    // Calculate frame delta
    const Uint64 counter = SDL_GetPerformanceCounter();
    float delta = (float)(counter - state->prev_counter) / (float)state->frequency;
    state->prev_counter = counter;

    // Update state
    tick(state, delta);

    // Play sound
    if (state->hit_wall) {
        SDL_ClearAudioStream(audio);
        SDL_PutAudioStreamData(audio, sound_buffer, (int)sound_len);
    }

    // DVD logo
    SDL_RenderTexture(renderer, texture, NULL, &state->rect);

    // Render all
    SDL_RenderPresent(renderer);

    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, const SDL_AppResult result) {
    AppState *state = appstate;

    if (texture) {
        SDL_DestroyTexture(texture);
    }

    if (audio) {
        SDL_DestroyAudioStream(audio);
    }

    if (sound_buffer) {
        SDL_free(sound_buffer);
    }

    if (state) {
        free(state);
    }

    switch (result) {
    case SDL_APP_FAILURE:
        SDL_Log("App quit with failure");
        break;
    case SDL_APP_CONTINUE:
    case SDL_APP_SUCCESS:
        break;
    }
}
