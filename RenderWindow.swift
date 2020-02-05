//
//  RenderWindow.swift
//  MetalApp
//
//  Created by Kent McGillivary on 2/2/20.
//  Copyright © 2020 Kent McGillivary App Shop. All rights reserved.
//

import Foundation
import Cocoa


class RenderWindowController: NSWindowController {
    @IBOutlet weak var button2d: NSButton!
    
    @IBAction func Button2dClick(_ sender: NSButton) {
        
        let viewController = contentViewController as! ViewController // It *must* be this type, so crash if it isn't
        let state = sender.state;
        if(state == NSControl.StateValue.on) {
            print("2D On")
            viewController.setIs2D(is2d:true);
                
        } else if(state == NSControl.StateValue.off) {
            print("2D Off")
            viewController.setIs2D(is2d:false);
                
            
        }
    }
    
    
}
