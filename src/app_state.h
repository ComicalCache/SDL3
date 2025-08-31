#ifndef SDL3_TEST_APP_STATE_H
#define SDL3_TEST_APP_STATE_H

#include <SDL3/SDL_rect.h>

typedef struct {
    int x;
    int y;
} Vec2d;

typedef struct {
    SDL_FRect rect;
    Uint64 prev_counter;
    Uint64 frequency;

    Vec2d dims;
    Vec2d delta;

    bool hit_wall;
} AppState;

void init_app_state(AppState *state, int h, int w, float size_w, float size_h, Uint64 prev_counter, Uint64 frequency);

void tick(AppState *state, float delta);

#endif // SDL3_TEST_APP_STATE_H
