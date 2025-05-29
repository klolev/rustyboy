#include <metal_stdlib>
#include "ShaderDefinitions.h"

using namespace metal;

struct VertexOut {
    float2 textureCoordinate;
    float4 position [[position]];
};

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    Vertex in = vertexArray[vid];
    
    VertexOut out = {
        in.textureCoordinate,
        float4(in.position.x, in.position.y, 0, 1)
    };

    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<half> texture [[texture(0)]],
                               constant FragmentShaderParams &params [[buffer(0)]]) {
    if (!params.isLCDFilterEnabled) {
        constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
        const half4 color = texture.sample(textureSampler, in.textureCoordinate);
        return float4(color);
    }
    
    const float2 textureCoordinates = float2(
        in.position.x / params.pixelSize.x,
        in.position.y / params.pixelSize.y
    );
    
    const float2 pixelStart = float2(uint2(textureCoordinates));
    const float2 pixelEnd = pixelStart + 1;
    const float2 startDifference = textureCoordinates - pixelStart;
    const float2 endDifference = pixelEnd - textureCoordinates;
    const float2 threshold = 0.15;
    const float multiplier = 0.97;

    if (startDifference.x <= threshold.x
        || endDifference.x <= threshold.x
        || startDifference.y <= threshold.y
        || endDifference.y <= threshold.y) {
        constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

        const half4 color = texture.sample(textureSampler, in.textureCoordinate);
        return float4(color.x * multiplier, color.y * multiplier, color.z * multiplier, 1.0);
    }
    
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    const half4 color = texture.sample(textureSampler, pixelStart * params.texturePixelSize);
    return float4(color);
}
