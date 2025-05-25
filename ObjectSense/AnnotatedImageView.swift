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
    @State private var editableLabels: [UUID: String] = [:]
    
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
            self.updateEditableLabels(for: observations)
            self.updateCroppedImagesList()
        }
        .onChange(of: observations) { newObservations in
            self.filteredObservations = newObservations
            self.updateEditableLabels(for: newObservations)
            self.updateCroppedImagesList()
        }
        .onChange(of: filteredObservations) { updatedObservations in
            let currentObservationUUIDs = Set(updatedObservations.map { $0.uuid })
            for uuid in editableLabels.keys {
                if !currentObservationUUIDs.contains(uuid) {
                    editableLabels[uuid] = nil
                }
            }
            self.updateCroppedImagesList()
        }
    }
    
    func updateCroppedImagesList() {
        var newCroppedImages: [UIImage] = []
        for observation in filteredObservations {
            let resizedImage = self.image.resized(to: CGSize(width: 384, height: 640))
            if let cropped = cropImage(from: resizedImage, using: observation.boundingBox) {
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
    
    func cropImage(from image: UIImage, using normalizedBoundingBox: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let x = normalizedBoundingBox.origin.x * imageSize.width
        let y = (1 - normalizedBoundingBox.origin.y - normalizedBoundingBox.height) * imageSize.height
        let width = normalizedBoundingBox.width * imageSize.width
        let height = normalizedBoundingBox.height * imageSize.height
        
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        let clampedRect = cropRect.intersection(CGRect(origin: .zero, size: imageSize))
        
        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else { 
            return nil 
        }
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
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
                        // Crop the image using the bounding box of the observation
                        let resizedImage = self.image.resized(to: CGSize(width: 384, height: 640))

                        if let croppedImage = cropImage(from: resizedImage, using: observation.boundingBox) {
                            VStack(alignment: .center, spacing: 4) {
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
                                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 4))
                                
                                TextField("Label", text: bindingForObservationLabel(uuid: observation.uuid))
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(4)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(4)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private func updateEditableLabels(for observations: [VNRecognizedObjectObservation]) {
        var newLabels: [UUID: String] = [:]
        for observation in observations {
            newLabels[observation.uuid] = observation.labels.first?.identifier ?? "Unknown"
        }
        self.editableLabels = newLabels
    }
    
    private func bindingForObservationLabel(uuid: UUID) -> Binding<String> {
        Binding<String>(
            get: { self.editableLabels[uuid] ?? "Unknown" },
            set: { newValue in
                if self.editableLabels[uuid] != newValue {
                    self.editableLabels[uuid] = newValue
                }
            }
        )
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
}

//#Preview {
//    AnnotatedImageView()
//}
