//
//  ImageViewer.swift
//  Grow
//
//  Created by Swen Rolink on 11/09/2021.
//

import SwiftUI
import UIKit

@available(iOS 13.0, *)
public struct ImageViewer: View {
    @Binding var viewerShown: Bool
    @Binding var image: Image
    @Binding var imageOpt: Image?
    @State var caption: Text?
    @State var closeButtonTopRight: Bool?

    var aspectRatio: Binding<CGFloat>?

    public init(image: Binding<Image>, viewerShown: Binding<Bool>, aspectRatio: Binding<CGFloat>? = nil, caption: Text? = nil, closeButtonTopRight: Bool? = false) {
        _image = image
        _viewerShown = viewerShown
        _imageOpt = .constant(nil)
        self.aspectRatio = aspectRatio
        _caption = State(initialValue: caption)
        _closeButtonTopRight = State(initialValue: closeButtonTopRight)
    }

    public init(image: Binding<Image?>, viewerShown: Binding<Bool>, aspectRatio: Binding<CGFloat>? = nil, caption: Text? = nil, closeButtonTopRight: Bool? = false) {
        _image = .constant(Image(systemName: ""))
        _imageOpt = image
        _viewerShown = viewerShown
        self.aspectRatio = aspectRatio
        _caption = State(initialValue: caption)
        _closeButtonTopRight = State(initialValue: closeButtonTopRight)
    }

    func getImage() -> Image {
        if imageOpt == nil {
            return image
        } else {
            return imageOpt ?? Image(systemName: "questionmark.diamond")
        }
    }

    @ViewBuilder
    public var body: some View {
        VStack {
            if viewerShown {
                ZStack(alignment: .top) {
                    Color.black
                        .ignoresSafeArea()

                    ZoomableImageScrollView(
                        image: getImage(),
                        aspectRatio: aspectRatio?.wrappedValue
                    )
                    .ignoresSafeArea()

                    if caption != nil {
                        VStack {
                            Spacer()

                            HStack {
                                Spacer()
                                caption
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .padding()
                        }
                        .ignoresSafeArea()
                    }

                    HStack {
                        if closeButtonTopRight == true {
                            Spacer()
                        }

                        Button(action: { viewerShown = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: UIFontMetrics.default.scaledValue(for: 24)))
                                .padding(12)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Circle())
                        }

                        if closeButtonTopRight != true {
                            Spacer()
                        }
                    }
                    .padding()
                    .zIndex(2)
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .introspectTabBarController { tabBarController in
                    tabBarController.tabBar.isHidden = viewerShown
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ZoomableImageScrollView: UIViewRepresentable {
    let image: Image
    let aspectRatio: CGFloat?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4

        let hostedView = context.coordinator.hostingController.view!
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.frame = scrollView.bounds
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(hostedView)
        context.coordinator.scrollView = scrollView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        context.coordinator.update(image: image, aspectRatio: aspectRatio)
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.update(image: image, aspectRatio: aspectRatio)
        context.coordinator.hostingController.view.frame = scrollView.bounds
        context.coordinator.centerImageIfNeeded()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        weak var scrollView: UIScrollView?

        func update(image: Image, aspectRatio: CGFloat?) {
            hostingController.rootView = AnyView(
                image
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
            )
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImageIfNeeded()
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale < scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView else {
                return
            }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            let tapLocation = gesture.location(in: hostingController.view)
            let zoomRect = zoomRect(for: scrollView.maximumZoomScale / 2, centeredAt: tapLocation, in: scrollView)
            scrollView.zoom(to: zoomRect, animated: true)
        }

        func centerImageIfNeeded() {
            guard let scrollView else {
                return
            }

            let boundsSize = scrollView.bounds.size
            var frameToCenter = hostingController.view.frame

            frameToCenter.origin.x = frameToCenter.size.width < boundsSize.width
                ? (boundsSize.width - frameToCenter.size.width) / 2
                : 0

            frameToCenter.origin.y = frameToCenter.size.height < boundsSize.height
                ? (boundsSize.height - frameToCenter.size.height) / 2
                : 0

            hostingController.view.frame = frameToCenter
        }

        private func zoomRect(for scale: CGFloat, centeredAt center: CGPoint, in scrollView: UIScrollView) -> CGRect {
            let size = CGSize(
                width: scrollView.bounds.size.width / scale,
                height: scrollView.bounds.size.height / scale
            )

            let origin = CGPoint(
                x: center.x - (size.width / 2),
                y: center.y - (size.height / 2)
            )

            return CGRect(origin: origin, size: size)
        }
    }
}
