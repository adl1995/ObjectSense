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

            detectedObjectsView()

            if !filteredObservations.isEmpty {
                croppedSectionsView()
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
        .onChange(of: filteredObservations) { _ in
            self.updateCroppedImagesList()
        }
    }
    
    func updateCroppedImagesList() {
        var newCroppedImages: [UIImage] = []
        for observation in filteredObservations {
            let rect = boundingBoxInPixelsForCropping(from: observation.boundingBox, forImage: image)
            if let cropped = image.cropped(toPixelRect: rect) {
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
        // Vision's origin is bottom-left. SwiftUI's origin is top-left.
        // To get the y-coordinate of the top edge of the box in SwiftUI's system:
        // 1. (normalized.origin.y + normalized.height) gives the y-coordinate of the top edge from the bottom in Vision's system.
        // 2. (1 - (normalized.origin.y + normalized.height)) flips this to be from the top in a normalized top-left system.
        // This is equivalent to (1 - normalized.origin.y - normalized.height).
        let y = (1 - normalized.origin.y - normalized.height) * displaySize.height + offset.height
        let width = normalized.width * displaySize.width
        let height = normalized.height * displaySize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func boundingBoxInPixelsForCropping(from normalizedRect: CGRect, forImage image: UIImage) -> CGRect {
        let uprightImageSize = image.uprightSize()

        let pixelWidth = normalizedRect.width * uprightImageSize.width
        let pixelHeight = normalizedRect.height * uprightImageSize.height
        let pixelX = normalizedRect.origin.x * uprightImageSize.width
        let pixelY = (1 - normalizedRect.origin.y - normalizedRect.height) * uprightImageSize.height

        return CGRect(x: pixelX, y: pixelY, width: pixelWidth, height: pixelHeight)
    }

    @ViewBuilder
    private func detectedObjectsView() -> some View {
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
    }

    @ViewBuilder
    private func croppedSectionsView() -> some View {
        VStack {
            Text("Cropped Sections")
                .font(.headline)
                .padding(.top)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filteredObservations, id: \.uuid) { observation in

                        let cropRect = boundingBoxInPixelsForCropping(from: observation.boundingBox, forImage: image)
                        if let croppedImage = image.cropped(toPixelRect: cropRect) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: croppedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )

                                Button(action: {
                                    withAnimation {
                                        filteredObservations.removeAll { $0.uuid == observation.uuid }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .background(Circle().fill(Color.white.opacity(0.75)))
                                        .padding(2)
                                }
                                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 4))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

extension UIImage {
    // Returns the size of the image as if its orientation is UIImage.Orientation.up
    func uprightSize() -> CGSize {
        switch self.imageOrientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            return CGSize(width: self.size.height, height: self.size.width)
        default:
            return self.size
        }
    }

    // Expects a CGRect in pixel coordinates relative to the upright CGImage data.
    func cropped(toPixelRect pixelRect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else {
            print("Error: cgImage is nil")
            return nil
        }

        // The pixelRect is already in the coordinate system of the cgImage (which is effectively upright).
        // Ensure the pixelRect is within the bounds of the cgImage.
        let cgImageBounds = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        
        // Intersect the requested crop rect with the actual image bounds.
        let validCropRect = pixelRect.intersection(cgImageBounds)

        guard !validCropRect.isNull, validCropRect.width > 0, validCropRect.height > 0 else {
            print("Error: Invalid crop rectangle after intersection. Original: \(pixelRect), Intersected: \(validCropRect), Image Bounds: \(cgImageBounds)")
            return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: validCropRect) else {
            print("Error: cgImage.cropping failed for rect: \(validCropRect)")
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

//#Preview {
//    AnnotatedImageView()
//}
