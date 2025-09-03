struct Uniform {
    metal::float4x4 projection;
    float angle;
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

    // Rotation matrix
    float c = metal::cos(uniform.angle);
    float s = metal::sin(uniform.angle);
    metal::float2x2 R = metal::float2x2(float2(c, -s),
                                        float2(s,  c));

    // Rotate and project coordinates
    out.position = uniform.projection * float4(R * vertex_in.position, 0, 1);
    // Copy unchanged color
    out.color = vertex_in.color;
    return out;
}
