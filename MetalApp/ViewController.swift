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
        mtkView.colorPixelFormat = .bgra8Unorm
        renderer = Renderer2D(view: mtkView, device: device)
        mtkView.delegate = renderer
        
    }
    
    


  


}

