# ObjectSense - iOS App for Creating Home Inventory with Object Detection

ObjectSense is an iOS application that demonstrates real-time object detection using the YOLO model with Core ML. Users can select images from their photo library or take new photos with the camera. The app then identifies objects within the image, draws bounding boxes around them, and allows users to view and edit the predicted labels. This removes the hassle of manually taking inventory photos and helps in creating a home inventory system efficiently.

| Main View | Cropped Sections with Editable Labels |
|:-:|:-:|
| ![Home screen](images/homescreen.jpg) | ![Result](images/detected-objects.jpg) |

## Features

*   **Image Selection**: Choose images from the device's photo library.
*   **Camera Capture**: Take new photos directly within the app.
*   **Object Detection**: Utilizes a YOLO Core ML model to detect objects in the selected image.
*   **Cropped Sections**: Shows individual cropped images of each detected object.
*   **Editable Labels**: Allows users to view and edit the predicted label for each detected object.
*   **Save Cropped Images**: Save the identified cropped sections to the photo library.

## Demo Video

<div align="center">
    <img src="images/recording.gif" alt="Demo video" width="40%" style="margin: auto; display: block;" />
</div>

## Setup and Running the Project

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/adl1995/ObjectSense.git
    cd ObjectSense
    ```
2.  **Open in Xcode:** Open the `ObjectSense.xcodeproj` file in Xcode.
3.  **YOLO Core ML Model**: This project expects a `Yolo.mlpackage` or `Yolo.mlmodel` Core ML model file. 
    *   If your model is named differently or not included, ensure you add your `.mlmodel` file to the project.
    *   Update the `ModelHandler.swift` (or equivalent model loading code) if your model's class name is different from the one currently used.
4.  **Build and Run:** Select a target device or simulator and run the app.

## Technologies Used

*   **SwiftUI**: For the user interface and application structure.
*   **Core ML**: For integrating and running the machine learning model on-device.
*   **Vision Framework**: For automatic preprocessing images and handling Core ML transformation.
*   **PhotosUI**: For picking images from the photo library.
*   **AVFoundation**: For accessing the camera.

## Future Enhancements / To-Do

*   [ ] Real-time object detection from the live camera feed.
*   [ ] Improve UI/UX animations and transitions.
*   [ ] Add settings for detection confidence thresholds.

## License

This project is licensed under the MIT License.
