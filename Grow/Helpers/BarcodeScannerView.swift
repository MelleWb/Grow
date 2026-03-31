import SwiftUI
import Vision
import VisionKit

struct BarcodeScannerSheet: View {
    let onBarcodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if #available(iOS 16.0, *), DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                BarcodeScannerView { barcode in
                    onBarcodeScanned(barcode)
                    dismiss()
                }
            } else {
                ContentUnavailableView(
                    "Scanner niet beschikbaar",
                    systemImage: "barcode.viewfinder",
                    description: Text("Deze barcode scanner werkt alleen op ondersteunde iPhones met cameratoegang.")
                )
            }
        }
    }
}

@available(iOS 16.0, *)
private struct BarcodeScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .code39, .itf14, .gs1DataBar])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator

        do {
            try scanner.startScanning()
        } catch {
            print("Failed to start barcode scanner: \(error)")
        }

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private var hasScanned = false
        private let onBarcodeScanned: (String) -> Void

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard hasScanned == false else {
                return
            }

            let barcode = (addedItems + allItems).compactMap { item -> String? in
                guard case .barcode(let barcode) = item else {
                    return nil
                }

                return barcode.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .first { $0?.isEmpty == false } ?? nil

            guard let barcode else {
                return
            }

            hasScanned = true
            onBarcodeScanned(barcode)
        }
    }
}
