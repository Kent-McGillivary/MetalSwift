//
//  Renderer2D.swift
//  MetalApp
//
//  Created by Kent McGillivary on 3/6/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Foundation
import MetalKit


class Renderer2D: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var targets: [MTLTexture] = []
    var vertexData: [Float]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    let renderPipelineState: MTLRenderPipelineState
    
    init?(view: MTKView, device: MTLDevice) {
        self.view = view
        // Use 4x MSAA multisampling
        view.sampleCount = 4
        // Clear to solid white
        view.clearColor = MTLClearColorMake(0, 0, 0, 1) //This sets the background.  With 0,0,0 it is black.  1,1,1 would be white.
        // Use a BGRA 8-bit normalized texture for the drawable
        view.colorPixelFormat = .bgra8Unorm
        // Use a 32-bit depth buffer
        view.depthStencilPixelFormat = .depth32Float
        
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
        super.init()
       
        self.createBuffer()
        
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
    
    func createBuffer() {
         let vertex_data = [Vertex(position: [0.0, 0.75, 0.0, 1.0], color: [1, 0, 0, 1]),
                           Vertex(position: [ -0.75, -0.75, 0.0, 1.0], color: [0, 1, 0, 1]),
                           Vertex(position: [ 0.75, -0.75, 0.0, 1.0], color: [0, 0, 1, 1])
        ]
        vertexBuffer = device.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * 3, options:[])
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        let bufferPointer = uniformBuffer.contents()
        memcpy(bufferPointer, Matrix().modelMatrix(Matrix()).m, MemoryLayout<Float>.size * 16)
    }
    
    func draw(in view: MTKView) {
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            // Ask the view for a configured render pass descriptor. It will have a loadAction of
            // MTLLoadActionClear and have the clear color of the drawable set to our desired clear color.
            let renderPassDescriptor = view.currentRenderPassDescriptor
            
            if let renderPassDescriptor = renderPassDescriptor {
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
