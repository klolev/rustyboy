#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>
#ifndef __cplusplus
#define bool _Bool
#endif

struct Vertex {
    vector_float2 textureCoordinate;
    vector_float2 position;
};

struct FragmentShaderParams {
    vector_uint2 screenSize;
    vector_float2 pixelSize;
    vector_float2 texturePixelSize;
    bool isLCDFilterEnabled;
};

#endif /* ShaderDefinitions_h */
