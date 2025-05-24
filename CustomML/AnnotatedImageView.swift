//
//  AnnotatedImageView.swift
//  CustomML
//
//  Created by Adeel Ahmad on 17/05/2025.
//

import SwiftUI
import Vision

struct AnnotatedImageView: View {
    let image: UIImage
    let observations: [VNRecognizedObjectObservation]
    @State var filteredObservations: [VNRecognizedObjectObservation] = []
    @Binding var croppedImages: [UIImage]
    
    var body: some View {
        VStack {
            Text("Detected Objects")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            GeometryReader { geo in
                let imageSize = image.size
                let containerSize = geo.size
                let scale = min(containerSize.width / imageSize.width,
                                containerSize.height / imageSize.height)
                let displaySize = CGSize(width: imageSize.width * scale,
                                         height: imageSize.height * scale)
                let xOffset = (containerSize.width - displaySize.width) / 2
                let yOffset = (containerSize.height - displaySize.height) / 2

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: displaySize.width, height: displaySize.height)
                        .position(x: containerSize.width / 2, y: containerSize.height / 2)

                    ForEach(filteredObservations, id: \.uuid) { observation in
                        let rect = boundingBoxRect(from: observation.boundingBox, in: displaySize, offset: CGSize(width: xOffset, height: yOffset))
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)

                        Text(observation.labels.first?.identifier ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .position(x: rect.minX + 20, y: rect.minY + 10)
                    }
                }
                .frame(width: containerSize.width, height: containerSize.height)
            }
            .padding(.horizontal)

            if !croppedImages.isEmpty {
                Text("Cropped Sections")
                    .font(.headline)
                    .padding(.top)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(croppedImages, id: \.self) { croppedImage in
                            Image(uiImage: croppedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            self.filteredObservations = observations
            self.updateCroppedImagesList()
        }
        .onChange(of: observations) { newObservations in
            self.filteredObservations = newObservations
            self.updateCroppedImagesList()
        }
    }
    
    func updateCroppedImagesList() {
        var newCroppedImages: [UIImage] = []
        for observation in filteredObservations {
            let rect = boundingBoxInPixels(from: observation.boundingBox, imageSize: image.size)
            if let cropped = image.cropped(to: rect) {
                newCroppedImages.append(cropped)
            }
        }
        let uniqueImages = newCroppedImages.reduce(into: [UIImage]()) { result, image in
            if !result.contains(where: { $0.pngData() == image.pngData() }) {
                result.append(image)
            }
        }
        self.croppedImages = uniqueImages
    }

    func boundingBoxRect(from normalized: CGRect, in displaySize: CGSize, offset: CGSize) -> CGRect {
        let x = normalized.origin.x * displaySize.width + offset.width
        // Vision's origin is bottom-left, UIKit's is top-left → flip y for display
        // The y-coordinate needs to be flipped, and then the height of the box itself needs to be added
        // to shift the origin from bottom-left (Vision) to top-left (SwiftUI).
        let y = (1 - normalized.origin.y - normalized.height) * displaySize.height + offset.height + normalized.height * displaySize.height
        let width = normalized.width * displaySize.width
        let height = normalized.height * displaySize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func boundingBoxInPixels(from normalized: CGRect, imageSize: CGSize) -> CGRect {
        let width = normalized.width * imageSize.width
        let height = normalized.height * imageSize.height
        let x = normalized.origin.x * imageSize.width
        // Vision's origin is bottom-left, UIKit's is top-left → flip y
        let y = (1 - normalized.origin.y - normalized.height) * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        let imageRect = CGRect(origin: .zero, size: self.size)
        guard imageRect.contains(rect) else { return nil }

        let scaledRect = CGRect(x: rect.origin.x * self.scale,
                                y: rect.origin.y * self.scale,
                                width: rect.width * self.scale,
                                height: rect.height * self.scale)

        guard let cgImage = self.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

//#Preview {
//    AnnotatedImageView()
//}
