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
    float2 texCoords;
};

struct VertexOut3D {
    float4 position [[position]];
    float3 normal;
    float2 texCoords;
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


struct Constants {
    float4x4 modelViewProjectionMatrix;
    float3x3 normalMatrix;
};

constant half3 ambientLightIntensity(0.1, 0.1, 0.1);
constant half3 diffuseLightIntensity(0.9, 0.9, 0.9);
constant half3 lightDirection(-0.577, -0.577, -0.577);

struct VertexIn3D {
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoords;
};



vertex VertexOut3D vertex_transform(device VertexIn3D *vertices [[buffer(0)]],
                                  constant Constants &uniforms [[buffer(1)]],
                                  uint vertexId [[vertex_id]])
{
    float3 modelPosition = vertices[vertexId].position;
    float3 modelNormal = vertices[vertexId].normal;
    
    VertexOut3D out;
    // Multiplying the model position by the model-view-projection matrix moves us into clip space
    out.position = uniforms.modelViewProjectionMatrix * float4(modelPosition, 1);
    // Copy the vertex normal and texture coordinates
    out.normal = uniforms.normalMatrix * modelNormal;
    out.texCoords = vertices[vertexId].texCoords;
    return out;
}

fragment half4 fragment_lit_textured(VertexOut3D fragmentIn [[stage_in]],
                                     texture2d<float, access::sample> tex2d [[texture(0)]],
                                     sampler sampler2d [[sampler(0)]])
{
    // Sample the texture to get the surface color at this point
    half3 surfaceColor = half3(tex2d.sample(sampler2d, fragmentIn.texCoords).rrr);
    // Re-normalize the interpolated surface normal
    half3 normal = normalize(half3(fragmentIn.normal));
    // Compute the ambient color contribution
    half3 color = ambientLightIntensity * surfaceColor;
    // Calculate the diffuse factor as the dot product of the normal and light direction
    float diffuseFactor = saturate(dot(normal, -lightDirection));
    // Add in the diffuse contribution from the light
    color += diffuseFactor * diffuseLightIntensity * surfaceColor;
    return half4(color, 1);
}

