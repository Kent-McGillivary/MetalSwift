//
//  Renderer.swift
//  MetalApp
//
//  Created by Kent McGillivary on 3/6/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Foundation

import MetalKit




class Renderer3D: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var targets: [MTLTexture] = []
    var vertexData: [Float]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var rps: MTLRenderPipelineState?
    
    init(view: MTKView, device: MTLDevice) {
        self.view = view
        self.device = device
        commandQueue = device.makeCommandQueue()!
        super.init()
        self.registerShaders()
        self.createBuffer()
        
    }
    
    func registerShaders() {
        let library = device.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try rps = device.makeRenderPipelineState(descriptor: rpld)
        } catch {
            //  self.printView("\(error)")
        }
    }
    
    func createBuffer() {
        let vertex_data = [Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
                           Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
                           Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])
        ]
        vertexBuffer = device.makeBuffer(bytes: vertex_data, length: MemoryLayout<Vertex>.size * 3, options:[])
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
        let bufferPointer = uniformBuffer.contents()
        memcpy(bufferPointer, Matrix().modelMatrix(Matrix()).m, MemoryLayout<Float>.size * 16)
    }
    
    func draw(in view: MTKView) {
        
        if let rpd = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
            commandEncoder?.setRenderPipelineState(rps!)
            commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            commandEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
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

