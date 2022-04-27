//
//  PagedListView.swift
//  CommunageApp
//
//  Created by Hetul Soni on 01/04/22.
//

import SwiftUI
import Combine

public struct PagedListView<OverlayView: View, Content: View>: View {
    
    public struct PageConfig {
        let pageIndicatorColor: UIColor
        let isAutoSlideOn: Bool
        let sliderDuration : TimeInterval
        let indexDisplayMode : PageTabViewStyle.IndexDisplayMode
        let indexbackgroundDisplayMode: PageIndexViewStyle.BackgroundDisplayMode
        
        public init(pageIndicatorColor: UIColor, isAutoSlideOn: Bool = false, sliderDuration: TimeInterval = 2.0, indexDisplayMode: PageTabViewStyle.IndexDisplayMode = .always, indexbackgroundDisplayMode: PageIndexViewStyle.BackgroundDisplayMode = .never) {
            self.pageIndicatorColor = pageIndicatorColor
            self.isAutoSlideOn = isAutoSlideOn
            self.sliderDuration = sliderDuration
            self.indexDisplayMode = indexDisplayMode
            self.indexbackgroundDisplayMode = indexbackgroundDisplayMode
        }
    }

    
    @Binding var selection: String
    let tags: [String]
    let height: CGFloat
    var config: PageConfig {
        didSet {
            if config.isAutoSlideOn == true {
                startTimer()
            }
            else {
                stopTimer()
            }
        }
    }
    
    let overlay: OverlayView?
    
    @ViewBuilder var content: Content
    
    @State private var timerSubscription: Cancellable?
    @State private var timer = Timer.publish(every: 2, on: .main, in: .common)
    
    init(selection: Binding<String>, tags: [String], height: CGFloat, config: PageConfig, @ViewBuilder overlayView: @escaping (() -> OverlayView?) = { nil }, @ViewBuilder content: (() -> Content)) {
        _selection = selection
        self.tags = tags
        self.height = height
        self.config = config
        self.overlay = overlayView()
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack (alignment: .center) {
                TabView(selection: $selection) {
                    content
                        .frame(height: height)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: config.indexDisplayMode))
                .indexViewStyle(.page(backgroundDisplayMode: config.indexbackgroundDisplayMode))
                .animation(.easeInOut)
                .transition(.slide)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .onAppear {
                    setupAppearance()
                }
                overlay
            }
            .onAppear(perform: {
                self.startTimer()
            })
            .onDisappear(perform: {
                self.stopTimer()
            })
            .onChange(of: selection, perform: { newValue in
                if newValue != selection {
                    self.stopTimer()
                    self.startTimer()
                }
            })
            .onReceive(timer) { _ in
                Next()
            }
        }
        .frame(height: height)
    }
    
    func setupAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = config.pageIndicatorColor
        UIPageControl.appearance().pageIndicatorTintColor = config.pageIndicatorColor.withAlphaComponent(0.2)
    }
}

//MARK: Support funcs
extension PagedListView {
    
    /// Create timer and start timer event
    fileprivate func startTimer() {
        if config.isAutoSlideOn && tags.count > 1 {
            timer = Timer.publish (every: 2, on: .main, in: .common)
            timerSubscription = timer.connect()
        }
    }
    
    /// Stop timer
    fileprivate func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    /// This func will be called after specified interval, it will change image based on index
    fileprivate func Next() {
        if timerSubscription != nil {
            if let index = tags.firstIndex(of: selection) {
                withAnimation {
                    if index < tags.count - 1 {
                        selection = tags[index + 1]
                    }
                    else if let firstIndex = tags.first {
                        selection = firstIndex
                    }
                }
            }
        }
    }
}
