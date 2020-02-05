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
    
    //Mesh for cube
    let mesh: Mesh
    let texture: MTLTexture
    
     var constants = Constants()
    
    var time = TimeInterval(0.0)
    
    let depthStencilState: MTLDepthStencilState
    let sampler: MTLSamplerState
    
    var targets: [MTLTexture] = []
    var vertexData: [Float]?
    
    let renderPipelineState: MTLRenderPipelineState
    
    var isAnimate:Bool = true;
    
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
        
        self.mesh = Mesh(cubeWithSize: 1.0, device: device)!
        
        do {
            self.texture = try Renderer3D.buildTexture(name: "Checkerboard", device)
        }
        catch {
            print("Unable to load texture from main bundle")
            return nil
        }
        
        // Make a depth-stencil state that passes when fragments are nearer to the camera than previous fragments
        depthStencilState = Renderer3D.buildDepthStencilStateWithDevice(device, compareFunc: .less, isWriteEnabled: true)
        
        // Make a texture sampler that wraps in both directions and performs bilinear filtering
        sampler = Renderer3D.buildSamplerStateWithDevice(device, addressMode: .repeat, filter: .linear)
        
        // Compile the functions and other state into a pipeline object.
        //do {
        //    renderPipelineState = try  Renderer2D.registerShaders(device,view:view)
        //}
        //catch {
        //    print("Unable to compile render pipeline state")
        //    return nil
        //}
        
        // Compile the functions and other state into a pipeline object.
        do {
           renderPipelineState = try Renderer3D.buildRenderPipelineWithDevice(device, view: view)
            //renderPipelineState = try Renderer3D.registerShaders(device, view: view)
        }
        catch {
            print("Unable to compile render pipeline state")
            return nil
        }
       
        
        super.init()
       
        
    }
    
   
    /**
        Load a texture found in assets.
     
     */
    class func buildTexture(name: String, _ device: MTLDevice) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        let asset = NSDataAsset.init(name: name)
        if let data = asset?.data {
            return try textureLoader.newTexture(data: data, options: [:])
        } else {
            fatalError("Could not load image \(name) from an asset catalog in the main bundle")
        }
    }
    
    class func buildSamplerStateWithDevice(_ device: MTLDevice,
                                           addressMode: MTLSamplerAddressMode,
                                           filter: MTLSamplerMinMagFilter) -> MTLSamplerState
    {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = addressMode
        samplerDescriptor.tAddressMode = addressMode
        samplerDescriptor.minFilter = filter
        samplerDescriptor.magFilter = filter
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    class func buildDepthStencilStateWithDevice(_ device: MTLDevice,
                                                compareFunc: MTLCompareFunction,
                                                isWriteEnabled: Bool) -> MTLDepthStencilState
    {
        let desc = MTLDepthStencilDescriptor()
        desc.depthCompareFunction = compareFunc
        desc.isDepthWriteEnabled = isWriteEnabled
        return device.makeDepthStencilState(descriptor: desc)!
    }
    
    class func buildRenderPipelineWithDevice(_ device: MTLDevice, view: MTKView) throws -> MTLRenderPipelineState {
        // The default library contains all of the shader functions that were compiled into our app bundle
        let library = device.makeDefaultLibrary()!
        
        // Retrieve the functions that will comprise our pipeline
        let vertexFunction = library.makeFunction(name: "vertex_transform")
        let fragmentFunction = library.makeFunction(name: "fragment_lit_textured")
        
        // A render pipeline descriptor describes the configuration of our programmable pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Render Pipeline"
        pipelineDescriptor.sampleCount = view.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
  
    
    func updateWithTimestep(_ timestep: TimeInterval)
    {
        // We keep track of time so we can animate the various transformations
        time = time + timestep
        
        
        let vectorAxis = vector_float3(0.7, 1, 0)
        let radiansAtTime = Float(time) * 0.5
        
        let modelToWorldMatrix = MathUtils.matrix4x4_rotation( radiansAtTime, vectorAxis)
        
        // So that the figure doesn't get distorted when the window changes size or rotates,
        // we factor the current aspect ration into our projection matrix. We also select
        // sensible values for the vertical view angle and the distances to the near and far planes.
        let viewSize = self.view.bounds.size
        let aspectRatio = Float(viewSize.width / viewSize.height)
        let verticalViewAngle = MathUtils.radians_from_degrees(65)
        let nearZ: Float = 0.1
        let farZ: Float = 100.0
        let projectionMatrix = MathUtils.matrix_perspective(verticalViewAngle, aspectRatio, nearZ, farZ)
        
        
        let viewMatrix = MathUtils.matrix_look_at(0, 0, 2.5, 0, 0, 0, 0, 1, 0)
        
        
        // The combined model-view-projection matrix moves our vertices from model space into clip space
        let mvMatrix = matrix_multiply(viewMatrix, modelToWorldMatrix);
        constants.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, mvMatrix)
        
        let upper = MathUtils.matrix_upper_left_3x3(mvMatrix)
        constants.normalMatrix = MathUtils.matrix_inverse_transpose(upper)
    }
    
    func render(_ view: MTKView) {
        // Our animation will be dependent on the frame time, so that regardless of how
        // fast we're animating, the speed of the transformations will be roughly constant.
        if(self.isAnimate) {
            let timestep = 1.0 / TimeInterval(view.preferredFramesPerSecond)
            updateWithTimestep(timestep)
        }
        // Our command buffer is a container for the work we want to perform with the GPU.
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            // Ask the view for a configured render pass descriptor. It will have a loadAction of
            // MTLLoadActionClear and have the clear color of the drawable set to our desired clear color.
            
            if let renderPassDescriptor =  view.currentRenderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                // Create a render encoder to clear the screen and draw our objects
                
                
                renderEncoder.pushDebugGroup("Draw Cube")
                
                // Since we specified the vertices of our triangles in counter-clockwise
                // order, we need to switch from the default of clockwise winding.
                renderEncoder.setFrontFacing(.counterClockwise)
                
                renderEncoder.setDepthStencilState(depthStencilState)
                
                // Set the pipeline state so the GPU knows which vertex and fragment function to invoke.
                renderEncoder.setRenderPipelineState(renderPipelineState)
                
                // Bind the buffer containing the array of vertex structures so we can
                // read it in our vertex shader.
                renderEncoder.setVertexBuffer(mesh.vertexBuffer, offset:0, index:0)
                
                // Bind the uniform buffer so we can read our model-view-projection matrix in the shader.
                renderEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.size, index: 1)
                
                // Bind our texture so we can sample from it in the fragment shader
                renderEncoder.setFragmentTexture(texture, index: 0)
                
                // Bind our sampler state so we can use it to sample the texture in the fragment shader
                renderEncoder.setFragmentSamplerState(sampler, index: 0)
                
                // Issue the draw call to draw the indexed geometry of the mesh
                renderEncoder.drawIndexedPrimitives(type: mesh.primitiveType,
                                                    indexCount: mesh.indexCount,
                                                    indexType: mesh.indexType,
                                                    indexBuffer: mesh.indexBuffer,
                                                    indexBufferOffset: 0)
                
                renderEncoder.popDebugGroup()
                
                // We are finished with this render command encoder, so end it.
                renderEncoder.endEncoding()
                
                // Tell the system to present the cleared drawable to the screen.
                if let drawable = view.currentDrawable
                {
                    commandBuffer.present(drawable)
                }
            }
            
            // Now that we're done issuing commands, we commit our buffer so the GPU can get to work.
            commandBuffer.commit()
            
        }
    }
    
    func draw(in view: MTKView) {
        
        self.render(view)
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
    
    
    func is2d(is2dDrawing:Bool) {
        self.isAnimate = !is2dDrawing;
        print("IsAnimate")
        print(self.isAnimate)
    }
    
}

