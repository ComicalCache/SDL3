struct Uniform {
    metal::float4x4 mvp;
};

struct InputVertex {
    // (x, y, z)
    float3 position [[attribute(0)]];
    // (r, g, b, a)
    float4 color    [[attribute(1)]];
    float2 uv       [[attribute(2)]];
};

struct OutputVertex {
    // (x, y, z, w)
    float4 position [[position]];
    float4 color;
    float2 uv;
};

vertex OutputVertex vertex_main(InputVertex in [[stage_in]], constant Uniform& uniform [[buffer(0)]]) {
    OutputVertex out;

    out.position = uniform.mvp * float4(in.position, 1);
    out.color = in.color;
    out.uv = in.uv;
    return out;
}
