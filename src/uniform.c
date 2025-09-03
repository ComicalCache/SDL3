#include "uniform.h"

void set_projection(Uniform *uniform, int width, int height) {
    uniform->projection[0 * 4 + 0] = (float)height / (float)width;
    uniform->projection[1 * 4 + 1] = 1.f;
    uniform->projection[2 * 4 + 2] = 1.f;
    uniform->projection[3 * 4 + 3] = 1.f;
}
