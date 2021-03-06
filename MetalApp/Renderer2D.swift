//
//  Renderer2D.swift
//  MetalApp
//
//  Created by Kent McGillivary on 3/6/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Foundation
import MetalKit

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
        let eye =  SIMD3<Float>.init(eyeX, eyeY, eyeZ);
        let center =  SIMD3<Float>.init(centerX, centerY, centerZ);
        let up =  SIMD3<Float>.init(upX, upY, upZ);
        
        let z = normalize(eye - center);
        let x = normalize(cross(up, z));
        let y = cross(z, x);
        let t =  SIMD3<Float>.init(-dot(x, eye), -dot(y, eye), -dot(z, eye));
        
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
        let col1 =  SIMD3<Float>.init(a.x,a.y,a.z)
        let col2 =  SIMD3<Float>.init(b.x,b.y,b.z)
        let col3 =  SIMD3<Float>.init(c.x,c.y,c.z)
        return float3x3(col1, col2,col3)
    }
    
    static func matrix_print_4x4(_ m:matrix_float4x4) {
        print(m);
    }
    
    func translationMatrix(_ matrix: Matrix, _ position: SIMD3<Float>) -> Matrix {
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
    
    func rotationMatrix(_ matrix: Matrix, _ rot: SIMD3<Float>) -> Matrix {
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
        matrix = rotationMatrix(matrix,  SIMD3<Float>.init(0.0, 0.0, 0.1))
        matrix = scalingMatrix(matrix, 0.25)
        matrix = translationMatrix(matrix,  SIMD3<Float>.init(0.0, 0.5, 0.0))
        return matrix
    }
}


class Renderer2D: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var targets: [MTLTexture] = []
    var vertexBuffer: MTLBuffer
    var uniformBuffer: MTLBuffer
    let renderPipelineState: MTLRenderPipelineState
    
    init?(view: MTKView, device: MTLDevice) {
        self.view = view
     
        // Ask for the default Metal device; this represents our GPU.
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
        }
        else {
            print("Metal is not supported")
            return nil
        }
        
        self.commandQueue = device.makeCommandQueue()!
        
        // Compile the functions and other state into a pipeline object.
        do {
            renderPipelineState = try  Renderer2D.registerShaders(device,view:view)
        }
        catch {
            print("Unable to compile render pipeline state")
            return nil
        }
        let item = Renderer2D.createBuffer(device:device)
        if let vertexBuffer = item.vertexBuffer, let uniformBuffer = item.uniformBuffer {
            self.vertexBuffer = vertexBuffer;
            self.uniformBuffer = uniformBuffer;
        }
        else  {
            return nil;
        }
      
        super.init()
        
    }
    
    class func registerShaders(_ device: MTLDevice, view: MTKView) throws -> MTLRenderPipelineState {
        
        // The default library contains all of the shader functions that were compiled into our app bundle
        let library = device.makeDefaultLibrary()!
        
        // Retrieve the functions that will comprise our pipeline
        let vertex_func = library.makeFunction(name: "vertex_passthrough")
        let frag_func = library.makeFunction(name: "fragment_passthrough")
        
        // A render pipeline descriptor describes the configuration of our programmable pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = view.sampleCount
        pipelineDescriptor.vertexFunction = vertex_func
        pipelineDescriptor.fragmentFunction = frag_func
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func createBuffer(device:MTLDevice) ->(vertexBuffer:MTLBuffer?, uniformBuffer:MTLBuffer?) {
        let vertex_data = [Vertex(position: [0.0, 0.75, 0.0, 1.0], color: [1, 0, 0, 1]),
                           Vertex(position: [ -0.75, -0.75, 0.0, 1.0], color: [0, 1, 0, 1]),
                           Vertex(position: [ 0.75, -0.75, 0.0, 1.0], color: [0, 0, 1, 1])
        ]
        
        
        if let uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * 16, options: []),
            let vertexBuffer = device.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * 3, options:[]) {
            
            let bufferPointer =  uniformBuffer.contents()
            memcpy(bufferPointer, Matrix().modelMatrix(Matrix()).m, MemoryLayout<Float>.size * 16)
            return  (vertexBuffer,uniformBuffer)
        }
        else {
            return (nil,nil)
        }
    }
    
    func draw(in view: MTKView) {
        
        // Ask the view for a configured render pass descriptor. It will have a loadAction of
        // MTLLoadActionClear and have the clear color of the drawable set to our desired clear color.
        
        if let commandBuffer = commandQueue.makeCommandBuffer(), let renderPassDescriptor = view.currentRenderPassDescriptor  {
            
                //Create a render encoder to clear the screen and draw our objects
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor:renderPassDescriptor) {
                    
                    renderEncoder.setRenderPipelineState(renderPipelineState)
                    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
                    
                    //We are finished with this render command encoder, so end it
                    renderEncoder.endEncoding()
                    if let drawable = view.currentDrawable {
                        commandBuffer.present(drawable)
                    }
                    
                    commandBuffer.commit()
                }
        }
    }
    
    func makeOffscreenTargets(_ size: CGSize) {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .invalid,
                                                                  width: Int(size.width),
                                                                  height: Int(size.height),
                                                                  mipmapped: false)
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .managed
        let colorTarget = device.makeTexture(descriptor: descriptor)!
        
        descriptor.pixelFormat = .depth32Float
        descriptor.usage = .renderTarget
        descriptor.storageMode = .private
        let depthTarget = device.makeTexture(descriptor: descriptor)!
        
        targets = [colorTarget, depthTarget]
    }

    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        makeOffscreenTargets(size)
    }
    
   
}
