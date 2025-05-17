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


class ModelHandler {
    private var model: VNCoreMLModel
    
    init() {
        guard let model = try? VNCoreMLModel(for: Yolo(configuration: MLModelConfiguration()).model) else {
            print("Error loading model")
            fatalError("Could not load model")
        }
        self.model = model
    }

    func predict(image: UIImage) {
        guard let cgImage = image.cgImage else {
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
            
            for observation in results {
                let bestMatch = observation.labels[0]
                print("Label: \(bestMatch.identifier), Confidence: \(bestMatch.confidence)")
                print("Bounding Box: \(observation.boundingBox)")
            }
        }

    }

}
