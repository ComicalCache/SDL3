struct OutputVertex {
    float4 position [[position]];
    float4 color;
    float2 uv;
};

fragment float4 fragment_main(
    OutputVertex in [[stage_in]],
    metal::texture2d<float> tex [[texture(0)]],
    metal::sampler samp [[sampler(0)]]) {
    return tex.sample(samp, in.uv);
}
