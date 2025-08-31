#include "app_state.h"

void tick(AppState *state) {
    state->hit_wall = false;

    float new_x = (int) state->rect.x + state->momentum.x;
    float new_y = (int) state->rect.y + state->momentum.y;

    if (new_x + state->rect.w > state->w || new_x < 0) {
        state->momentum.x = -state->momentum.x;
        state->hit_wall = true;
    }
    if (new_y + state->rect.h > state->h || new_y < 0) {
        state->momentum.y = -state->momentum.y;
        state->hit_wall = true;
    }

    state->rect.x += (float) state->momentum.x;
    state->rect.y += (float) state->momentum.y;
}
