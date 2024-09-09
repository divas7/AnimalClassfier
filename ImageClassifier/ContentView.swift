import SwiftUI
import CoreML
import Vision
import UIKit

struct ContentView: View {
    @State private var image: UIImage? = nil
    @State private var prediction: String = "Upload an image to predict"
    @State private var isImagePickerPresented: Bool = false
    @State private var isImageUploaded: Bool = false
    
    var body: some View {
        ZStack {
            // Subtle blue gradient background
            LinearGradient(gradient: Gradient(colors: [Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8, opacity: 1), Color(.sRGB, red: 0.1, green: 0.3, blue: 0.6, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Animal Classifier")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .shadow(radius: 5)
                    .scaleEffect(isImageUploaded ? 1.1 : 1.0) // Scale animation

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.6), lineWidth: 3)
                        )
                        .animation(.spring()) // Animated when image appears
                        .transition(.scale)
                        .blur(radius: isImageUploaded ? 0 : 10)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .overlay(
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white.opacity(0.8))
                        )
                        .shadow(radius: 10)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
                
                Button(action: {
                    self.isImagePickerPresented = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    Text("Upload Image")
                        .fontWeight(.bold)
                        .padding()
                        .frame(width: 250)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .scaleEffect(isImageUploaded ? 1.1 : 1.0) // Button grows after upload
                }
                .padding(.top, 20)
                .animation(.easeInOut(duration: 0.3)) // Smooth button effect
                
                Text(prediction)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding()
                    .background(
                        BlurView(style: .systemMaterial) // Frosted glass effect
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .animation(.easeInOut(duration: 0.3)) // Smooth appearance of text
                    .scaleEffect(isImageUploaded ? 1.1 : 1.0) // Prediction text grows subtly after upload
                
                Spacer()
            }
            .sheet(isPresented: $isImagePickerPresented, content: {
                ImagePicker(image: self.$image, prediction: self.$prediction, isImageUploaded: self.$isImageUploaded)
            })
        }
    }
}

// Custom blur view for glassmorphism effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// ImagePicker for selecting an image from the library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var prediction: String
    @Binding var isImageUploaded: Bool
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.isImageUploaded = true
                parent.predictImage(image: uiImage)
            }
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func predictImage(image: UIImage) {
        guard let model = try? VNCoreMLModel(for: PetImageClassifier().model) else {
            prediction = "Failed to load model"
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNClassificationObservation],
               let firstResult = results.first {
                DispatchQueue.main.async {
                    self.prediction = "It's a \(firstResult.identifier.capitalized)!"
                }
            } else {
                self.prediction = "Could not classify image"
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
