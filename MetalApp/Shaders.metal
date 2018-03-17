//
//  Shaders.metal
//  chapter07
//
//  Created by Marius on 2/29/16.
//  Copyright © 2016 Marius Horga. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position;
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
};

vertex VertexOut vertex_passthrough(device VertexIn *vertices [[buffer(0)]],
                          uint vertexId [[vertex_id]]) {
    VertexOut out;
    out.position = vertices[vertexId].position;
    out.color = vertices[vertexId].color;
    return out;
}

fragment half4 fragment_passthrough(VertexOut fragmentIn [[stage_in]]) {
    return half4(fragmentIn.color);
}
