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
            let imageSize = image.size
            let containerSize = geo.size
            let scale = min(containerSize.width / imageSize.width,
                            containerSize.height / imageSize.height)
            
            let displaySize = CGSize(width: imageSize.width * scale,
                                     height: imageSize.height * scale)
            
            let xOffset = (containerSize.width - displaySize.width) / 2
            let yOffset = (containerSize.height - displaySize.height) / 2
            
//            ZStack {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: displaySize.width, height: displaySize.height)
//                    .position(x: containerSize.width / 2, y: containerSize.height / 2)
//                
//                ForEach(observations, id: \.uuid) { observation in
//                    let rect = boundingBoxRect(
//                        from: observation.boundingBox,
//                        in: displaySize,
//                        offset: CGSize(width: xOffset, height: yOffset)
//                    )
//                    
//                    Rectangle()
//                        .stroke(Color.red, lineWidth: 2)
//                        .frame(width: rect.width, height: rect.height)
//                        .position(x: rect.midX, y: rect.midY)
//                    
//                    Text(observation.labels.first?.identifier ?? "Unknown")
//                        .foregroundColor(.white)
//                        .background(Color.black.opacity(0.7))
//                        .font(.caption)
//                        .position(x: rect.midX, y: rect.minY - 10)
//                }
//            }
            
            ScrollView {
                VStack {
                    ForEach(observations, id: \.uuid) { observation in
                        
                        let rect = boundingBoxInPixels(
                            from: observation.boundingBox,
                            imageSize: imageSize
                        )
                        let croppedImage = image.cropped(to: rect)
                        
                        
                        Image(uiImage: croppedImage ?? UIImage())
                            .resizable()
                            .scaledToFit()
//                            .frame(width: displaySize.width, height: displaySize.height)
//                            .position(x: containerSize.width / 2, y: containerSize.height / 2)
                    }
                }
            }
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
