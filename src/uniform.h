#ifndef UNIFORM_H
#define UNIFORM_H

typedef struct {
    float projection[16];
    float angle;
} Uniform;

void set_projection(Uniform *uniform, int width, int height);

#endif
