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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                ForEach(observations, id: \.uuid) { observation in
                    let rect = boundingBoxRect(from: observation.boundingBox, in: geo.size)

                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    Text(observation.labels.first?.identifier ?? "Unknown")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .font(.caption)
                        .position(x: rect.midX, y: rect.minY - 10)
                }
            }
        }
    }

    func boundingBoxRect(from normalized: CGRect, in size: CGSize) -> CGRect {
        let x = normalized.origin.x * size.width
        let y = (1 - normalized.origin.y - normalized.height) * size.height
//        let y = (normalized.origin.y + normalized.height) * size.height
        let width = normalized.width * size.width
        let height = normalized.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

//#Preview {
//    AnnotatedImageView()
//}
