#ifndef SDL3_TEST_APP_STATE_H
#define SDL3_TEST_APP_STATE_H

#include <SDL3/SDL_rect.h>
#include <stdbool.h>

typedef struct {
    int x;
    int y;
} Vec2d;

typedef struct {
    int h;
    int w;

    SDL_FRect rect;
    Vec2d momentum;

    bool hit_wall;

    Uint8 *sound_buffer;
    Uint32 sound_len;
} AppState;

void tick(AppState *state);

#endif //SDL3_TEST_APP_STATE_H
