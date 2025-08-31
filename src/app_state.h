#ifndef APP_STATE_H
#define APP_STATE_H

#include <SDL3/SDL_rect.h>

typedef struct {
    int x;
    int y;
} Vec2d;

typedef struct {
    SDL_FRect rect;
    Uint64 prev_counter;

    Vec2d dims;
    Vec2d delta;

    bool hit_wall;
} AppState;

void AS_init(AppState *state, Vec2d dims, Vec2d rect_dims, Uint64 prev_counter);

void AS_tick(AppState *state, float delta);

#endif // APP_STATE_H
