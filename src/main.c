#define SDL_MAIN_USE_CALLBACKS 1
#include <stdlib.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "app_state.h"

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_AudioStream *audio = NULL;

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

    const int width = 640;
    const int height = 480;

    if (!SDL_CreateWindowAndRenderer("SDL3 Test", width, height, 0, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    (*state)->hit_wall = false;
    (*state)->h = height;
    (*state)->w = width;
    (*state)->momentum.x = 2;
    (*state)->momentum.y = 2;
    (*state)->rect.h = 26.f;
    (*state)->rect.w = 26.f;
    (*state)->rect.x = (float) width / 2.f + 13.f;
    (*state)->rect.y = (float) height / 2.f + 13.f;

    if (!SDL_SetWindowResizable(window, true)) {
        SDL_Log("Couldn't set the window to resizable: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    SDL_AudioSpec audio_spec;
    if (!SDL_LoadWAV("/Users/user/Downloads/effect.wav", &audio_spec, &(*state)->sound_buffer, &(*state)->sound_len)) {
        SDL_Log("Couldn't load WAV: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    audio = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, NULL, NULL);
    if (!audio) {
        SDL_Log("Couldn't open audio device: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

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
        state->w = event->window.data1;
        state->h = event->window.data2;

        return SDL_APP_CONTINUE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    AppState *state = appstate;

    // Background
    /*
    const double now = (double) SDL_GetTicks() / 1000.0;
    const float red = (float) (0.5 + 0.5 * SDL_sin(now));
    const float green = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
    const float blue = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));
    SDL_SetRenderDrawColorFloat(renderer, red, green, blue, SDL_ALPHA_OPAQUE_FLOAT);
    */
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
    SDL_RenderClear(renderer);

    // Update state
    if (SDL_GetTicks() % 25 == 0) {
        tick(state);

        // Play sound
        if (state->hit_wall) {
            SDL_ClearAudioStream(audio);
            SDL_PutAudioStreamData(audio, state->sound_buffer, (int) state->sound_len);
        }
    }

    // Rectangle
    // SDL_SetRenderDrawColor(renderer, -red + 1.f, -green + 1.f, -blue + 1.f, SDL_ALPHA_OPAQUE_FLOAT);
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    SDL_RenderFillRect(renderer, &state->rect);

    // Render all
    SDL_RenderPresent(renderer);

    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, const SDL_AppResult result) {
    AppState *state = appstate;

    if (audio) {
        SDL_DestroyAudioStream(audio);
    }

    if (state) {
        if (state->sound_buffer) {
            SDL_free(state->sound_buffer);
        }

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
