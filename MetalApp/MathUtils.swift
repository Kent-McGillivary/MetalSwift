//
//  MathUtils.swift
//  chapter07
//
//  Created by Marius on 3/1/16.
//  Copyright © 2016 Marius Horga. All rights reserved.
//

import simd

struct Uniforms {
    let modelViewMatrix: float4x4
    let projectionMatrix: float4x4
}

struct Vertex {
    var position: vector_float4
    var color: vector_float4
}


struct Matrix {
    var m: [Float]
    
    init() {
        m = [1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1
        ]
    }
    
   
    
    static func matrix4x4_rotation(_ radians:Float,_ axis:float3)->matrix_float4x4 {
    let axisN = normalize(axis);
    let ct:Float = cosf(radians);
    let st:Float = sinf(radians);
    let ci:Float = 1 - ct;
    let x:Float = axisN.x, y = axisN.y, z = axisN.z;
    return matrix_float4x4(
        [ ct + x * x * ci,x * y * ci - z * st,x * z * ci + y * st,0],
        [y * x * ci + z * st,ct + y * y * ci,y * z * ci - x * st,0],
        [ z * x * ci - y * st, z * y * ci + x * st,  ct + z * z * ci,0],
        [0,0,0,1]
        );
    }
    
    static func matrix_look_at(_ eyeX:Float, _ eyeY:Float,_ eyeZ:Float,
                               _ centerX:Float,_ centerY:Float,_ centerZ:Float,
                               _ upX:Float,_ upY:Float,_ upZ:Float)->matrix_float4x4
    {
    let eye = float3(eyeX, eyeY, eyeZ);
    let center = float3(centerX, centerY, centerZ);
    let up = float3(upX, upY, upZ);
    
    let z = normalize(eye - center);
    let x = normalize(cross(up, z));
    let y = cross(z, x);
    let t = float3(-dot(x, eye), -dot(y, eye), -dot(z, eye));
    
    return matrix_float4x4([x.x, y.x,  z.x,  0],[x.y,y.y,z.y,0],[x.z,y.z,z.z,0],[t.x,t.y,t.z,1]);
    }
    
   static func matrix_inverse_transpose(_ m:matrix_float3x3)->matrix_float3x3 {
    return simd_transpose(m).inverse;
    }
    
    static func matrix_perspective(_ fovyRadians:Float,_ aspect:Float,_ nearZ:Float, _ farZ:Float)->matrix_float4x4 {
        let ys:Float = 1 / tanf(fovyRadians * 0.5);
        let xs:Float = ys / aspect;
        let zs:Float = farZ / (nearZ - farZ);
        
        
    return matrix_float4x4([xs, 0, 0, 0],
    [0, ys, 0, 0],
    [0, 0, zs, -1 ],
    [0, 0,zs * nearZ, 0]);
    }
    
    static func radians_from_degrees(_ degrees:Float) -> Float {
        return (degrees / 180) * Float.pi;
    }
    
    static func matrix_upper_left_3x3(_ m:matrix_float4x4)-> matrix_float3x3 {
        
        let (a,b,c,_) = m.columns
        let col1 = float3(a.x,a.y,a.z)
        let col2 = float3(b.x,b.y,b.z)
        let col3 = float3(c.x,c.y,c.z)
        return float3x3(col1, col2,col3)
    }
    
    static func matrix_print_4x4(_ m:matrix_float4x4) {
        print(m);
    }
    
    func translationMatrix(_ matrix: Matrix, _ position: float3) -> Matrix {
        var matrix = matrix
        matrix.m[12] = position.x
        matrix.m[13] = position.y
        matrix.m[14] = position.z
        return matrix
    }
    
    func scalingMatrix(_ matrix: Matrix, _ scale: Float) -> Matrix {
        var matrix = matrix
        matrix.m[0] = scale
        matrix.m[5] = scale
        matrix.m[10] = scale
        matrix.m[15] = 1.0
        return matrix
    }
    
    func rotationMatrix(_ matrix: Matrix, _ rot: float3) -> Matrix {
        var matrix = matrix
        matrix.m[0] = cos(rot.y) * cos(rot.z)
        matrix.m[4] = cos(rot.z) * sin(rot.x) * sin(rot.y) - cos(rot.x) * sin(rot.z)
        matrix.m[8] = cos(rot.x) * cos(rot.z) * sin(rot.y) + sin(rot.x) * sin(rot.z)
        matrix.m[1] = cos(rot.y) * sin(rot.z)
        matrix.m[5] = cos(rot.x) * cos(rot.z) + sin(rot.x) * sin(rot.y) * sin(rot.z)
        matrix.m[9] = -cos(rot.z) * sin(rot.x) + cos(rot.x) * sin(rot.y) * sin(rot.z)
        matrix.m[2] = -sin(rot.y)
        matrix.m[6] = cos(rot.y) * sin(rot.x)
        matrix.m[10] = cos(rot.x) * cos(rot.y)
        matrix.m[15] = 1.0
        return matrix
    }
    
    func modelMatrix(_ matrix: Matrix) -> Matrix {
        var matrix = matrix
        matrix = rotationMatrix(matrix, float3(0.0, 0.0, 0.1))
        matrix = scalingMatrix(matrix, 0.25)
        matrix = translationMatrix(matrix, float3(0.0, 0.5, 0.0))
        return matrix
    }
}

