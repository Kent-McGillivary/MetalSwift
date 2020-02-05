//
//  ViewController.swift
//  MetalApp
//
//  Created by Kent McGillivary on 2/27/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Cocoa
import Metal

import MetalKit

import simd





class ViewController: NSViewController {
    
    let vkertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    var device: MTLDevice!
    var renderer: Renderer2D!
    var renderer3D: Renderer3D!
  
    @IBOutlet var mtkView: MTKView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.device = device
        //mtkView.colorPixelFormat = .bgra8Unorm
        
        // Use 4x MSAA multisampling
        mtkView.sampleCount = 4
        // Clear to solid white
        //mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1) //This sets the background.  With 0,0,0 it is black.  1,1,1 would be white.
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        // Use a BGRA 8-bit normalized texture for the drawable
        mtkView.colorPixelFormat = .bgra8Unorm
        // Use a 32-bit depth buffer
        mtkView.depthStencilPixelFormat = .depth32Float
        
        //renderer = Renderer2D(view: mtkView, device: device)
        renderer3D = Renderer3D(view: mtkView, device: device)
        //mtkView.delegate = renderer
        mtkView.delegate = renderer3D
    }
    
    func setIs2D(is2d:Bool) {
        if(is2d) {
             print("Is2d")
           
        } else {
            print("Is3d")
        }
        
        renderer3D.is2d(is2dDrawing:is2d);
       
    }
    
    


  


}

