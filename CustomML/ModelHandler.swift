//
//  ModelHandler.swift
//  CustomML
//
//  Created by Adeel Ahmad on 17/05/2025.
//

import Foundation
import Vision
import CoreML
import UIKit
import UIKit
import Photos

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func cropped(to rect: CGRect) -> UIImage? {
            guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
            return UIImage(cgImage: cgImage)
//            return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        }
}

class ModelHandler {
    private var model: VNCoreMLModel
    var modelResult: [VNRecognizedObjectObservation]?
    var extractedImages: [UIImage] = []

    init() {
        guard let model = try? VNCoreMLModel(for: Yolo(configuration: MLModelConfiguration()).model) else {
            print("Error loading model")
            fatalError("Could not load model")
        }
        self.model = model
    }

    func predict(image: UIImage) {
        let resizedImage = image.resized(to: CGSize(width: 384, height: 640))
        guard let cgImage = resizedImage.cgImage else {
            print("Error converting UIImage to CGImage")
            return
        }

        let request = VNCoreMLRequest(model: self.model, completionHandler: handleYoloResults)
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try handler.perform([request])
        } catch {
            print("Error performing request: \(error)")
        }

        func handleYoloResults(request: VNRequest, error: Error?) {
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            self.modelResult = results
            for observation in results {
                let bestMatch = observation.labels[0]
                print("Label: \(bestMatch.identifier), Confidence: \(bestMatch.confidence)")
                print("Bounding Box: \(observation.boundingBox)")
            }
        }
    }

    func saveImagesToLibrary(_ images: [UIImage]) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                print("🚫 Photo Library access denied")
                return
            }

            for image in images {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if success {
                        print("✅ Image saved")
                    } else {
                        print("❌ Failed to save image:", error?.localizedDescription ?? "Unknown error")
                    }
                }
            }
        }
    }
}
