//
//  MathUtils.swift
//  chapter07
//
//  Created by Marius on 3/1/16.
//  Copyright © 2016 Marius Horga. All rights reserved.
//

import simd








public class MathUtils {
    
    static func matrix4x4_rotation(_ radians:Float,_ axis:SIMD3<Float>)->matrix_float4x4 {
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
        let eye = SIMD3<Float>.init(eyeX, eyeY, eyeZ);
        let center = SIMD3<Float>.init(centerX, centerY, centerZ);
        let up = SIMD3<Float>.init(upX, upY, upZ);
        
        let z = normalize(eye - center);
        let x = normalize(cross(up, z));
        let y = cross(z, x);
        let t = SIMD3<Float>.init(-dot(x, eye), -dot(y, eye), -dot(z, eye));
        
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
        
        return float3x3(vector3(m.columns.0.x,m.columns.0.y, m.columns.0.z),
                        vector3(m.columns.1.x,m.columns.1.y, m.columns.1.z),
                        vector3(m.columns.2.x,m.columns.2.y, m.columns.2.z))
    }
    
    static func matrix_print_4x4(_ m:matrix_float4x4) {
        print(m);
    }
    
}

