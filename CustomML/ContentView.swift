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
import Photos

struct ContentView: View {
    @State var selectedPhotos: PhotosPickerItem?
    @State var selectedImage: UIImage?
    @State var model: ModelHandler = ModelHandler()
    @State private var croppedImages: [UIImage] = []

    var body: some View {
        VStack {
//            Button ("Predict") {
//                if let image = UIImage(named: "437A8396") {
//                    self.model = ModelHandler()
//                    model.predict(image: image)
//                }
//            }
            
            if let results = model.modelResult, let input = selectedImage {
                AnnotatedImageView(
                    image: input,
                    observations: results,
                    croppedImages: $croppedImages
                )
            }
            else if let input = selectedImage {
                Image(uiImage: input)
                    .resizable()
                    .scaledToFit()
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
                        self.model.predict(image: uiImage)
                        selectedImage = uiImage
                    }
                }

            
            if !croppedImages.isEmpty {
                Button("Save Images") {
                    self.model.saveImagesToLibrary(croppedImages)
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
