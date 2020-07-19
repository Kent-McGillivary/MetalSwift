//
//  AppDelegate.swift
//  MetalApp
//
//  Created by Kent McGillivary on 2/27/18.
//  Copyright © 2018 Kent McGillivary App Shop. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // Create the SwiftUI view that provides the window contents.
              let contentView = ContentView()

              // Create the window and set the content view.
              window = NSWindow(
                  contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                  backing: .buffered, defer: false)
              window.center()
              window.setFrameAutosaveName("Main Window")
              window.contentView = NSHostingView(rootView: contentView)
              window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }


}

