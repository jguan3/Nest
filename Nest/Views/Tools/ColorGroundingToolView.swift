import PhotosUI
import SwiftUI
import UIKit

/// Grounding activity: find something matching a random niche color, then photograph it.
struct ColorGroundingToolView: View {
    @State private var targetColor = NicheColor.random()
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var foundIt = false

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Look around and find something close to this color.")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(targetColor.color)
                            .frame(height: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: targetColor.color.opacity(0.4), radius: 20, y: 8)

                        Text(targetColor.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(NestTheme.primaryText)
                    }
                    .padding(.horizontal, 24)

                    if let capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                            )
                            .padding(.horizontal, 24)

                        if foundIt {
                            Text("Nice find. You're here, in this moment.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(NestTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        } else {
                            Button {
                                withAnimation {
                                    foundIt = true
                                }
                            } label: {
                                Text("This matches")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Capsule().fill(NestTheme.accentGradient))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 40)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            targetColor = NicheColor.random(excluding: targetColor)
                            capturedImage = nil
                            foundIt = false
                        } label: {
                            Text("New color")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NestTheme.primaryText)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(NestTheme.cardBackground)
                                        .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCamera = true
                        } label: {
                            Label("Take photo", systemImage: "camera.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(NestTheme.accentGradient))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 28)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Color Grounding")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newValue in
            if newValue != nil {
                foundIt = false
            }
        }
    }
}

/// A named niche color used for grounding hunts.
struct NicheColor: Equatable {
    let name: String
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    static let palette: [NicheColor] = [
        NicheColor(name: "Dusty Apricot", red: 0.89, green: 0.62, blue: 0.45),
        NicheColor(name: "Sea Glass", red: 0.55, green: 0.78, blue: 0.72),
        NicheColor(name: "Midnight Plum", red: 0.35, green: 0.18, blue: 0.38),
        NicheColor(name: "Moss Clay", red: 0.52, green: 0.55, blue: 0.32),
        NicheColor(name: "Stormy Periwinkle", red: 0.55, green: 0.58, blue: 0.82),
        NicheColor(name: "Toasted Caramel", red: 0.72, green: 0.45, blue: 0.28),
        NicheColor(name: "Foggy Sage", red: 0.62, green: 0.70, blue: 0.58),
        NicheColor(name: "Berry Ink", red: 0.48, green: 0.18, blue: 0.35),
        NicheColor(name: "Candle Wax", red: 0.92, green: 0.86, blue: 0.70),
        NicheColor(name: "Electric Teal", red: 0.10, green: 0.72, blue: 0.68),
        NicheColor(name: "Brick Dust", red: 0.68, green: 0.32, blue: 0.28),
        NicheColor(name: "Lavender Ash", red: 0.68, green: 0.62, blue: 0.78)
    ]

    /// Picks a random niche color, optionally skipping the current one.
    static func random(excluding current: NicheColor? = nil) -> NicheColor {
        let options = palette.filter { $0 != current }
        return options.randomElement() ?? palette[0]
    }
}

/// UIKit camera wrapper for taking a single photo.
struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ColorGroundingToolView()
    }
}
