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
    
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    let device = MTLCreateSystemDefaultDevice()!
    var renderer: Renderer2D!
  
    @IBOutlet var mtkView: MTKView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.device = device
        //mtkView.colorPixelFormat = .bgra8Unorm
        
        // Use 4x MSAA multisampling
        mtkView.sampleCount = 4
        // Clear to solid white
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1) //This sets the background.  With 0,0,0 it is black.  1,1,1 would be white.
        // Use a BGRA 8-bit normalized texture for the drawable
        mtkView.colorPixelFormat = .bgra8Unorm
        // Use a 32-bit depth buffer
        mtkView.depthStencilPixelFormat = .depth32Float
        
        renderer = Renderer2D(view: mtkView, device: device)
        mtkView.delegate = renderer
        
    }
    
    


  


}

