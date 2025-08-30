#include "app_state.h"

void init_app_state(AppState *state, const int h, const int w, const int size) {
    state->hit_wall = false;

    state->dims.x = w;
    state->dims.y = h;

    state->delta.x = 4;
    state->delta.y = 4;

    state->rect.w = size;
    state->rect.h = size;
    state->rect.x = w / 2 + size / 2;
    state->rect.y = h / 2 + size / 2;
}

void tick(AppState *state) {
    state->hit_wall = false;

    float new_x = state->rect.x + state->delta.x;
    float new_y = state->rect.y + state->delta.y;

    if (new_x + state->rect.w > state->dims.x || new_x < 0) {
        state->delta.x = -state->delta.x;
        state->hit_wall = true;
    }
    if (new_y + state->rect.h > state->dims.y || new_y < 0) {
        state->delta.y = -state->delta.y;
        state->hit_wall = true;
    }

    state->rect.x += state->delta.x;
    state->rect.y += state->delta.y;
}
