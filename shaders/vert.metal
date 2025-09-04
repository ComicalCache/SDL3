struct Uniform {
    metal::float4x4 mvp;
};

struct InputVertex {
    // (x, y, z)
    float3 position [[attribute(0)]];
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

    // Rotate and project coordinates
    out.position = uniform.mvp * float4(vertex_in.position, 1);
    // Copy unchanged color
    out.color = vertex_in.color;
    return out;
}
