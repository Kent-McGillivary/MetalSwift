//
//  tutorial.metal
//  MetalApp
//
//  Created by Kent McGillivary on 4/5/20.
//  Copyright © 2020 Kent McGillivary App Shop. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
  float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
  return vertex_in.position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
