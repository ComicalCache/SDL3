#include "app_state.h"

void AS_init(AppState *state, const Vec2d dims, const Vec2d rect_dims, const Uint64 prev_counter) {
    state->prev_counter = prev_counter;
    state->hit_wall = false;

    state->dims = dims;

    state->delta.x = 200;
    state->delta.y = 200;

    state->rect.w = (float)rect_dims.x;
    state->rect.h = (float)rect_dims.y;
    state->rect.x = (float)dims.x / 2.f + state->rect.w / 2.f;
    state->rect.y = (float)dims.y / 2.f + state->rect.h / 2.f;
}

void AS_tick(AppState *state, const float delta) {
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
