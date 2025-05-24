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
    @State private var triggerAnimation = 0
    @State private var isLoading = false
    @State private var showingCameraPicker = false
    @State private var justUsedCamera: Bool = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Processing Image...")
                    .padding()
            } else if let results = model.modelResult, let input = selectedImage {
                AnnotatedImageView(
                    image: input,
                    observations: results,
                    croppedImages: $croppedImages
                )
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    Text("No image selected")
                        .font(.headline)
                    Text("Tap the button below to choose an image.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            PhotosPicker(
                selection: $selectedPhotos,
                matching: .any(of: [.images, .not(.screenshots)])) {
                    Label("Select Photo", systemImage: "photo.badge.plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

            Button(action: {
                justUsedCamera = true
                showingCameraPicker = true
            }) {
                Label("Take Photo", systemImage: "camera.fill")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 5)
            .onChange(of: selectedPhotos) { newPhotoItem in
                Task {
                    selectedImage = nil
                    model.modelResult = nil
                    croppedImages = []

                    if let currentPhotoItem = newPhotoItem {
                        isLoading = true
                        do {
                            let data = try await currentPhotoItem.loadTransferable(type: Data.self)
                            if let uiImage = UIImage(data: data!) {
                                selectedImage = uiImage
                            } else {
                                print("Failed to create UIImage from data.")
                                isLoading = false
                                selectedPhotos = nil
                            }
                        } catch {
                            print("Failed to load image from library: \(error.localizedDescription)")
                            isLoading = false
                            selectedPhotos = nil
                        }
                    } else {
                        if isLoading {
                            isLoading = false
                        }
                    }
                }
            }

            if !croppedImages.isEmpty && !isLoading {
                HStack {
                    Button(action: {
                        self.model.saveImagesToLibrary(croppedImages)
                        triggerAnimation += 1
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                                .symbolEffect(.bounce, value: triggerAnimation)
                            Text("Save")
                        }
                    }
                    .padding()
                    
                    
                    Button(action: {
                        model.modelResult = nil
                        selectedImage = nil
                        croppedImages = []
                        selectedPhotos = nil
                        justUsedCamera = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text("Reset")
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingCameraPicker) {
            CameraPickerView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            Task {
                if let imageToProcess = newImage {
                    isLoading = true
                    self.model.predict(image: imageToProcess)
                    isLoading = false

                    if justUsedCamera {
                        selectedPhotos = nil
                        justUsedCamera = false
                    }
                } else {
                    model.modelResult = nil
                    croppedImages = []
                    
                    if isLoading {
                        isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
