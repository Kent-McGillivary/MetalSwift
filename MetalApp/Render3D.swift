//
//  Renderer.swift
//  MetalApp
//
//  Created by Kent McGillivary on 3/6/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Foundation

import MetalKit

import Metal

import simd


struct Constants {
    var modelViewProjectionMatrix = matrix_identity_float4x4
    var normalMatrix = matrix_identity_float3x3
}

class Renderer3D: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    let simpleSphere: MTKMesh
    
     var constants = Constants()
        
    var targets: [MTLTexture] = []
    var vertexData: [Float]?
    
    let renderPipelineState: MTLRenderPipelineState
    
    //let renderPipelineStateSimple: MTLRenderPipelineState
    
    var isAnimate:Bool = false;
    
     init?(view: MTKView, device: MTLDevice) {
        self.view = view
        // Ask for the default Metal device; this represents our GPU.
        guard let defaultDevice = MTLCreateSystemDefaultDevice()
        else {
         fatalError("GPU is not supported")
        }

        self.device = defaultDevice

        guard let commandQueue =  device.makeCommandQueue() else {
          fatalError("Could not create a command queue")
        }

        self.commandQueue = commandQueue
      
        do {
            
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                                            segments: [100, 100],
                                            inwardNormals: false,
                                            geometryType: .triangles,
                                            allocator: allocator)
            self.simpleSphere = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("Unable to load sphere")
                      return nil
        }
        

        // Compile the functions and other state into a pipeline object.
        do {
            let library = device.makeDefaultLibrary()!
           let vertexFunction = library.makeFunction(name: "vertex_main")
           let fragmentFunction = library.makeFunction(name: "fragment_main")
           
           let pipelineDescriptor = MTLRenderPipelineDescriptor()
           pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
           pipelineDescriptor.vertexFunction = vertexFunction
           pipelineDescriptor.fragmentFunction = fragmentFunction
            
            pipelineDescriptor.vertexDescriptor =
                 MTKMetalVertexDescriptorFromModelIO(  self.simpleSphere.vertexDescriptor)
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            self.renderPipelineState =
             try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        }
        catch {
            print("Unable to compile render pipeline state")
             print("Unexpected error: \(error).")
            return nil
        }
       
        super.init()
       
        
    }
    
    func render(_ view: MTKView) {
        // Our animation will be dependent on the frame time, so that regardless of how
        // fast we're animating, the speed of the transformations will be roughly constant.
        // Our command buffer is a container for the work we want to perform with the GPU.
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
        let renderPassDescriptor =  view.currentRenderPassDescriptor,
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
           fatalError()
        }
                
        // Set the pipeline state so the GPU knows which vertex and fragment function to invoke.
    
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        renderEncoder.setVertexBuffer(self.simpleSphere.vertexBuffers[0].buffer, offset:0, index:0)
        
        guard let submesh = simpleSphere.submeshes.first else {
          fatalError()
        }
            
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                  indexCount: submesh.indexCount,
                                  indexType: submesh.indexType,
                                  indexBuffer: submesh.indexBuffer.buffer,
                                  indexBufferOffset: 0)
            
        
                

        renderEncoder.endEncoding()
                
      
        guard let drawable = view.currentDrawable else {
          fatalError()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
            
        
    }
    
    func draw(in view: MTKView) {
        
        self.render(view)
    }
    
    func makeOffscreenTargets(_ size: CGSize) {
//        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .invalid,
//                                                                  width: Int(size.width),
//                                                                  height: Int(size.height),
//                                                                  mipmapped: false)
//        descriptor.pixelFormat = .rgba8Unorm
//        descriptor.usage = [.shaderRead, .renderTarget]
//        descriptor.storageMode = .managed
//        descriptor.pixelFormat = .depth32Float
//        descriptor.usage = .renderTarget
//        descriptor.storageMode = .private
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        makeOffscreenTargets(size)
    }
    
    
    func is2d(is2dDrawing:Bool) {
        self.isAnimate = !is2dDrawing;
        print("IsAnimate")
        print(self.isAnimate)
    }
    
}

