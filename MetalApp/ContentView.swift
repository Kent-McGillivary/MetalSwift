//
//  ContentView.swift
//  TestSwiftUI
//
//  Created by Kent McGillivary on 6/27/20.
//  Copyright © 2020 Kent McGillivary. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack() {
            //Spacer()
            HStack() {
                //Spacer()
                Text("Hello, World!")
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.leading)
                Text("Button2")
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                    Text(/*@START_MENU_TOKEN@*/"Button"/*@END_MENU_TOKEN@*/)
                }
                Spacer()
              
                
            }
            ExtractedView().background(Color.yellow)
           
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ExtractedView: View {
    var body: some View {
       // VStack(){
         //    Text("Test1")
           // } .frame(maxWidth: .infinity,maxHeight: .infinity)
       MetalView()
    }
}
