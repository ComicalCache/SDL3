#define SDL_MAIN_USE_CALLBACKS 1
#include <stdlib.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_image/SDL_image.h>

#include "app_state.h"

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_AudioStream *audio = NULL;

Uint8 *sound_buffer;
Uint32 sound_len;

SDL_Texture *texture = NULL;

SDL_AppResult SDL_AppInit(void **appstate, const int argc, char *argv[]) {
    AppState **state = (AppState **) appstate;
    *state = (AppState *) malloc(sizeof(AppState));

    SDL_SetAppMetadata("SDL3 Test", "1.0.0", "cc.cmath.sdl3_test");

    for (int i = 1; i < argc; i += 1) {
        SDL_Log("Received command line argument: '%s'", argv[i]);
    }

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    const int width = 641;
    const int height = 487;

    if (!SDL_CreateWindowAndRenderer("SDL3 Test", width, height, 0, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_SetWindowResizable(window, true)) {
        SDL_Log("Couldn't set the window to resizable: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_AudioSpec audio_spec;
    if (!SDL_LoadWAV("/Users/user/Downloads/effect.wav", &audio_spec, &sound_buffer, &sound_len)) {
        SDL_Log("Couldn't load WAV: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    audio = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, NULL, NULL);
    if (!audio) {
        SDL_Log("Couldn't open audio device: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_Surface *surface = IMG_Load("/Users/user/Downloads/dvd.png");
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

    init_app_state(*state, height, width, texture->w, texture->h);

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
            case SDLK_Q: return SDL_APP_SUCCESS;
            default: return SDL_APP_CONTINUE;
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

    if (SDL_GetTicks() % 25 != 0) {
        SDL_Delay(25 - SDL_GetTicks() % 25);
    }

    // Update state
    tick(state);

    // Play sound
    if (state->hit_wall) {
        SDL_ClearAudioStream(audio);
        SDL_PutAudioStreamData(audio, sound_buffer, (int) sound_len);
    }

    // DVD logo
    const SDL_FRect rect = {
        .h = (float) state->rect.h, .w = (float) state->rect.w, .x = (float) state->rect.x, .y = (float) state->rect.y
    };
    SDL_RenderTexture(renderer, texture, NULL, &rect);

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
        case SDL_APP_SUCCESS:
            SDL_Log("App quit with success");
            break;
        case SDL_APP_FAILURE:
            SDL_Log("App quit with failure");
            break;
        default:
            SDL_Log("App quit");
            break;
    }
}
