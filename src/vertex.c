#include "vertex.h"

static const float r = 0.6f;
// sqrt(3) / 2
static const float lambda = 0.8660254f;

const unsigned long num_vertices = 3;
const Vertex vertices[] = {{0.0f, r, 1.0f, 0.0f, 0.0f, 1.0f},
                           {-lambda * r, -0.5f * r, 0.0f, 1.0f, 0.0f, 1.0f},
                           {lambda * r, -0.5f * r, 0.0f, 0.0f, 1.0f, 1.0f}};
