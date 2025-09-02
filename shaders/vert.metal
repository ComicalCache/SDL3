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

vertex OutputVertex vertex_main(InputVertex vertex_in [[stage_in]]) {
    OutputVertex out;
    out.position = float4(vertex_in.position, 0, 1);
    out.color = vertex_in.color;
    return out;
}
