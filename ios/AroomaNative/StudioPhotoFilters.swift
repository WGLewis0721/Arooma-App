import SwiftUI
import CoreImage
import UIKit

/// Photo grades only. A filter never fabricates or redraws the photographed container.
enum StudioPhotoFilter: String, CaseIterable, Codable, Identifiable {
    case original = "Original"
    case royalAmber = "Royal Amber"
    case midnight = "Midnight"
    case ivory = "Ivory"
    case violet = "Violet"
    case emerald = "Emerald"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .original: "Unfiltered photograph"
        case .royalAmber: "Warm gold and rich contrast"
        case .midnight: "Cool shadows and deep blacks"
        case .ivory: "Soft, creamy highlights"
        case .violet: "Moody editorial contrast"
        case .emerald: "Cool, crisp detail"
        }
    }

    fileprivate var grade: Grade {
        switch self {
        case .original: Grade(saturation: 1, contrast: 1, brightness: 0, exposure: 0, temperature: 6500, sepia: 0, vignette: 0, hue: 0)
        case .royalAmber: Grade(saturation: 1.04, contrast: 1.10, brightness: 0.005, exposure: 0.05, temperature: 5200, sepia: 0.18, vignette: 0.55, hue: 0)
        case .midnight: Grade(saturation: 0.78, contrast: 1.18, brightness: -0.025, exposure: -0.08, temperature: 7800, sepia: 0, vignette: 0.8, hue: 0)
        case .ivory: Grade(saturation: 0.88, contrast: 0.94, brightness: 0.04, exposure: 0.08, temperature: 5800, sepia: 0.04, vignette: 0.10, hue: 0)
        case .violet: Grade(saturation: 0.90, contrast: 1.15, brightness: -0.012, exposure: -0.01, temperature: 7300, sepia: 0, vignette: 0.60, hue: 0.055)
        case .emerald: Grade(saturation: 0.94, contrast: 1.07, brightness: 0.01, exposure: 0.06, temperature: 7000, sepia: 0, vignette: 0.32, hue: -0.035)
        }
    }
}

private struct Grade {
    let saturation: Double
    let contrast: Double
    let brightness: Double
    let exposure: Double
    let temperature: Double
    let sepia: Double
    let vignette: Double
    let hue: Double
}

/// Uses the same deterministic Core Image recipe for live previews, saved cards and PNG export.
/// The actual source photo is persisted without the grade, so switching filters is non-destructive.
enum StudioPhotoFilters {
    private static let context = CIContext(options: [.cacheIntermediates: false])

    static func render(data: Data, preset: StudioPhotoFilter, maxDimension: CGFloat) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return render(image: image, preset: preset, maxDimension: maxDimension)
    }

    static func render(image: UIImage, preset: StudioPhotoFilter, maxDimension: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let oriented = CIImage(cgImage: cgImage).oriented(CGImagePropertyOrientation(image.imageOrientation))
        let source = oriented.transformed(
            by: CGAffineTransform(translationX: -oriented.extent.minX, y: -oriented.extent.minY)
        )
        let longest = max(source.extent.width, source.extent.height)
        guard longest > 0 else { return nil }
        let scale = min(1, max(1, maxDimension) / longest)
        let input = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        var result = input

        if preset != .original {
            let grade = preset.grade
            result = result.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: grade.saturation,
                kCIInputContrastKey: grade.contrast,
                kCIInputBrightnessKey: grade.brightness
            ])
            if grade.exposure != 0 {
                result = result.applyingFilter("CIExposureAdjust", parameters: [
                    kCIInputEVKey: grade.exposure
                ])
            }
            if grade.temperature != 6500 {
                result = result.applyingFilter("CITemperatureAndTint", parameters: [
                    "inputNeutral": CIVector(x: 6500, y: 0),
                    "inputTargetNeutral": CIVector(x: grade.temperature, y: 0)
                ])
            }
            if grade.sepia > 0 {
                result = result.applyingFilter("CISepiaTone", parameters: [
                    kCIInputIntensityKey: grade.sepia
                ])
            }
            if grade.hue != 0 {
                result = result.applyingFilter("CIHueAdjust", parameters: [
                    kCIInputAngleKey: grade.hue
                ])
            }
            // Skip vignette on transparent cutouts; preserve the original alpha silhouette.
            if grade.vignette > 0 && !cgImageHasAlpha(cgImage) {
                result = result.applyingFilter("CIVignette", parameters: [
                    kCIInputIntensityKey: grade.vignette,
                    kCIInputRadiusKey: max(input.extent.width, input.extent.height) * 0.68
                ])
            }
        }

        guard let output = context.createCGImage(result, from: input.extent) else { return nil }
        return UIImage(cgImage: output, scale: 1, orientation: .up)
    }

    private static func cgImageHasAlpha(_ cg: CGImage) -> Bool {
        switch cg.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: true
        default: false
        }
    }
}

/// An on-device thumbnail of the actual uploaded photo, never a generic sample image.
struct StudioFilterThumbnail: View {
    let photo: Data
    let preset: StudioPhotoFilter
    @State private var preview: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.12))
            if let preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 76, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task(id: photo) {
            preview = nil
            let bytes = photo
            let style = preset
            let rendered = await Task.detached(priority: .utility) {
                StudioPhotoFilters.render(data: bytes, preset: style, maxDimension: 240)
            }.value
            if !Task.isCancelled { preview = rendered }
        }
    }
}
