#ifndef VERTEX_H
#define VERTEX_H

typedef struct Vertex {
    float x, y;
    float r, g, b, a;
} Vertex;

extern const unsigned long num_verticies;
extern const Vertex verticies[];

#endif
