//
//  RefreshableScrollView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 30.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//
//  based on https://gist.github.com/swiftui-lab/3de557a513fbdb2d8fced41e40347e01
//

import SwiftUI

struct RefreshableScrollView<Content: View>: View {
    @State
    private var previousScrollOffset: CGFloat = 0

    @State
    private var scrollOffset: CGFloat = 0

    @State
    private var frozen: Bool = false

    @State
    private var rotation: Angle = .degrees(0)

    var refreshTresholdInPoints: CGFloat = 70

    // We will begin rotation, only after we have passed
    // 60% of the way of reaching the threshold.
    var relativeRotationThreshold = 0.6

    @Binding
    var refreshing: Bool
    
    let content: Content

    init(height: CGFloat = 70, refreshing: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.refreshTresholdInPoints = height
        self._refreshing = refreshing
        self.content = content()

    }

    var body: some View {
        return VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()

                    VStack { self.content }
                        .alignmentGuide(.top, computeValue: { d in
                            (self.refreshing && self.frozen) ? -self.refreshTresholdInPoints : 0.0
                        })

                    SymbolView(height: self.refreshTresholdInPoints,
                               loading: self.refreshing,
                               frozen: self.frozen,
                               rotation: self.rotation)
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }

    func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.viewType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.viewType == .fixedView }?.bounds ?? .zero

            self.scrollOffset  = movingBounds.minY - fixedBounds.minY

            self.rotation = self.symbolRotation(self.scrollOffset)

            // Crossing the threshold on the way down, we start the refresh process
            if !self.refreshing &&
                self.scrollOffset > self.refreshTresholdInPoints &&
                self.previousScrollOffset <= self.refreshTresholdInPoints {
                self.refreshing = true
            }

            if self.refreshing {
                // Crossing the threshold on the way up, we add a space at the top of the scrollview
                if self.previousScrollOffset > self.refreshTresholdInPoints &&
                    self.scrollOffset <= self.refreshTresholdInPoints {
                    self.frozen = true
                }
            } else {
                // remove the space at the top of the scroll view
                self.frozen = false
            }

            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }

    func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        if scrollOffset < refreshTresholdInPoints * CGFloat(relativeRotationThreshold) {
            return .degrees(0)
        } else {
            let rotationStartInPoints = Double(refreshTresholdInPoints) * relativeRotationThreshold
            let rotationEndInPoints = Double(refreshTresholdInPoints) * (1 - relativeRotationThreshold)
            if scrollOffset < CGFloat(rotationStartInPoints) {
                return .degrees(0)
            } else {
                let rotationOffset = max(min(Double(scrollOffset) - rotationStartInPoints, rotationEndInPoints), 0)
                return .degrees(180 * rotationOffset / rotationEndInPoints)
            }
        }
    }

    struct SymbolView: View {
        let height: CGFloat
        let loading: Bool
        let frozen: Bool
        let rotation: Angle

        var body: some View {
            Group {
                if self.loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        Spacer()
                    }
                    .frame(height: height).fixedSize()
                    .offset(y: -height + (self.loading && self.frozen ? height : 0.0))
                } else {
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                        .offset(y: -height + (loading && frozen ? height : 0.0))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: RefreshableKeyTypes.PrefKey.self,
                    value: [RefreshableKeyTypes.PrefData(viewType: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }

    struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: RefreshableKeyTypes.PrefKey.self,
                    value: [RefreshableKeyTypes.PrefData(viewType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }
}

struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }

    struct PrefData: Equatable {
        let viewType: ViewType
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}
