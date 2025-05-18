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

    
    var body: some View {
        GeometryReader { geo in
            let imageSize = image.size
            let containerSize = geo.size
            let scale = min(containerSize.width / imageSize.width,
                            containerSize.height / imageSize.height)
            
//            let displaySize = CGSize(width: imageSize.width * scale,
//                                     height: imageSize.height * scale)
            
//            let xOffset = (containerSize.width - displaySize.width) / 2
//            let yOffset = (containerSize.height - displaySize.height) / 2

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(filteredObservations, id: \.uuid) { observation in
                        let rect = boundingBoxInPixels(from: observation.boundingBox, imageSize: image.size)
                        let croppedImage = image.cropped(to: rect)

                        VStack(alignment: .leading) {
                            if let croppedImage = croppedImage {
                                ZStack(alignment: Alignment.topLeading) {
                                    Image(uiImage: croppedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(8)

                                    Button(action: {
                                        if let index = filteredObservations.firstIndex(where: { $0.uuid == observation.uuid }) {
                                            filteredObservations.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .padding(8)
                                }
                            }

                            Text(observation.labels.first?.identifier ?? "Unknown")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(.leading, 8)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onChange(of: observations) { newValue in
            filteredObservations = newValue
        }
        .onAppear {
            filteredObservations = observations
        }
    }
    
    func boundingBoxRect(from normalized: CGRect, in imageSize: CGSize, offset: CGSize) -> CGRect {
        let x = normalized.origin.x * imageSize.width + offset.width
        let y = (1 - normalized.origin.y - normalized.height) * imageSize.height + offset.height
        let width = normalized.width * imageSize.width
        let height = normalized.height * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func boundingBoxInPixels(from normalized: CGRect, imageSize: CGSize) -> CGRect {
        let width = normalized.width * imageSize.width
        let height = normalized.height * imageSize.height
        let x = normalized.origin.x * imageSize.width
        // Vision’s origin is bottom-left, UIKit’s is top-left → flip y
        let y = (1 - normalized.origin.y - normalized.height) * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
//#Preview {
//    AnnotatedImageView()
//}
