#include "app_state.h"

void init_app_state(AppState *state, const int h, const int w, const int size_w, const int size_h) {
    state->hit_wall = false;

    state->dims.x = w;
    state->dims.y = h;

    state->delta.x = 4;
    state->delta.y = 4;

    state->rect.w = size_w;
    state->rect.h = size_h;
    state->rect.x = w / 2 + size_w / 2;
    state->rect.y = h / 2 + size_h / 2;
}

void tick(AppState *state) {
    state->hit_wall = false;

    float new_x = state->rect.x + state->delta.x;
    float new_y = state->rect.y + state->delta.y;

    if (new_x + state->rect.w > state->dims.x) {
        state->rect.x = state->dims.x - state->rect.w;
        state->delta.x = -state->delta.x;
        state->hit_wall = true;
    } else if (new_x < 0) {
        state->rect.x = 0;
        state->delta.x = -state->delta.x;
        state->hit_wall = true;
    } else {
        state->rect.x += state->delta.x;
    }

    if (new_y + state->rect.h > state->dims.y) {
        state->rect.y = state->dims.y - state->rect.h;
        state->delta.y = -state->delta.y;
        state->hit_wall = true;
    } else if (new_y < 0) {
        state->rect.y = 0;
        state->delta.y = -state->delta.y;
        state->hit_wall = true;
    } else {
        state->rect.y += state->delta.y;
    }
}
