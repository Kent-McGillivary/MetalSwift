import MetalKit
import SwiftUI


struct MetalView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
    }
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        let simpleSphere: MTKMesh!
        let renderPipelineState: MTLRenderPipelineState!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            
            
            do {
                       
                       let allocator = MTKMeshBufferAllocator(device: metalDevice)
                       let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                                                       segments: [100, 100],
                                                       inwardNormals: false,
                                                       geometryType: .triangles,
                                                       allocator: allocator)
                       self.simpleSphere = try MTKMesh(mesh: mdlMesh, device: metalDevice)
                   } catch {
                       print("Unable to load sphere")
                    self.simpleSphere = nil
                    
                   }
            
            // Compile the functions and other state into a pipeline object.
                  do {
                      let library = metalDevice.makeDefaultLibrary()!
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
                       try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)

                  }
                  catch {
                      print("Unable to compile render pipeline state")
                       print("Unexpected error: \(error).")
                    self.renderPipelineState = nil
                    
                  }
            super.init()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func render(_ view: MTKView) {
            // Our animation will be dependent on the frame time, so that regardless of how
            // fast we're animating, the speed of the transformations will be roughly constant.
            // Our command buffer is a container for the work we want to perform with the GPU.
            guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
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
           /* guard let drawable = view.currentDrawable else {
                return
            }
            let commandBuffer = metalCommandQueue.makeCommandBuffer()
            let rpd = view.currentRenderPassDescriptor
            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
            rpd?.colorAttachments[0].loadAction = .clear
            rpd?.colorAttachments[0].storeAction = .store
            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
            re?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()*/
            
             self.render(view)
        }
    }
}
