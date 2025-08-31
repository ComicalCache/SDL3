#include "app_state.h"

void init_app_state(AppState *state, const int h, const int w, const float size_w, const float size_h,
                    const Uint64 prev_counter, const Uint64 frequency) {
    state->prev_counter = prev_counter;
    state->frequency = frequency;
    state->hit_wall = false;

    state->dims.x = w;
    state->dims.y = h;

    state->delta.x = 200;
    state->delta.y = 200;

    state->rect.w = size_w;
    state->rect.h = size_h;
    state->rect.x = (float)w / 2.f + size_w / 2.f;
    state->rect.y = (float)h / 2.f + size_h / 2.f;
}

void tick(AppState *state, const float delta) {
    state->hit_wall = false;

    float new_x = state->rect.x + (float)state->delta.x * delta;
    float new_y = state->rect.y + (float)state->delta.y * delta;

    if (new_x + state->rect.w > (float)state->dims.x) {
        state->rect.x = (float)state->dims.x - state->rect.w;
        state->delta.x = -state->delta.x;
        state->hit_wall = true;
    } else if (new_x < 0) {
        state->rect.x = 0;
        state->delta.x = -state->delta.x;
        state->hit_wall = true;
    } else {
        state->rect.x += (float)state->delta.x * delta;
    }

    if (new_y + state->rect.h > (float)state->dims.y) {
        state->rect.y = (float)state->dims.y - state->rect.h;
        state->delta.y = -state->delta.y;
        state->hit_wall = true;
    } else if (new_y < 0) {
        state->rect.y = 0;
        state->delta.y = -state->delta.y;
        state->hit_wall = true;
    } else {
        state->rect.y += (float)state->delta.y * delta;
    }
}
