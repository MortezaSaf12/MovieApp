//
//  ContentView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack {
            Text("Tap on this button to add some data")
            Button("add an item"){
                addItem()
            }
        }
        .padding()
    }
    
    func addItem(){
        //Create the Item
        let item = DataItem(name: "Test Item")
        //Add the item to the data context
        context.insert(item)
    }
}

#Preview {
    ContentView()
}  
