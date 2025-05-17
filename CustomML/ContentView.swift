//
//  ContentView.swift
//  CustomML
//
//  Created by Adeel Ahmad on 17/05/2025.
//

import Vision
import CoreML
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State var selectedPhotos: PhotosPickerItem?
    @State var selectedImage: UIImage?
    @State var modelResult: VNRecognizedObjectObservation?
    @State var model: ModelHandler = ModelHandler()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button ("Predict") {
                if let image = UIImage(named: "twinlake") {
                    self.model = ModelHandler()
                    model.predict(image: image)
                }
            }
            
            if let input = selectedImage {
                AnnotatedImageView(
                    image: input,
                    observations: [VNRecognizedObjectObservation]() // Placeholder for observations
                )
                    
//                Image(uiImage: input)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 300, height: 300)
            } else {
                Text("No image selected")
            }
            
            PhotosPicker(
                selection: $selectedPhotos,
                matching: .any(of: [.images, .not(.screenshots)])) {
                    Text("Select Photos")
                } .onChange(of: selectedPhotos) {
                    Task {
                        guard let selectedPhotos = selectedPhotos,
                        let data = try? await selectedPhotos.loadTransferable(type: Data.self),
                        let uiImage = UIImage(data: data)
                        else {
                            print("Failed to load image")
                            return
                        }
//                        let model = ModelHandler()
                        self.model.predict(image: uiImage)
                        selectedImage = uiImage
                    }
                }
                
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
