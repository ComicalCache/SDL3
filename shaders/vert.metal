struct Uniform {
    float ar;
    float xa;
    float ya;
    float za;
};

struct InputVertex {
    // (x, y)
    float2 position [[attribute(0)]];
    // (r, g, b, a)
    float4 color    [[attribute(1)]];
};

struct OutputVertex {
    // (x, y, z, w)
    float4 position [[position]];
    float4 color;
};

vertex OutputVertex vertex_main(InputVertex vertex_in [[stage_in]], constant Uniform& uniform [[buffer(0)]]) {
    OutputVertex out;

    // Projection matrix
    metal::float4x4 P = metal::float4x4(1);
    P[0][0] = uniform.ar;

    // Rotation matrix
    float cx = metal::cos(uniform.xa);
    float sx = metal::sin(uniform.xa);
    float cy = metal::cos(uniform.ya);
    float sy = metal::sin(uniform.ya);
    float cz = metal::cos(uniform.za);
    float sz = metal::sin(uniform.za);

    metal::float4x4 Rx =
        metal::float4x4(float4(1, 0, 0, 0),
                        float4(0, cx, -sx, 0),
                        float4(0, sx, cx, 0),
                        float4(0, 0, 0, 1));

    metal::float4x4 Ry =
        metal::float4x4(float4(cy, 0, sy, 0),
                        float4(0, 1, 0, 0),
                        float4(-sy, 0, cy, 0),
                        float4(0, 0, 0, 1));

    metal::float4x4 Rz =
        metal::float4x4(float4(cz, -sz, 0, 0),
                        float4(sz, cz, 0, 0),
                        float4(0, 0, 1, 0),
                        float4(0, 0, 0, 1));

    // Rotate and project coordinates
    out.position = P * Rz * Ry * Rx * float4(vertex_in.position, 0, 1);
    // Copy unchanged color
    out.color = vertex_in.color;
    return out;
}
