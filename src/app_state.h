#ifndef SDL3_TEST_APP_STATE_H
#define SDL3_TEST_APP_STATE_H

#include <SDL3/SDL_rect.h>
#include <stdbool.h>

typedef struct {
    int x;
    int y;
} Vec2d;

typedef struct {
    Vec2d dims;
    SDL_Rect rect;
    Vec2d delta;

    bool hit_wall;
} AppState;

void init_app_state(AppState *state, int h, int w, int size_w, int size_h);

void tick(AppState *state);

#endif //SDL3_TEST_APP_STATE_H
